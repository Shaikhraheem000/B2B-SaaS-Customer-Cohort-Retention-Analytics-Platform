-- =============================================================================
-- Project:         B2B SaaS Customer Cohort & Retention Analytics Platform
-- File:            sql/09_dashboard_queries.sql
-- Role:            Principal BI Developer / Power BI Architect
-- Target Engine:   PostgreSQL 13+
-- Purpose:         Production Power BI dashboard reporting dataset queries.
--                  Queries strictly from the semantic layer views (07_analytics_views.sql)
--                  to provide 45 clean, optimized result sets across 8 BI pages.
-- =============================================================================

SET search_path TO analytics, public;


-- =============================================================================
-- PAGE 1: EXECUTIVE DASHBOARD
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Dashboard Name: Executive Dashboard
-- Visual Name: Executive KPI Cards
-- Purpose: Top-level executive metrics (Customers, Active, MRR, ARR, Churn %, ARPA).
-- Recommended Power BI Visual: KPI Card / Multi-Row Card
-- Expected Output Columns: total_customers, active_customers, churned_customers, overall_churn_rate_pct, total_mrr_usd, total_arr_usd, avg_arpa_usd
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(account_id) AS total_customers,
    SUM(CASE WHEN churn_flag = FALSE THEN 1 ELSE 0 END) AS active_customers,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(account_id), 2) AS overall_churn_rate_pct,
    SUM(active_mrr_usd) AS total_mrr_usd,
    SUM(active_arr_usd) AS total_arr_usd,
    ROUND(SUM(active_mrr_usd) / NULLIF(SUM(CASE WHEN churn_flag = FALSE THEN 1 ELSE 0 END), 0), 2) AS avg_arpa_usd
FROM analytics.vw_customer_revenue;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Executive Dashboard
-- Visual Name: Monthly Revenue Trend
-- Purpose: Track Monthly Recurring Revenue (MRR) and ARR trajectory over cohort months.
-- Recommended Power BI Visual: Line Chart / Area Chart
-- Expected Output Columns: cohort_month, m0_starting_mrr_usd, m12_retained_mrr_usd, m12_net_revenue_retention_nrr_pct
-- -----------------------------------------------------------------------------
SELECT 
    cohort_month,
    m0_starting_mrr_usd,
    m12_retained_mrr_usd,
    m12_net_revenue_retention_nrr_pct
FROM analytics.vw_cohort_summary
ORDER BY cohort_month ASC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Executive Dashboard
-- Visual Name: Customer Account Growth Trend
-- Purpose: Track monthly new customer acquisition vs retained customer counts.
-- Recommended Power BI Visual: Line and Stacked Column Chart
-- Expected Output Columns: cohort_month, initial_cohort_size, m12_retained_logos, m12_logo_retention_pct
-- -----------------------------------------------------------------------------
SELECT 
    cohort_month,
    initial_cohort_size,
    m12_retained_logos,
    m12_logo_retention_pct
FROM analytics.vw_cohort_summary
ORDER BY cohort_month ASC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Executive Dashboard
-- Visual Name: Executive KPI Summary Scorecard
-- Purpose: Monthly executive summary dataset detailing signups, MRR, NRR, and retention %.
-- Recommended Power BI Visual: Matrix / Table
-- Expected Output Columns: cohort_month, initial_cohort_size, m12_retained_logos, m12_logo_retention_pct, m0_starting_mrr_usd, m12_retained_mrr_usd, m12_net_revenue_retention_nrr_pct
-- -----------------------------------------------------------------------------
SELECT *
FROM analytics.vw_cohort_summary
ORDER BY cohort_month DESC;


-- =============================================================================
-- PAGE 2: CUSTOMER DASHBOARD
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Dashboard Name: Customer Dashboard
-- Visual Name: Customers by Industry
-- Purpose: Display customer account distribution across industry verticals.
-- Recommended Power BI Visual: Clustered Bar Chart / Treemap
-- Expected Output Columns: industry, total_accounts, active_accounts, churned_accounts, industry_churn_rate_pct
-- -----------------------------------------------------------------------------
SELECT 
    industry,
    total_accounts,
    active_accounts,
    churned_accounts,
    industry_churn_rate_pct
FROM analytics.vw_industry_performance
ORDER BY total_accounts DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Customer Dashboard
-- Visual Name: Customers by Country
-- Purpose: Geographic breakdown of customer accounts.
-- Recommended Power BI Visual: Map / Horizontal Bar Chart
-- Expected Output Columns: country, customer_count, active_mrr_usd
-- -----------------------------------------------------------------------------
SELECT 
    country,
    COUNT(account_id) AS customer_count,
    SUM(active_mrr_usd) AS total_country_mrr_usd
FROM analytics.vw_customer_overview o
INNER JOIN analytics.vw_customer_revenue r USING (account_id)
GROUP BY country
ORDER BY customer_count DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Customer Dashboard
-- Visual Name: Customers by Subscription Plan Tier
-- Purpose: Customer distribution across Basic, Pro, and Enterprise plan tiers.
-- Recommended Power BI Visual: Donut Chart / Pie Chart
-- Expected Output Columns: plan_tier, total_accounts, tier_mrr_usd
-- -----------------------------------------------------------------------------
SELECT 
    plan_tier,
    COUNT(account_id) AS total_accounts,
    SUM(active_mrr_usd) AS tier_mrr_usd
FROM analytics.vw_customer_revenue
WHERE churn_flag = FALSE
GROUP BY plan_tier
ORDER BY total_accounts DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Customer Dashboard
-- Visual Name: Monthly Customer Signup Growth
-- Purpose: Track monthly new account signup volume.
-- Recommended Power BI Visual: Column Chart
-- Expected Output Columns: signup_cohort_month, new_customer_signups
-- -----------------------------------------------------------------------------
SELECT 
    signup_cohort_month,
    COUNT(account_id) AS new_customer_signups
FROM analytics.vw_customer_overview
GROUP BY signup_cohort_month
ORDER BY signup_cohort_month ASC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Customer Dashboard
-- Visual Name: Top 10 Customer Accounts by Seat Count
-- Purpose: Identify largest seat deployment accounts.
-- Recommended Power BI Visual: Bar Chart / Table
-- Expected Output Columns: account_name, industry, plan_tier, seats, current_customer_status
-- -----------------------------------------------------------------------------
SELECT 
    account_name,
    industry,
    plan_tier,
    seats,
    current_customer_status
FROM analytics.vw_customer_overview
ORDER BY seats DESC
LIMIT 10;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Customer Dashboard
-- Visual Name: Customer Lifecycle Status Distribution
-- Purpose: Show active, trial, and churned status breakdown.
-- Recommended Power BI Visual: Donut Chart
-- Expected Output Columns: current_customer_status, account_count
-- -----------------------------------------------------------------------------
SELECT 
    current_customer_status,
    COUNT(account_id) AS account_count
FROM analytics.vw_customer_overview
GROUP BY current_customer_status
ORDER BY account_count DESC;


-- =============================================================================
-- PAGE 3: REVENUE DASHBOARD
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Dashboard Name: Revenue Dashboard
-- Visual Name: Monthly Recurring Revenue (MRR) by Industry
-- Purpose: Financial contribution breakdown by industry sector.
-- Recommended Power BI Visual: Stacked Bar Chart / Treemap
-- Expected Output Columns: industry, total_mrr_usd, total_arr_usd, industry_arpa_usd
-- -----------------------------------------------------------------------------
SELECT 
    industry,
    total_mrr_usd,
    total_arr_usd,
    industry_arpa_usd
FROM analytics.vw_industry_performance
ORDER BY total_mrr_usd DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Revenue Dashboard
-- Visual Name: Revenue by Country
-- Purpose: Regional recurring revenue contribution.
-- Recommended Power BI Visual: Map / Bar Chart
-- Expected Output Columns: country, total_mrr_usd, total_arr_usd
-- -----------------------------------------------------------------------------
SELECT 
    country,
    SUM(active_mrr_usd) AS total_mrr_usd,
    SUM(active_arr_usd) AS total_arr_usd
FROM analytics.vw_customer_overview o
INNER JOIN analytics.vw_customer_revenue r USING (account_id)
WHERE r.churn_flag = FALSE
GROUP BY country
ORDER BY total_mrr_usd DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Revenue Dashboard
-- Visual Name: Revenue Share by Plan Tier
-- Purpose: Revenue percentage breakdown by plan tier.
-- Recommended Power BI Visual: Donut Chart / Treemap
-- Expected Output Columns: plan_tier, tier_mrr_usd, mrr_share_pct
-- -----------------------------------------------------------------------------
SELECT 
    plan_tier,
    SUM(active_mrr_usd) AS tier_mrr_usd,
    ROUND(SUM(active_mrr_usd) * 100.0 / (SELECT SUM(active_mrr_usd) FROM analytics.vw_customer_revenue WHERE churn_flag = FALSE), 2) AS mrr_share_pct
FROM analytics.vw_customer_revenue
WHERE churn_flag = FALSE
GROUP BY plan_tier
ORDER BY tier_mrr_usd DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Revenue Dashboard
-- Visual Name: Monthly Revenue Waterfall Bridge
-- Purpose: Monthly MRR movement waterfall (New, Expansion, Contraction, Churn, Net New MRR).
-- Recommended Power BI Visual: Waterfall Chart
-- Expected Output Columns: waterfall_month, new_mrr_usd, expansion_mrr_usd, contraction_mrr_usd, churned_mrr_usd, net_new_mrr_usd
-- -----------------------------------------------------------------------------
SELECT 
    waterfall_month,
    new_mrr_usd,
    expansion_mrr_usd,
    contraction_mrr_usd,
    churned_mrr_usd,
    net_new_mrr_usd
FROM analytics.vw_monthly_revenue_waterfall
ORDER BY waterfall_month ASC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Revenue Dashboard
-- Visual Name: Quarterly Recurring Revenue Trend
-- Purpose: Quarterly MRR and ARR growth trend.
-- Recommended Power BI Visual: Column Chart
-- Expected Output Columns: contract_quarter, quarterly_mrr_usd, quarterly_arr_usd
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(start_date, 'YYYY"-Q"') || TO_CHAR(start_date, 'Q') AS contract_quarter,
    SUM(mrr_amount) AS quarterly_mrr_usd,
    SUM(arr_amount) AS quarterly_arr_usd
FROM analytics.vw_subscription_summary
WHERE churn_flag = FALSE
GROUP BY TO_CHAR(start_date, 'YYYY"-Q"') || TO_CHAR(start_date, 'Q')
ORDER BY contract_quarter ASC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Revenue Dashboard
-- Visual Name: Top 10 Revenue Customer Accounts
-- Purpose: Ranks top 10 financial account contributors.
-- Recommended Power BI Visual: Table / Bar Chart
-- Expected Output Columns: account_name, industry, plan_tier, active_mrr_usd, active_arr_usd, revenue_tier_category
-- -----------------------------------------------------------------------------
SELECT 
    account_name,
    industry,
    plan_tier,
    active_mrr_usd,
    active_arr_usd,
    revenue_tier_category
FROM analytics.vw_customer_revenue
WHERE churn_flag = FALSE
ORDER BY active_mrr_usd DESC
LIMIT 10;


-- =============================================================================
-- PAGE 4: MARKETING DASHBOARD
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Dashboard Name: Marketing Dashboard
-- Visual Name: Campaign Performance Matrix
-- Purpose: Comprehensive performance table per marketing campaign.
-- Recommended Power BI Visual: Matrix / Table
-- Expected Output Columns: campaign_name, channel, budget_usd, acquired_customer_accounts, acquired_mrr_usd, customer_acquisition_cost_cac, mrr_yield_per_budget_dollar
-- -----------------------------------------------------------------------------
SELECT 
    campaign_name,
    channel,
    budget_usd,
    acquired_customer_accounts,
    acquired_mrr_usd,
    customer_acquisition_cost_cac,
    mrr_yield_per_budget_dollar
FROM analytics.vw_marketing_performance
ORDER BY acquired_mrr_usd DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Marketing Dashboard
-- Visual Name: Acquisitions & Revenue by Channel
-- Purpose: Customer acquisition count and MRR generated per channel.
-- Recommended Power BI Visual: Clustered Column Chart
-- Expected Output Columns: channel, acquired_customer_accounts, acquired_mrr_usd
-- -----------------------------------------------------------------------------
SELECT 
    channel,
    SUM(acquired_customer_accounts) AS acquired_customer_accounts,
    SUM(acquired_mrr_usd) AS acquired_mrr_usd
FROM analytics.vw_marketing_performance
GROUP BY channel
ORDER BY acquired_mrr_usd DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Marketing Dashboard
-- Visual Name: Budget Spend vs Revenue Yield
-- Purpose: Compare marketing budget spent against MRR acquired by campaign.
-- Recommended Power BI Visual: Scatter Plot
-- Expected Output Columns: campaign_name, channel, budget_usd, acquired_mrr_usd, customer_acquisition_cost_cac
-- -----------------------------------------------------------------------------
SELECT 
    campaign_name,
    channel,
    budget_usd,
    acquired_mrr_usd,
    customer_acquisition_cost_cac
FROM analytics.vw_marketing_performance
WHERE budget_usd > 0;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Marketing Dashboard
-- Visual Name: Conversion Rate by Channel
-- Purpose: Ad conversion rate percentage per marketing channel.
-- Recommended Power BI Visual: Bar Chart / Gauge
-- Expected Output Columns: channel, avg_conversion_rate_pct, avg_ctr_pct
-- -----------------------------------------------------------------------------
SELECT 
    channel,
    ROUND(AVG(ad_conversion_rate_pct), 2) AS avg_conversion_rate_pct,
    ROUND(AVG(ctr_pct), 2) AS avg_ctr_pct
FROM analytics.vw_marketing_performance
GROUP BY channel
ORDER BY avg_conversion_rate_pct DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Marketing Dashboard
-- Visual Name: Customer Acquisition Cost (CAC) by Channel
-- Purpose: Average CAC in USD per channel.
-- Recommended Power BI Visual: Horizontal Bar Chart
-- Expected Output Columns: channel, avg_cac_usd
-- -----------------------------------------------------------------------------
SELECT 
    channel,
    ROUND(SUM(budget_usd) / NULLIF(SUM(acquired_customer_accounts), 0), 2) AS avg_cac_usd
FROM analytics.vw_marketing_performance
GROUP BY channel
ORDER BY avg_cac_usd ASC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Marketing Dashboard
-- Visual Name: Marketing Yield per Dollar (ROAS Metric)
-- Purpose: MRR generated per dollar spent by channel.
-- Recommended Power BI Visual: Bar Chart
-- Expected Output Columns: channel, mrr_yield_per_dollar
-- -----------------------------------------------------------------------------
SELECT 
    channel,
    ROUND(SUM(acquired_mrr_usd) / NULLIF(SUM(budget_usd), 0), 2) AS mrr_yield_per_dollar
FROM analytics.vw_marketing_performance
GROUP BY channel
ORDER BY mrr_yield_per_dollar DESC;


-- =============================================================================
-- PAGE 5: PRODUCT DASHBOARD
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Dashboard Name: Product Dashboard
-- Visual Name: Top 10 Most Adopted Features
-- Purpose: Ranks top 10 features by interaction count and usage hours.
-- Recommended Power BI Visual: Horizontal Bar Chart
-- Expected Output Columns: feature_name, is_beta_feature, total_interaction_events, total_usage_hours
-- -----------------------------------------------------------------------------
SELECT 
    feature_name,
    is_beta_feature,
    total_interaction_events,
    total_usage_hours
FROM analytics.vw_feature_usage_summary
ORDER BY total_interaction_events DESC
LIMIT 10;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Product Dashboard
-- Visual Name: Feature Usage by Adoption Category
-- Purpose: Display usage volume grouped by adoption category tiers.
-- Recommended Power BI Visual: Treemap / Donut Chart
-- Expected Output Columns: feature_adoption_category, total_interactions, feature_count
-- -----------------------------------------------------------------------------
SELECT 
    feature_adoption_category,
    SUM(total_interaction_events) AS total_interactions,
    COUNT(feature_name) AS feature_count
FROM analytics.vw_feature_usage_summary
GROUP BY feature_adoption_category
ORDER BY total_interactions DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Product Dashboard
-- Visual Name: Beta Feature Adoption & Error Rates
-- Purpose: Audit beta feature interaction volume and technical error rates.
-- Recommended Power BI Visual: Clustered Column & Line Chart
-- Expected Output Columns: feature_name, distinct_accounts_using, total_interaction_events, feature_error_rate_pct
-- -----------------------------------------------------------------------------
SELECT 
    feature_name,
    distinct_accounts_using,
    total_interaction_events,
    feature_error_rate_pct
FROM analytics.vw_feature_usage_summary
WHERE is_beta_feature = TRUE
ORDER BY total_interaction_events DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Product Dashboard
-- Visual Name: Product Health Summary Matrix
-- Purpose: Matrix overview of feature interactions, usage hours, and error rates.
-- Recommended Power BI Visual: Matrix / Table
-- Expected Output Columns: feature_name, is_beta_feature, distinct_accounts_using, total_interaction_events, total_usage_hours, total_errors_logged, feature_error_rate_pct
-- -----------------------------------------------------------------------------
SELECT *
FROM analytics.vw_feature_usage_summary
ORDER BY total_interaction_events DESC;


-- =============================================================================
-- PAGE 6: SUPPORT DASHBOARD
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Dashboard Name: Support Dashboard
-- Visual Name: Support Ticket Volume by Priority Level
-- Purpose: Distribution of support load across urgency priority tiers.
-- Recommended Power BI Visual: Donut Chart / Pie Chart
-- Expected Output Columns: priority, ticket_count
-- -----------------------------------------------------------------------------
SELECT 
    st.priority,
    COUNT(st.ticket_id) AS ticket_count
FROM analytics.support_tickets st
GROUP BY st.priority
ORDER BY ticket_count DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Support Dashboard
-- Visual Name: Average Resolution Time (Hours) by Priority
-- Purpose: SLA resolution speed across ticket priorities.
-- Recommended Power BI Visual: Bar Chart / Column Chart
-- Expected Output Columns: priority, avg_resolution_time_hours, avg_first_response_mins
-- -----------------------------------------------------------------------------
SELECT 
    st.priority,
    ROUND(AVG(st.resolution_time_hours), 1) AS avg_resolution_time_hours,
    ROUND(AVG(st.first_response_time_minutes), 1) AS avg_first_response_mins
FROM analytics.support_tickets st
GROUP BY st.priority
ORDER BY avg_resolution_time_hours ASC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Support Dashboard
-- Visual Name: Customer Satisfaction (CSAT) by Priority Level
-- Purpose: Average CSAT rating score across ticket priority levels.
-- Recommended Power BI Visual: Gauge / Bar Chart
-- Expected Output Columns: priority, avg_csat_score
-- -----------------------------------------------------------------------------
SELECT 
    st.priority,
    ROUND(AVG(st.satisfaction_score), 2) AS avg_csat_score
FROM analytics.support_tickets st
WHERE st.satisfaction_score IS NOT NULL
GROUP BY st.priority
ORDER BY avg_csat_score DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Support Dashboard
-- Visual Name: Escalation Rate Percentage by Plan Tier
-- Purpose: Technical ticket escalation percentage across subscription tiers.
-- Recommended Power BI Visual: Column Chart
-- Expected Output Columns: plan_tier, total_tickets, escalated_tickets, escalation_rate_pct
-- -----------------------------------------------------------------------------
SELECT 
    plan_tier,
    SUM(total_tickets_opened) AS total_tickets,
    SUM(escalated_tickets_count) AS escalated_tickets,
    ROUND(SUM(escalated_tickets_count) * 100.0 / NULLIF(SUM(total_tickets_opened), 0), 2) AS escalation_rate_pct
FROM analytics.vw_support_summary
GROUP BY plan_tier
ORDER BY escalation_rate_pct DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Support Dashboard
-- Visual Name: Support Workload & SLA Health Matrix by Account
-- Purpose: Account-level support summary matrix detailing tickets, CSAT, & resolution times.
-- Recommended Power BI Visual: Matrix / Table
-- Expected Output Columns: account_name, industry, plan_tier, total_tickets_opened, avg_resolution_time_hours, avg_csat_satisfaction_score, support_health_category
-- -----------------------------------------------------------------------------
SELECT *
FROM analytics.vw_support_summary
ORDER BY total_tickets_opened DESC;


-- =============================================================================
-- PAGE 7: RETENTION DASHBOARD
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Dashboard Name: Retention Dashboard
-- Visual Name: Monthly Churn Event & Refund Trend
-- Purpose: Monthly cancellation count and refund dollar trend.
-- Recommended Power BI Visual: Line and Clustered Column Chart
-- Expected Output Columns: churn_month, churn_events_count, total_refunds_usd
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(churn_date, 'YYYY-MM') AS churn_month,
    COUNT(churn_event_id) AS churn_events_count,
    SUM(refund_amount_usd) AS total_refunds_usd
FROM analytics.vw_churn_summary
GROUP BY TO_CHAR(churn_date, 'YYYY-MM')
ORDER BY churn_month ASC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Retention Dashboard
-- Visual Name: Customer Churn Distribution by Reason Code
-- Purpose: Categorized primary root cause cancellation reasons.
-- Recommended Power BI Visual: Donut Chart / Treemap
-- Expected Output Columns: reason_code, total_cancellations, total_refunds_usd
-- -----------------------------------------------------------------------------
SELECT 
    reason_code,
    COUNT(churn_event_id) AS total_cancellations,
    SUM(refund_amount_usd) AS total_refunds_usd
FROM analytics.vw_churn_summary
GROUP BY reason_code
ORDER BY total_cancellations DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Retention Dashboard
-- Visual Name: Customer Churn Rate % by Industry
-- Purpose: Industry vertical account churn rate comparison.
-- Recommended Power BI Visual: Horizontal Bar Chart
-- Expected Output Columns: industry, total_accounts, churned_accounts, industry_churn_rate_pct
-- -----------------------------------------------------------------------------
SELECT 
    industry,
    total_accounts,
    churned_accounts,
    industry_churn_rate_pct
FROM analytics.vw_industry_performance
ORDER BY industry_churn_rate_pct DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Retention Dashboard
-- Visual Name: Cohort Logo & Revenue Retention Matrix Dataset
-- Purpose: Complete cohort retention matrix dataset ($M_0 \dots M_{12}$).
-- Recommended Power BI Visual: Matrix (Heatmap formatting)
-- Expected Output Columns: cohort_month, initial_cohort_size, m12_retained_logos, m12_logo_retention_pct, m0_starting_mrr_usd, m12_retained_mrr_usd, m12_net_revenue_retention_nrr_pct
-- -----------------------------------------------------------------------------
SELECT *
FROM analytics.vw_cohort_summary
ORDER BY cohort_month ASC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Retention Dashboard
-- Visual Name: RFM Customer Segment Revenue & Account Distribution
-- Purpose: RFM behavioral segment portfolio distribution.
-- Recommended Power BI Visual: Treemap / Matrix
-- Expected Output Columns: rfm_customer_segment, total_accounts, account_share_pct, segment_mrr_usd, segment_arr_usd, strategic_action_playbook
-- -----------------------------------------------------------------------------
SELECT 
    rfm_customer_segment,
    COUNT(account_id) AS total_accounts,
    ROUND(COUNT(account_id) * 100.0 / (SELECT COUNT(*) FROM analytics.vw_rfm_segments), 2) AS account_share_pct,
    SUM(active_mrr) AS segment_mrr_usd,
    SUM(active_arr) AS segment_arr_usd,
    strategic_action_playbook
FROM analytics.vw_rfm_segments
GROUP BY rfm_customer_segment, strategic_action_playbook
ORDER BY segment_mrr_usd DESC;


-- =============================================================================
-- PAGE 8: EXECUTIVE SUMMARY DASHBOARD
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Dashboard Name: Executive Summary Dashboard
-- Visual Name: Top Executive Metrics Card
-- Purpose: High-level KPI summary card.
-- Recommended Power BI Visual: Multi-Row Card / KPI Visual
-- Expected Output Columns: total_accounts, active_accounts, total_mrr_usd, total_arr_usd, avg_arpa_usd
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(account_id) AS total_accounts,
    SUM(CASE WHEN churn_flag = FALSE THEN 1 ELSE 0 END) AS active_accounts,
    SUM(active_mrr_usd) AS total_mrr_usd,
    SUM(active_arr_usd) AS total_arr_usd,
    ROUND(SUM(active_mrr_usd) / NULLIF(SUM(CASE WHEN churn_flag = FALSE THEN 1 ELSE 0 END), 0), 2) AS avg_arpa_usd
FROM analytics.vw_customer_revenue;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Executive Summary Dashboard
-- Visual Name: Active Revenue at Risk by Customer Health Status
-- Purpose: Total recurring revenue tied to Red, Yellow, and Green health statuses.
-- Recommended Power BI Visual: Donut Chart / Stacked Bar
-- Expected Output Columns: health_score_status, account_count, total_mrr_at_risk
-- -----------------------------------------------------------------------------
SELECT 
    health_score_status,
    COUNT(account_id) AS account_count,
    SUM(active_mrr) AS total_mrr_at_risk
FROM analytics.vw_customer_health_scorecard
WHERE churn_flag = FALSE
GROUP BY health_score_status
ORDER BY total_mrr_at_risk DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Executive Summary Dashboard
-- Visual Name: Customer Health Scorecard Roster
-- Purpose: 360-degree account health roster for Customer Success reviews.
-- Recommended Power BI Visual: Table / Matrix Visual
-- Expected Output Columns: account_name, industry, plan_tier, active_mrr, total_usage_clicks, total_tickets, avg_csat, health_score_status
-- -----------------------------------------------------------------------------
SELECT 
    account_name,
    industry,
    plan_tier,
    active_mrr,
    total_usage_clicks,
    total_tickets,
    avg_csat,
    health_score_status
FROM analytics.vw_customer_health_scorecard
WHERE churn_flag = FALSE
ORDER BY active_mrr DESC;


-- -----------------------------------------------------------------------------
-- Dashboard Name: Executive Summary Dashboard
-- Visual Name: Master Executive Action Plan Summary Matrix
-- Purpose: Actionable C-Suite strategic growth and retention roadmap.
-- Recommended Power BI Visual: Table / Grid Visual
-- Expected Output Columns: customer_segment, total_accounts, segment_mrr_usd, strategic_action_playbook
-- -----------------------------------------------------------------------------
SELECT 
    rfm_customer_segment,
    COUNT(account_id) AS total_accounts,
    SUM(active_mrr) AS segment_mrr_usd,
    strategic_action_playbook
FROM analytics.vw_rfm_segments
GROUP BY rfm_customer_segment, strategic_action_playbook
ORDER BY segment_mrr_usd DESC;
