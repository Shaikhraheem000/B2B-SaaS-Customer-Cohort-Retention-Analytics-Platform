-- =============================================================================
-- Project:         B2B SaaS Customer Cohort & Retention Analytics Platform
-- File:            views.sql
-- Role:            Senior Data Architect / Lead Data Analyst
-- Target Engine:   PostgreSQL 13+
-- Purpose:         Production Analytical Views for Executive Dashboards,
--                  Cohort Heatmaps, and Revenue Operations Reporting.
-- =============================================================================

SET search_path TO analytics, public;

--------------------------------------------------------------------------------
-- 1. VIEW: vw_active_customers
-- Description: Current active (non-churned) customer roster with tier, seats,
--              MRR, ARR, and acquisition campaign channel attribution.
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.vw_active_customers AS
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.country,
    a.signup_date,
    TO_CHAR(a.signup_date, 'YYYY-MM') AS signup_cohort_month,
    a.plan_tier AS account_plan_tier,
    a.seats AS account_seats,
    a.is_trial AS is_account_trial,
    a.referral_source,
    mc.campaign_name,
    mc.channel AS campaign_channel,
    COALESCE(SUM(s.mrr_amount), 0.00) AS total_active_mrr,
    COALESCE(SUM(s.arr_amount), 0.00) AS total_active_arr,
    COUNT(s.subscription_id) AS active_subscriptions_count
FROM analytics.accounts a
LEFT JOIN analytics.marketing_campaigns mc ON a.campaign_id = mc.campaign_id
LEFT JOIN analytics.subscriptions s 
       ON a.account_id = s.account_id 
      AND s.churn_flag = FALSE 
      AND (s.end_date IS NULL OR s.end_date >= CURRENT_DATE)
WHERE a.churn_flag = FALSE
GROUP BY 
    a.account_id,
    a.account_name,
    a.industry,
    a.country,
    a.signup_date,
    a.plan_tier,
    a.seats,
    a.is_trial,
    a.referral_source,
    mc.campaign_name,
    mc.channel;

COMMENT ON VIEW analytics.vw_active_customers IS 
'Active customer account roster detailing current plan tiers, MRR/ARR contribution, and acquisition campaign channels.';


--------------------------------------------------------------------------------
-- 2. VIEW: vw_monthly_revenue
-- Description: Monthly recurring revenue summary aggregated by cohort signup 
--              month, tracking active logos, total MRR, ARR, and ARPA.
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.vw_monthly_revenue AS
SELECT 
    TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
    COUNT(DISTINCT a.account_id) AS total_acquired_accounts,
    COUNT(DISTINCT CASE WHEN a.churn_flag = FALSE THEN a.account_id END) AS active_retained_accounts,
    COUNT(DISTINCT CASE WHEN a.churn_flag = TRUE THEN a.account_id END) AS churned_accounts,
    ROUND(
        COUNT(DISTINCT CASE WHEN a.churn_flag = FALSE THEN a.account_id END) * 100.0 / 
        NULLIF(COUNT(DISTINCT a.account_id), 0), 2
    ) AS logo_retention_pct,
    COALESCE(SUM(s.mrr_amount), 0.00) AS total_mrr_usd,
    COALESCE(SUM(s.arr_amount), 0.00) AS total_arr_usd,
    ROUND(
        COALESCE(SUM(s.mrr_amount), 0.00) / 
        NULLIF(COUNT(DISTINCT CASE WHEN a.churn_flag = FALSE THEN a.account_id END), 0), 2
    ) AS arpa_usd
FROM analytics.accounts a
LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id
GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
ORDER BY cohort_month DESC;

COMMENT ON VIEW analytics.vw_monthly_revenue IS 
'Cohort signup month revenue aggregation tracking MRR, ARR, Logo Retention %, and Average Revenue Per Account (ARPA).';


--------------------------------------------------------------------------------
-- 3. VIEW: vw_customer_revenue
-- Description: Account-level financial summary combining current contract MRR, 
--              historical contract count, trial status, and churn classification.
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.vw_customer_revenue AS
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    a.signup_date,
    a.churn_flag AS is_account_churned,
    COUNT(s.subscription_id) AS total_contracts_ever,
    COUNT(CASE WHEN s.churn_flag = FALSE THEN 1 END) AS active_contracts_count,
    COUNT(CASE WHEN s.is_trial = TRUE THEN 1 END) AS trial_contracts_count,
    COALESCE(SUM(CASE WHEN s.churn_flag = FALSE THEN s.mrr_amount ELSE 0 END), 0.00) AS current_mrr,
    COALESCE(SUM(CASE WHEN s.churn_flag = FALSE THEN s.arr_amount ELSE 0 END), 0.00) AS current_arr,
    COALESCE(SUM(s.mrr_amount), 0.00) AS lifetime_mrr_value
FROM analytics.accounts a
LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id
GROUP BY 
    a.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    a.signup_date,
    a.churn_flag;

COMMENT ON VIEW analytics.vw_customer_revenue IS 
'Comprehensive account-level revenue rollup showing active vs. churned MRR, contract history, and trial activity.';


--------------------------------------------------------------------------------
-- 4. VIEW: vw_churn_summary
-- Description: Categorized cancellation analytics view aggregating churn count 
--              by reason code, total refund dollars issued, and plan tier.
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.vw_churn_summary AS
SELECT 
    ce.reason_code,
    a.plan_tier,
    COUNT(ce.churn_event_id) AS total_churn_events,
    SUM(ce.refund_amount_usd) AS total_refunds_issued_usd,
    ROUND(AVG(ce.refund_amount_usd), 2) AS avg_refund_per_churn_usd,
    SUM(CASE WHEN ce.preceding_upgrade_flag = TRUE THEN 1 ELSE 0 END) AS churns_with_prior_upgrade,
    SUM(CASE WHEN ce.preceding_downgrade_flag = TRUE THEN 1 ELSE 0 END) AS churns_with_prior_downgrade,
    SUM(CASE WHEN ce.is_reactivation = TRUE THEN 1 ELSE 0 END) AS reactivated_count
FROM analytics.churn_events ce
JOIN analytics.accounts a ON ce.account_id = a.account_id
GROUP BY ce.reason_code, a.plan_tier
ORDER BY total_churn_events DESC;

COMMENT ON VIEW analytics.vw_churn_summary IS 
'Churn root cause distribution by reason code, plan tier, refund amounts, and preceding plan changes.';


--------------------------------------------------------------------------------
-- 5. VIEW: vw_support_summary
-- Description: Customer support operational metrics per account including 
--              ticket volume, average resolution time, response time, CSAT, & escalations.
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.vw_support_summary AS
SELECT 
    a.account_id,
    a.account_name,
    a.plan_tier,
    a.churn_flag,
    COUNT(st.ticket_id) AS total_tickets_opened,
    SUM(CASE WHEN st.priority = 'urgent' OR st.priority = 'high' THEN 1 ELSE 0 END) AS high_priority_tickets_count,
    SUM(CASE WHEN st.escalation_flag = TRUE THEN 1 ELSE 0 END) AS escalated_tickets_count,
    ROUND(AVG(st.resolution_time_hours), 2) AS avg_resolution_time_hours,
    ROUND(AVG(st.first_response_time_minutes), 2) AS avg_first_response_minutes,
    ROUND(AVG(st.satisfaction_score), 2) AS avg_csat_score
FROM analytics.accounts a
LEFT JOIN analytics.support_tickets st ON a.account_id = st.account_id
GROUP BY 
    a.account_id,
    a.account_name,
    a.plan_tier,
    a.churn_flag;

COMMENT ON VIEW analytics.vw_support_summary IS 
'Support operations summary per account detailing ticket counts, resolution SLA performance, CSAT scores, and escalations.';


--------------------------------------------------------------------------------
-- 6. VIEW: vw_feature_adoption
-- Description: Product telemetry rollup tracking feature interactions, usage 
--              durations, error rates, and beta adoption across subscription tiers.
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW analytics.vw_feature_adoption AS
SELECT 
    fu.feature_name,
    s.plan_tier,
    fu.is_beta_feature,
    COUNT(DISTINCT fu.subscription_id) AS distinct_subscriptions_using,
    SUM(fu.usage_count) AS total_usage_events,
    ROUND(SUM(fu.usage_duration_secs) / 3600.0, 2) AS total_usage_hours,
    SUM(fu.error_count) AS total_errors_logged,
    ROUND(
        SUM(fu.error_count) * 100.0 / NULLIF(SUM(fu.usage_count), 0), 2
    ) AS error_rate_pct
FROM analytics.feature_usage fu
JOIN analytics.subscriptions s ON fu.subscription_id = s.subscription_id
GROUP BY 
    fu.feature_name,
    s.plan_tier,
    fu.is_beta_feature
ORDER BY total_usage_events DESC;

COMMENT ON VIEW analytics.vw_feature_adoption IS 
'Product feature adoption metrics tracking usage volume, cumulative hours, and error rate percentages per plan tier.';
