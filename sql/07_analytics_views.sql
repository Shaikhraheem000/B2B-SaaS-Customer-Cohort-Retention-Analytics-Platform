-- =============================================================================
-- Project:         B2B SaaS Customer Cohort & Retention Analytics Platform
-- File:            sql/07_analytics_views.sql
-- Role:            Principal Analytics Engineer / Senior BI Developer
-- Target Engine:   PostgreSQL 13+
-- Purpose:         Semantic BI Data Layer providing 12 reusable, business-ready
--                  PostgreSQL analytical views optimized for Power BI, Tableau,
--                  Executive Dashboards, and Revenue Operations.
-- =============================================================================

SET search_path TO analytics, public;


-- =============================================================================
-- VIEW 1: vw_customer_overview
-- Purpose: Master customer profile dimension view combining account details,
--          tier classification, seat count, and campaign attribution.
-- Business Use Case: Customer 360 dashboards, CRM account rosters, and segmentation.
-- =============================================================================
CREATE OR REPLACE VIEW analytics.vw_customer_overview AS
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.country,
    a.plan_tier,
    a.seats,
    a.is_trial,
    a.churn_flag,
    CASE 
        WHEN a.churn_flag = TRUE THEN 'Churned'
        WHEN a.is_trial = TRUE THEN 'Trial Evaluation'
        ELSE 'Active Paid Subscriber'
    END AS current_customer_status,
    a.signup_date,
    TO_CHAR(a.signup_date, 'YYYY-MM') AS signup_cohort_month,
    a.referral_source,
    mc.campaign_id,
    mc.campaign_name,
    COALESCE(mc.channel, 'Organic/Direct') AS acquisition_channel
FROM analytics.accounts a
LEFT JOIN analytics.marketing_campaigns mc ON a.campaign_id = mc.campaign_id;

COMMENT ON VIEW analytics.vw_customer_overview IS 
'Master customer profile dimension view detailing account metadata, tier, status, and marketing channel attribution.';


-- =============================================================================
-- VIEW 2: vw_customer_revenue
-- Purpose: Account-level financial summary view calculating active MRR, ARR,
--          lifetime revenue, refunds, and revenue tier classifications.
-- Business Use Case: Power BI Revenue Dashboard, ARPA tracking, and financial tiering.
-- =============================================================================
CREATE OR REPLACE VIEW analytics.vw_customer_revenue AS
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    a.churn_flag,
    COALESCE(SUM(CASE WHEN s.churn_flag = FALSE THEN s.mrr_amount ELSE 0 END), 0.00) AS active_mrr_usd,
    COALESCE(SUM(CASE WHEN s.churn_flag = FALSE THEN s.arr_amount ELSE 0 END), 0.00) AS active_arr_usd,
    COALESCE(SUM(s.mrr_amount), 0.00) AS lifetime_mrr_generated_usd,
    COALESCE(ce.refund_amount_usd, 0.00) AS cumulative_refunds_issued_usd,
    COUNT(s.subscription_id) AS total_contracts_held,
    CASE 
        WHEN COALESCE(SUM(CASE WHEN s.churn_flag = FALSE THEN s.mrr_amount ELSE 0 END), 0) >= 2000 THEN 'Tier 1: Enterprise ($2k+)'
        WHEN COALESCE(SUM(CASE WHEN s.churn_flag = FALSE THEN s.mrr_amount ELSE 0 END), 0) >= 1000 THEN 'Tier 2: Mid-Market ($1k-$2k)'
        WHEN COALESCE(SUM(CASE WHEN s.churn_flag = FALSE THEN s.mrr_amount ELSE 0 END), 0) > 0 THEN 'Tier 3: SMB ($1-$999)'
        ELSE 'Tier 4: Non-Monetized ($0)'
    END AS revenue_tier_category
FROM analytics.accounts a
LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id
LEFT JOIN analytics.churn_events ce ON a.account_id = ce.account_id
GROUP BY a.account_id, a.account_name, a.industry, a.plan_tier, a.churn_flag, ce.refund_amount_usd;

COMMENT ON VIEW analytics.vw_customer_revenue IS 
'Account-level revenue financial rollup detailing active MRR, ARR, lifetime revenue, refunds, and revenue tier categories.';


-- =============================================================================
-- VIEW 3: vw_subscription_summary
-- Purpose: Contract lifecycle summary view detailing active vs churned status,
--          billing frequencies, upgrades, downgrades, and contract duration.
-- Business Use Case: Subscription Operations, Contract Renewals, and Billing Mix.
-- =============================================================================
CREATE OR REPLACE VIEW analytics.vw_subscription_summary AS
SELECT 
    s.subscription_id,
    s.account_id,
    a.account_name,
    s.plan_tier,
    s.billing_frequency,
    s.mrr_amount,
    s.arr_amount,
    s.is_trial,
    s.upgrade_flag,
    s.downgrade_flag,
    s.churn_flag,
    s.auto_renew_flag,
    s.start_date,
    s.end_date,
    COALESCE(s.end_date, CURRENT_DATE) - s.start_date AS contract_duration_days,
    ROUND((COALESCE(s.end_date, CURRENT_DATE) - s.start_date) / 30.44, 1) AS contract_duration_months,
    CASE 
        WHEN s.churn_flag = TRUE THEN 'Cancelled'
        WHEN s.is_trial = TRUE THEN 'Active Trial'
        WHEN s.end_date IS NULL OR s.end_date >= CURRENT_DATE THEN 'Active Paid Contract'
        ELSE 'Expired'
    END AS subscription_contract_status
FROM analytics.subscriptions s
INNER JOIN analytics.accounts a ON s.account_id = a.account_id;

COMMENT ON VIEW analytics.vw_subscription_summary IS 
'Subscription contract lifecycle view detailing billing frequency, contract upgrades/downgrades, and tenure duration.';


-- =============================================================================
-- VIEW 4: vw_marketing_performance
-- Purpose: Campaign & channel attribution view calculating acquisition spend,
--          impressions, clicks, conversions, acquired accounts, MRR, and CAC.
-- Business Use Case: Power BI Marketing Dashboard, Channel ROI, and CAC Payback.
-- =============================================================================
CREATE OR REPLACE VIEW analytics.vw_marketing_performance AS
SELECT 
    mc.campaign_id,
    mc.campaign_name,
    mc.channel,
    mc.campaign_type,
    mc.start_date,
    mc.end_date,
    mc.budget_usd,
    mc.impressions,
    mc.clicks,
    mc.conversions AS ad_conversions_count,
    COUNT(DISTINCT a.account_id) AS acquired_customer_accounts,
    COALESCE(SUM(s.mrr_amount), 0.00) AS acquired_mrr_usd,
    ROUND(mc.clicks * 100.0 / NULLIF(mc.impressions, 0), 2) AS ctr_pct,
    ROUND(mc.conversions * 100.0 / NULLIF(mc.clicks, 0), 2) AS ad_conversion_rate_pct,
    ROUND(mc.budget_usd / NULLIF(COUNT(DISTINCT a.account_id), 0), 2) AS customer_acquisition_cost_cac,
    ROUND(COALESCE(SUM(s.mrr_amount), 0.00) / NULLIF(mc.budget_usd, 0), 2) AS mrr_yield_per_budget_dollar
FROM analytics.marketing_campaigns mc
LEFT JOIN analytics.accounts a ON mc.campaign_id = a.campaign_id
LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id AND s.churn_flag = FALSE
GROUP BY mc.campaign_id, mc.campaign_name, mc.channel, mc.campaign_type, mc.start_date, mc.end_date, mc.budget_usd, mc.impressions, mc.clicks, mc.conversions;

COMMENT ON VIEW analytics.vw_marketing_performance IS 
'Marketing campaign attribution view measuring budget, impressions, acquisitions, MRR yield, and Customer Acquisition Cost (CAC).';


-- =============================================================================
-- VIEW 5: vw_feature_usage_summary
-- Purpose: Product telemetry rollup view summarizing feature interaction counts,
--          usage hours, error rates, beta adoption, and engagement categories.
-- Business Use Case: Power BI Product Telemetry Dashboard & Feature Popularity.
-- =============================================================================
CREATE OR REPLACE VIEW analytics.vw_feature_usage_summary AS
SELECT 
    fu.feature_name,
    fu.is_beta_feature,
    COUNT(DISTINCT fu.subscription_id) AS distinct_subscriptions_using,
    COUNT(DISTINCT s.account_id) AS distinct_accounts_using,
    SUM(fu.usage_count) AS total_interaction_events,
    ROUND(SUM(fu.usage_duration_secs) / 3600.0, 1) AS total_usage_hours,
    SUM(fu.error_count) AS total_errors_logged,
    ROUND(SUM(fu.error_count) * 100.0 / NULLIF(SUM(fu.usage_count), 0), 2) AS feature_error_rate_pct,
    CASE 
        WHEN SUM(fu.usage_count) >= 100000 THEN 'Tier 1: Core Mainstream Feature'
        WHEN SUM(fu.usage_count) >= 25000 THEN 'Tier 2: Moderate Adoption Feature'
        WHEN SUM(fu.usage_count) >= 5000 THEN 'Tier 3: Niche Specialty Feature'
        ELSE 'Tier 4: Low Adoption Feature'
    END AS feature_adoption_category
FROM analytics.feature_usage fu
INNER JOIN analytics.subscriptions s ON fu.subscription_id = s.subscription_id
GROUP BY fu.feature_name, fu.is_beta_feature;

COMMENT ON VIEW analytics.vw_feature_usage_summary IS 
'Product feature telemetry view summarizing usage volume, duration hours, error rates, and adoption categories.';


-- =============================================================================
-- VIEW 6: vw_support_summary
-- Purpose: Support operations summary view calculating ticket volumes, SLA
--          resolution times, response times, CSAT scores, & escalation rates.
-- Business Use Case: Power BI Support Operations Dashboard & SLA Health.
-- =============================================================================
CREATE OR REPLACE VIEW analytics.vw_support_summary AS
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    a.churn_flag,
    COUNT(st.ticket_id) AS total_tickets_opened,
    SUM(CASE WHEN LOWER(st.priority) IN ('urgent', 'high') THEN 1 ELSE 0 END) AS high_priority_tickets_count,
    SUM(CASE WHEN st.escalation_flag = TRUE THEN 1 ELSE 0 END) AS escalated_tickets_count,
    ROUND(AVG(st.first_response_time_minutes), 1) AS avg_first_response_mins,
    ROUND(AVG(st.resolution_time_hours), 1) AS avg_resolution_time_hours,
    ROUND(AVG(st.satisfaction_score), 2) AS avg_csat_satisfaction_score,
    CASE 
        WHEN COUNT(st.ticket_id) >= 10 THEN 'High Friction Account (10+ Tickets)'
        WHEN COUNT(st.ticket_id) >= 4 THEN 'Moderate Touch Account (4-9 Tickets)'
        WHEN COUNT(st.ticket_id) >= 1 THEN 'Low Touch Account (1-3 Tickets)'
        ELSE 'Zero Support Account (0 Tickets)'
    END AS support_health_category
FROM analytics.accounts a
LEFT JOIN analytics.support_tickets st ON a.account_id = st.account_id
GROUP BY a.account_id, a.account_name, a.industry, a.plan_tier, a.churn_flag;

COMMENT ON VIEW analytics.vw_support_summary IS 
'Support operations summary view detailing ticket counts, resolution SLA metrics, CSAT scores, and support health categories.';


-- =============================================================================
-- VIEW 7: vw_churn_summary
-- Purpose: Churn analytics view summarizing cancellation reasons, refund totals,
--          prior plan change flags, and customer lifespan months before churn.
-- Business Use Case: Power BI Churn Dashboard, Exit Interview Analysis, Save Lists.
-- =============================================================================
CREATE OR REPLACE VIEW analytics.vw_churn_summary AS
SELECT 
    ce.churn_event_id,
    ce.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    a.signup_date,
    ce.churn_date,
    ROUND((ce.churn_date - a.signup_date) / 30.44, 1) AS customer_lifetime_months,
    ce.reason_code,
    ce.refund_amount_usd,
    ce.preceding_upgrade_flag,
    ce.preceding_downgrade_flag,
    ce.is_reactivation,
    ce.feedback_text,
    CASE 
        WHEN (ce.churn_date - a.signup_date) <= 60 THEN 'Early Onboarding Churn (<= 60 days)'
        WHEN (ce.churn_date - a.signup_date) <= 180 THEN 'Mid-Term Churn (61-180 days)'
        WHEN (ce.churn_date - a.signup_date) <= 365 THEN 'First Year Churn (181-365 days)'
        ELSE 'Mature Account Churn (> 365 days)'
    END AS churn_tenure_category
FROM analytics.churn_events ce
INNER JOIN analytics.accounts a ON ce.account_id = a.account_id;

COMMENT ON VIEW analytics.vw_churn_summary IS 
'Churn event detailed view summarizing reason codes, refunds, customer lifetime months, and tenure churn categories.';


-- =============================================================================
-- VIEW 8: vw_cohort_summary
-- Purpose: Pre-aggregated cohort summary view computing signup cohort sizes,
--          Month 0 starting MRR, Month 12 retained MRR, NRR %, and Logo Retention %.
-- Business Use Case: Power BI Cohort Retention Heatmap & Executive Scorecards.
-- =============================================================================
CREATE OR REPLACE VIEW analytics.vw_cohort_summary AS
WITH cohort_base AS (
    SELECT 
        TO_CHAR(signup_date, 'YYYY-MM') AS cohort_month,
        COUNT(account_id) AS initial_logos
    FROM analytics.accounts
    GROUP BY TO_CHAR(signup_date, 'YYYY-MM')
),
m0_revenue AS (
    SELECT 
        TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
        SUM(s.mrr_amount) AS m0_starting_mrr
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    WHERE ((EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM a.signup_date)) * 12 +
           (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM a.signup_date))) = 0
    GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
),
m12_metrics AS (
    SELECT 
        TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
        COUNT(DISTINCT a.account_id) AS m12_logos,
        SUM(s.mrr_amount) AS m12_retained_mrr
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    WHERE s.churn_flag = FALSE
      AND ((EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM a.signup_date)) * 12 +
           (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM a.signup_date))) = 12
    GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
)
SELECT 
    cb.cohort_month,
    cb.initial_logos AS initial_cohort_size,
    COALESCE(m12.m12_logos, 0) AS m12_retained_logos,
    ROUND(COALESCE(m12.m12_logos, 0) * 100.0 / cb.initial_logos, 2) AS m12_logo_retention_pct,
    COALESCE(m0.m0_starting_mrr, 0.00) AS m0_starting_mrr_usd,
    COALESCE(m12.m12_retained_mrr, 0.00) AS m12_retained_mrr_usd,
    ROUND(COALESCE(m12.m12_retained_mrr, 0.00) * 100.0 / NULLIF(m0.m0_starting_mrr, 0), 2) AS m12_net_revenue_retention_nrr_pct
FROM cohort_base cb
LEFT JOIN m0_revenue m0 ON cb.cohort_month = m0.cohort_month
LEFT JOIN m12_metrics m12 ON cb.cohort_month = m12.cohort_month;

COMMENT ON VIEW analytics.vw_cohort_summary IS 
'Cohort master summary view detailing signup sizes, starting MRR, M12 retained MRR, NRR %, and Logo Retention %.';


-- =============================================================================
-- VIEW 9: vw_rfm_segments
-- Purpose: Customer RFM segmentation view assigning 1-5 R, F, M quintiles,
--          3-digit RFM codes, 10 SaaS behavioral segments, and playbooks.
-- Business Use Case: Power BI RFM Segmentation Matrix & CS Playbook Automation.
-- =============================================================================
CREATE OR REPLACE VIEW analytics.vw_rfm_segments AS
WITH rfm_scores AS (
    SELECT 
        a.account_id,
        a.account_name,
        a.industry,
        a.plan_tier,
        a.seats,
        COALESCE(SUM(s.mrr_amount), 0.00) AS active_mrr,
        COALESCE(SUM(s.arr_amount), 0.00) AS active_arr,
        (CURRENT_DATE - COALESCE(MAX(fu.usage_date), a.signup_date)) AS recency_days,
        COALESCE(SUM(fu.usage_count), 0) AS frequency_clicks,
        NTILE(5) OVER (ORDER BY (CURRENT_DATE - COALESCE(MAX(fu.usage_date), a.signup_date)) ASC) AS r_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(fu.usage_count), 0) ASC) AS f_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(s.mrr_amount), 0.00) ASC) AS m_score
    FROM analytics.accounts a
    LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id AND s.churn_flag = FALSE
    LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY a.account_id, a.account_name, a.industry, a.plan_tier, a.seats, a.signup_date
)
SELECT 
    account_id,
    account_name,
    industry,
    plan_tier,
    seats,
    active_mrr,
    active_arr,
    recency_days,
    frequency_clicks,
    r_score, f_score, m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_cell_code,
    (r_score + f_score + m_score) AS total_rfm_score,
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 4 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score >= 3 AND m_score >= 2 THEN 'Potential Loyalists'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score = 3 AND f_score = 3 AND m_score = 3 THEN 'Need Attention'
        WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'Cannot Lose Them'
        WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 4 THEN 'About To Sleep'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Hibernating / Lost'
        ELSE 'Promising'
    END AS rfm_customer_segment,
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Reward VIPs, Case Studies & Advocacy'
        WHEN r_score >= 3 AND f_score >= 4 AND m_score >= 3 THEN 'Upsell Higher Tiers & Cross-sell'
        WHEN r_score >= 4 AND f_score >= 3 AND m_score >= 2 THEN 'Onboarding Push & Engagement Incentives'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'Welcome Series & Feature Activation'
        WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4 THEN 'EMERGENCY: Dedicated CSM Save Outreach'
        WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'HIGH RISK: Product Training & CS Call'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 4 THEN 'Re-engagement Discount & CS Review'
        ELSE 'Win-back Campaign / Deprioritize'
    END AS strategic_action_playbook
FROM rfm_scores;

COMMENT ON VIEW analytics.vw_rfm_segments IS 
'Customer RFM segmentation view assigning scores (1-5), 3-digit cell codes, behavioral segments, and action playbooks.';


-- =============================================================================
-- VIEW 10: vw_monthly_revenue_waterfall (Optional Value-Add)
-- Purpose: Monthly MRR waterfall movement tracking (New, Expansion, Contraction, Churn, Net New MRR).
-- Business Use Case: Executive Revenue Bridge & Financial Reporting.
-- =============================================================================
CREATE OR REPLACE VIEW analytics.vw_monthly_revenue_waterfall AS
SELECT 
    TO_CHAR(s.start_date, 'YYYY-MM') AS waterfall_month,
    COALESCE(SUM(CASE WHEN s.upgrade_flag = FALSE AND s.downgrade_flag = FALSE AND s.churn_flag = FALSE THEN s.mrr_amount ELSE 0 END), 0.00) AS new_mrr_usd,
    COALESCE(SUM(CASE WHEN s.upgrade_flag = TRUE THEN s.mrr_amount ELSE 0 END), 0.00) AS expansion_mrr_usd,
    COALESCE(SUM(CASE WHEN s.downgrade_flag = TRUE THEN s.mrr_amount ELSE 0 END), 0.00) AS contraction_mrr_usd,
    COALESCE(SUM(CASE WHEN s.churn_flag = TRUE THEN s.mrr_amount ELSE 0 END), 0.00) AS churned_mrr_usd,
    COALESCE(SUM(CASE WHEN s.upgrade_flag = FALSE AND s.downgrade_flag = FALSE AND s.churn_flag = FALSE THEN s.mrr_amount ELSE 0 END), 0.00) +
    COALESCE(SUM(CASE WHEN s.upgrade_flag = TRUE THEN s.mrr_amount ELSE 0 END), 0.00) -
    COALESCE(SUM(CASE WHEN s.downgrade_flag = TRUE THEN s.mrr_amount ELSE 0 END), 0.00) -
    COALESCE(SUM(CASE WHEN s.churn_flag = TRUE THEN s.mrr_amount ELSE 0 END), 0.00) AS net_new_mrr_usd
FROM analytics.subscriptions s
GROUP BY TO_CHAR(s.start_date, 'YYYY-MM');

COMMENT ON VIEW analytics.vw_monthly_revenue_waterfall IS 
'Monthly recurring revenue waterfall view tracking New, Expansion, Contraction, Churn, and Net New MRR.';


-- =============================================================================
-- VIEW 11: vw_industry_performance (Optional Value-Add)
-- Purpose: Industry vertical benchmark summary detailing accounts, total MRR,
--          ARR, average ARPA, churn rate %, and CSAT.
-- Business Use Case: Market Vertical Benchmark Analysis.
-- =============================================================================
CREATE OR REPLACE VIEW analytics.vw_industry_performance AS
SELECT 
    a.industry,
    COUNT(DISTINCT a.account_id) AS total_accounts,
    COUNT(DISTINCT CASE WHEN a.churn_flag = FALSE THEN a.account_id END) AS active_accounts,
    COUNT(DISTINCT CASE WHEN a.churn_flag = TRUE THEN a.account_id END) AS churned_accounts,
    ROUND(
        COUNT(DISTINCT CASE WHEN a.churn_flag = TRUE THEN a.account_id END) * 100.0 / 
        COUNT(DISTINCT a.account_id), 2
    ) AS industry_churn_rate_pct,
    COALESCE(SUM(CASE WHEN s.churn_flag = FALSE THEN s.mrr_amount ELSE 0 END), 0.00) AS total_mrr_usd,
    COALESCE(SUM(CASE WHEN s.churn_flag = FALSE THEN s.arr_amount ELSE 0 END), 0.00) AS total_arr_usd,
    ROUND(
        COALESCE(SUM(CASE WHEN s.churn_flag = FALSE THEN s.mrr_amount ELSE 0 END), 0.00) / 
        NULLIF(COUNT(DISTINCT CASE WHEN a.churn_flag = FALSE THEN a.account_id END), 0), 2
    ) AS industry_arpa_usd,
    ROUND(AVG(st.satisfaction_score), 2) AS avg_industry_csat
FROM analytics.accounts a
LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id
LEFT JOIN analytics.support_tickets st ON a.account_id = st.account_id
GROUP BY a.industry;

COMMENT ON VIEW analytics.vw_industry_performance IS 
'Industry vertical performance view detailing account counts, MRR, ARR, ARPA, churn rate %, and CSAT.';


-- =============================================================================
-- VIEW 12: vw_customer_health_scorecard (Optional Value-Add)
-- Purpose: 360-degree Customer Health Scorecard combining active MRR, feature usage,
--          CSAT, tickets, and health risk classification.
-- Business Use Case: Customer Success Health Scorecard Dashboard & Risk Monitoring.
-- =============================================================================
CREATE OR REPLACE VIEW analytics.vw_customer_health_scorecard AS
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    a.churn_flag,
    COALESCE(SUM(s.mrr_amount), 0.00) AS active_mrr,
    COALESCE(SUM(fu.usage_count), 0) AS total_usage_clicks,
    COUNT(DISTINCT st.ticket_id) AS total_tickets,
    ROUND(AVG(st.satisfaction_score), 2) AS avg_csat,
    CASE 
        WHEN a.churn_flag = TRUE THEN 'RED - Churned'
        WHEN COALESCE(SUM(fu.usage_count), 0) < 100 AND COUNT(DISTINCT st.ticket_id) >= 3 THEN 'RED - High Churn Risk'
        WHEN COALESCE(AVG(st.satisfaction_score), 5.0) < 3.0 THEN 'YELLOW - Dissatisfied Risk'
        WHEN COALESCE(SUM(fu.usage_count), 0) >= 500 AND COALESCE(AVG(st.satisfaction_score), 5.0) >= 4.0 THEN 'GREEN - Healthy Account'
        ELSE 'YELLOW - Neutral Account'
    END AS health_score_status
FROM analytics.accounts a
LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id AND s.churn_flag = FALSE
LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
LEFT JOIN analytics.support_tickets st ON a.account_id = st.account_id
GROUP BY a.account_id, a.account_name, a.industry, a.plan_tier, a.churn_flag;

COMMENT ON VIEW analytics.vw_customer_health_scorecard IS 
'360-degree customer health scorecard view categorizing accounts into Red, Yellow, and Green risk statuses.';
