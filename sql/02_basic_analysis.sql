-- =============================================================================
-- Project:         B2B SaaS Customer Cohort & Retention Analytics Platform
-- File:            sql/02_basic_analysis.sql
-- Role:            Principal Data Analyst / Senior Business Intelligence Engineer
-- Target Engine:   PostgreSQL 13+
-- Purpose:         Foundational SQL analytics layer providing exploratory first-level 
--                  business metrics across customers, revenue, subscriptions, 
--                  marketing channels, support operations, product telemetry, 
--                  and churn drivers.
-- =============================================================================

SET search_path TO analytics, public;


-- =============================================================================
-- SECTION 1: CUSTOMER OVERVIEW
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Business Question 1.1:
-- What is the total volume of registered customer accounts in the platform?
--
-- Purpose:
-- Establishes the baseline total account count for executive reporting.
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(account_id) AS total_registered_accounts
FROM analytics.accounts;
-- Expected Business Insight:
-- Confirms total account population (500 accounts) to benchmark customer growth.


-- -----------------------------------------------------------------------------
-- Business Question 1.2:
-- How are customer accounts distributed across active, trial, and churned statuses?
--
-- Purpose:
-- Measures overall portfolio health and customer lifecycle breakdown.
-- -----------------------------------------------------------------------------
SELECT 
    churn_flag AS is_churned,
    is_trial AS is_on_trial,
    COUNT(account_id) AS account_count,
    ROUND(COUNT(account_id) * 100.0 / (SELECT COUNT(*) FROM analytics.accounts), 2) AS percentage_share
FROM analytics.accounts
GROUP BY churn_flag, is_trial
ORDER BY account_count DESC;
-- Expected Business Insight:
-- Reveals the proportion of healthy active accounts versus active trial evaluations and cancellations.


-- -----------------------------------------------------------------------------
-- Business Question 1.3:
-- Which industry verticals represent our largest customer account segments?
--
-- Purpose:
-- Identifies core market industry focus and vertical concentration risk.
-- -----------------------------------------------------------------------------
SELECT 
    industry,
    COUNT(account_id) AS total_accounts,
    ROUND(COUNT(account_id) * 100.0 / (SELECT COUNT(*) FROM analytics.accounts), 2) AS industry_share_pct
FROM analytics.accounts
GROUP BY industry
ORDER BY total_accounts DESC;
-- Expected Business Insight:
-- Highlights dominant market verticals (e.g., FinTech, DevTools, EdTech) driving platform adoption.


-- -----------------------------------------------------------------------------
-- Business Question 1.4:
-- Which geographical countries represent our primary customer bases?
--
-- Purpose:
-- Guides international expansion and regional customer success resource allocation.
-- -----------------------------------------------------------------------------
SELECT 
    country,
    COUNT(account_id) AS total_accounts,
    ROUND(COUNT(account_id) * 100.0 / (SELECT COUNT(*) FROM analytics.accounts), 2) AS geographic_share_pct
FROM analytics.accounts
GROUP BY country
ORDER BY total_accounts DESC;
-- Expected Business Insight:
-- Shows customer concentration across key geographies (e.g., US, IN, UK, DE, CA).


-- -----------------------------------------------------------------------------
-- Business Question 1.5:
-- How are customer accounts distributed across subscription plan tiers?
--
-- Purpose:
-- Evaluates tier adoption and plan positioning efficiency.
-- -----------------------------------------------------------------------------
SELECT 
    plan_tier,
    COUNT(account_id) AS total_accounts,
    ROUND(COUNT(account_id) * 100.0 / (SELECT COUNT(*) FROM analytics.accounts), 2) AS plan_share_pct
FROM analytics.accounts
GROUP BY plan_tier
ORDER BY total_accounts DESC;
-- Expected Business Insight:
-- Measures customer volume across Basic, Pro, and Enterprise plan tiers.


-- -----------------------------------------------------------------------------
-- Business Question 1.6:
-- What is the average, minimum, and maximum seat allocation per account by plan tier?
--
-- Purpose:
-- Assesses seat capacity utilization and pricing tier alignment.
-- -----------------------------------------------------------------------------
SELECT 
    plan_tier,
    COUNT(account_id) AS total_accounts,
    MIN(seats) AS min_seats_allocated,
    MAX(seats) AS max_seats_allocated,
    ROUND(AVG(seats), 1) AS avg_seats_per_account
FROM analytics.accounts
GROUP BY plan_tier
ORDER BY avg_seats_per_account DESC;
-- Expected Business Insight:
-- Demonstrates user scaling requirements as accounts transition from Basic to Enterprise tiers.


-- =============================================================================
-- SECTION 2: REVENUE OVERVIEW
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Business Question 2.1:
-- What is the total active Monthly Recurring Revenue (MRR) and Annual Recurring Revenue (ARR)?
--
-- Purpose:
-- Establishes core top-line recurring revenue benchmarks for executive leadership.
-- -----------------------------------------------------------------------------
SELECT 
    SUM(mrr_amount) AS total_active_mrr_usd,
    SUM(arr_amount) AS total_active_arr_usd,
    COUNT(subscription_id) AS total_active_subscriptions
FROM analytics.subscriptions
WHERE churn_flag = FALSE;
-- Expected Business Insight:
-- Quantifies current run-rate recurring revenue generated across active customer contracts.


-- -----------------------------------------------------------------------------
-- Business Question 2.2:
-- What is the Average Revenue Per Account (ARPA) across active paying customers?
--
-- Purpose:
-- Measures average account monetary density and unit economics efficiency.
-- -----------------------------------------------------------------------------
SELECT 
    ROUND(SUM(mrr_amount) / COUNT(DISTINCT account_id), 2) AS arpa_mrr_usd,
    ROUND(SUM(arr_amount) / COUNT(DISTINCT account_id), 2) AS arpa_arr_usd,
    COUNT(DISTINCT account_id) AS active_paying_accounts
FROM analytics.subscriptions
WHERE churn_flag = FALSE AND is_trial = FALSE;
-- Expected Business Insight:
-- Provides monthly and annual ARPA baselines for revenue forecasting.


-- -----------------------------------------------------------------------------
-- Business Question 2.3:
-- How much recurring revenue (MRR & ARR) is generated by each subscription plan tier?
--
-- Purpose:
-- Analyzes revenue contribution per product tier to evaluate monetization strategy.
-- -----------------------------------------------------------------------------
SELECT 
    plan_tier,
    COUNT(subscription_id) AS active_subscriptions,
    SUM(mrr_amount) AS total_mrr_usd,
    SUM(arr_amount) AS total_arr_usd,
    ROUND(AVG(mrr_amount), 2) AS avg_mrr_per_contract,
    ROUND(SUM(mrr_amount) * 100.0 / (SELECT SUM(mrr_amount) FROM analytics.subscriptions WHERE churn_flag = FALSE), 2) AS mrr_share_pct
FROM analytics.subscriptions
WHERE churn_flag = FALSE
GROUP BY plan_tier
ORDER BY total_mrr_usd DESC;
-- Expected Business Insight:
-- Identifies top revenue-generating plan tiers (e.g., Enterprise expansion impact).


-- -----------------------------------------------------------------------------
-- Business Question 2.4:
-- Which industry verticals generate the highest total Monthly Recurring Revenue?
--
-- Purpose:
-- Guides vertical sales targeting by identifying high-value customer industries.
-- -----------------------------------------------------------------------------
SELECT 
    a.industry,
    COUNT(DISTINCT a.account_id) AS customer_count,
    SUM(s.mrr_amount) AS total_industry_mrr_usd,
    ROUND(AVG(s.mrr_amount), 2) AS avg_mrr_per_customer
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.churn_flag = FALSE
GROUP BY a.industry
ORDER BY total_industry_mrr_usd DESC;
-- Expected Business Insight:
-- Ranks industries by total revenue yield and average account value.


-- -----------------------------------------------------------------------------
-- Business Question 2.5:
-- What is the total active MRR contribution breakdown by customer country?
--
-- Purpose:
-- Evaluates global revenue breakdown and regional expansion return.
-- -----------------------------------------------------------------------------
SELECT 
    a.country,
    COUNT(DISTINCT a.account_id) AS active_accounts,
    SUM(s.mrr_amount) AS total_country_mrr_usd,
    ROUND(SUM(s.mrr_amount) * 100.0 / (SELECT SUM(mrr_amount) FROM analytics.subscriptions WHERE churn_flag = FALSE), 2) AS mrr_country_share_pct
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.churn_flag = FALSE
GROUP BY a.country
ORDER BY total_country_mrr_usd DESC;
-- Expected Business Insight:
-- Highlights geographic revenue concentration to optimize regional marketing spend.


-- -----------------------------------------------------------------------------
-- Business Question 2.6:
-- Who are the top 10 customer accounts contributing the highest active Monthly Recurring Revenue?
--
-- Purpose:
-- Identifies key account relationships requiring dedicated VIP customer success management.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    SUM(s.mrr_amount) AS account_total_mrr_usd,
    SUM(s.arr_amount) AS account_total_arr_usd
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.churn_flag = FALSE
GROUP BY a.account_id, a.account_name, a.industry, a.plan_tier
ORDER BY account_total_mrr_usd DESC
LIMIT 10;
-- Expected Business Insight:
-- Pinpoints top 10 strategic accounts driving a disproportionate share of ARR.


-- =============================================================================
-- SECTION 3: SUBSCRIPTION OVERVIEW
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Business Question 3.1:
-- How are active subscriptions split between Monthly and Annual billing frequencies?
--
-- Purpose:
-- Evaluates billing preference and cash-flow predictability (annual contracts increase cash upfront).
-- -----------------------------------------------------------------------------
SELECT 
    billing_frequency,
    COUNT(subscription_id) AS contract_count,
    SUM(mrr_amount) AS total_mrr_usd,
    ROUND(COUNT(subscription_id) * 100.0 / (SELECT COUNT(*) FROM analytics.subscriptions WHERE churn_flag = FALSE), 2) AS contract_share_pct
FROM analytics.subscriptions
WHERE churn_flag = FALSE
GROUP BY billing_frequency
ORDER BY contract_count DESC;
-- Expected Business Insight:
-- Measures contract duration mix (Monthly vs. Annual) across active subscribers.


-- -----------------------------------------------------------------------------
-- Business Question 3.2:
-- How many subscription contracts represent expansion upgrades versus contraction downgrades?
--
-- Purpose:
-- Quantifies historical net contract movement direction across the account base.
-- -----------------------------------------------------------------------------
SELECT 
    upgrade_flag,
    downgrade_flag,
    COUNT(subscription_id) AS contract_count,
    SUM(mrr_amount) AS total_mrr_usd
FROM analytics.subscriptions
GROUP BY upgrade_flag, downgrade_flag
ORDER BY contract_count DESC;
-- Expected Business Insight:
-- Compares upgrade contract volume against downgrade contract volume.


-- -----------------------------------------------------------------------------
-- Business Question 3.3:
-- What percentage of active subscription contracts have auto-renewal enabled?
--
-- Purpose:
-- Predicts upcoming renewal friction and revenue retention risk.
-- -----------------------------------------------------------------------------
SELECT 
    auto_renew_flag,
    COUNT(subscription_id) AS active_contracts,
    ROUND(COUNT(subscription_id) * 100.0 / (SELECT COUNT(*) FROM analytics.subscriptions WHERE churn_flag = FALSE), 2) AS auto_renew_share_pct
FROM analytics.subscriptions
WHERE churn_flag = FALSE
GROUP BY auto_renew_flag;
-- Expected Business Insight:
-- Identifies accounts at risk of non-renewal due to disabled auto-renewal flags.


-- -----------------------------------------------------------------------------
-- Business Question 3.4:
-- What is the summary breakdown of free trial evaluations versus paid active contracts?
--
-- Purpose:
-- Monitors active trial volume and conversion pipeline potential.
-- -----------------------------------------------------------------------------
SELECT 
    is_trial,
    COUNT(subscription_id) AS total_contracts,
    SUM(mrr_amount) AS total_mrr_usd,
    ROUND(AVG(seats), 1) AS avg_seats
FROM analytics.subscriptions
WHERE churn_flag = FALSE
GROUP BY is_trial;
-- Expected Business Insight:
-- Evaluates trial contract distribution to assess pipeline conversion opportunities.


-- =============================================================================
-- SECTION 4: MARKETING OVERVIEW
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Business Question 4.1:
-- How many customer accounts were acquired through each marketing channel?
--
-- Purpose:
-- Evaluates channel volume productivity for customer acquisition.
-- -----------------------------------------------------------------------------
SELECT 
    mc.channel,
    COUNT(a.account_id) AS acquired_accounts,
    ROUND(COUNT(a.account_id) * 100.0 / (SELECT COUNT(*) FROM analytics.accounts), 2) AS channel_acquisition_share_pct
FROM analytics.accounts a
INNER JOIN analytics.marketing_campaigns mc ON a.campaign_id = mc.campaign_id
GROUP BY mc.channel
ORDER BY acquired_accounts DESC;
-- Expected Business Insight:
-- Identifies primary acquisition channels (e.g., Google Ads, LinkedIn, Referral).


-- -----------------------------------------------------------------------------
-- Business Question 4.2:
-- Which specific marketing campaigns generated the highest number of customer signups?
--
-- Purpose:
-- Highlights top-performing campaign initiatives for marketing attribution.
-- -----------------------------------------------------------------------------
SELECT 
    mc.campaign_id,
    mc.campaign_name,
    mc.channel,
    mc.campaign_type,
    COUNT(a.account_id) AS total_signups
FROM analytics.marketing_campaigns mc
INNER JOIN analytics.accounts a ON mc.campaign_id = a.campaign_id
GROUP BY mc.campaign_id, mc.campaign_name, mc.channel, mc.campaign_type
ORDER BY total_signups DESC
LIMIT 10;
-- Expected Business Insight:
-- Ranks top 10 campaigns by customer signup volume.


-- -----------------------------------------------------------------------------
-- Business Question 4.3:
-- What is the total budget, impressions, clicks, and conversions summary by campaign channel?
--
-- Purpose:
-- Evaluates macro marketing spend efficiency and channel funnel performance.
-- -----------------------------------------------------------------------------
SELECT 
    channel,
    COUNT(campaign_id) AS total_campaigns,
    SUM(budget_usd) AS total_channel_budget_usd,
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks,
    SUM(conversions) AS total_conversions
FROM analytics.marketing_campaigns
GROUP BY channel
ORDER BY total_channel_budget_usd DESC;
-- Expected Business Insight:
-- Compares marketing channel investments against funnel performance indicators.


-- -----------------------------------------------------------------------------
-- Business Question 4.4:
-- What is the average conversion rate and cost per conversion across marketing channels?
--
-- Purpose:
-- Measures financial efficiency and unit acquisition economics per channel.
-- -----------------------------------------------------------------------------
SELECT 
    channel,
    SUM(budget_usd) AS total_budget_usd,
    SUM(conversions) AS total_conversions,
    ROUND(SUM(clicks) * 100.0 / NULLIF(SUM(impressions), 0), 2) AS avg_ctr_pct,
    ROUND(SUM(conversions) * 100.0 / NULLIF(SUM(clicks), 0), 2) AS avg_conversion_rate_pct,
    ROUND(SUM(budget_usd) / NULLIF(SUM(conversions), 0), 2) AS cost_per_conversion_usd
FROM analytics.marketing_campaigns
GROUP BY channel
ORDER BY cost_per_conversion_usd ASC;
-- Expected Business Insight:
-- Reveals most cost-effective acquisition channels (lowest cost per conversion).


-- =============================================================================
-- SECTION 5: SUPPORT OVERVIEW
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Business Question 5.1:
-- What is the total volume of customer support tickets logged in the system?
--
-- Purpose:
-- Establishes overall customer service operational volume.
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(ticket_id) AS total_support_tickets,
    COUNT(DISTINCT account_id) AS unique_accounts_submitting_tickets
FROM analytics.support_tickets;
-- Expected Business Insight:
-- Quantifies support ticket volume and account touchpoint rates.


-- -----------------------------------------------------------------------------
-- Business Question 5.2:
-- How are support tickets distributed across urgency priority levels?
--
-- Purpose:
-- Measures customer issue severity and support resource requirements.
-- -----------------------------------------------------------------------------
SELECT 
    priority,
    COUNT(ticket_id) AS ticket_count,
    ROUND(COUNT(ticket_id) * 100.0 / (SELECT COUNT(*) FROM analytics.support_tickets), 2) AS priority_share_pct
FROM analytics.support_tickets
GROUP BY priority
ORDER BY ticket_count DESC;
-- Expected Business Insight:
-- Breaks down support load across Low, Medium, High, and Urgent priorities.


-- -----------------------------------------------------------------------------
-- Business Question 5.3:
-- What is the average resolution time (hours) and first response time (minutes) by priority level?
--
-- Purpose:
-- Audits Customer Support SLA adherence and operational responsiveness.
-- -----------------------------------------------------------------------------
SELECT 
    priority,
    COUNT(ticket_id) AS total_tickets,
    ROUND(AVG(first_response_time_minutes), 1) AS avg_first_response_mins,
    ROUND(AVG(resolution_time_hours), 1) AS avg_resolution_hours,
    MIN(resolution_time_hours) AS min_resolution_hours,
    MAX(resolution_time_hours) AS max_resolution_hours
FROM analytics.support_tickets
GROUP BY priority
ORDER BY avg_resolution_hours ASC;
-- Expected Business Insight:
-- Validates SLA compliance across priority tiers (Urgent tickets resolved faster).


-- -----------------------------------------------------------------------------
-- Business Question 5.4:
-- What is the average customer satisfaction score (CSAT) broken down by priority level?
--
-- Purpose:
-- Evaluates customer sentiment relative to issue severity.
-- -----------------------------------------------------------------------------
SELECT 
    priority,
    COUNT(satisfaction_score) AS rated_tickets_count,
    ROUND(AVG(satisfaction_score), 2) AS avg_csat_score
FROM analytics.support_tickets
WHERE satisfaction_score IS NOT NULL
GROUP BY priority
ORDER BY avg_csat_score DESC;
-- Expected Business Insight:
-- Measures CSAT rating scores (1.0 to 5.0 scale) across priority tiers.


-- -----------------------------------------------------------------------------
-- Business Question 5.5:
-- How many support tickets required escalation to senior engineering or specialist teams?
--
-- Purpose:
-- Identifies complex technical defect trends requiring product team intervention.
-- -----------------------------------------------------------------------------
SELECT 
    escalation_flag,
    priority,
    COUNT(ticket_id) AS ticket_count,
    ROUND(AVG(resolution_time_hours), 1) AS avg_resolution_hours
FROM analytics.support_tickets
GROUP BY escalation_flag, priority
ORDER BY escalation_flag DESC, ticket_count DESC;
-- Expected Business Insight:
-- Quantifies escalated ticket volume and resolution time inflation.


-- =============================================================================
-- SECTION 6: PRODUCT OVERVIEW
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Business Question 6.1:
-- What is the total volume of feature interactions and cumulative usage duration logged?
--
-- Purpose:
-- Establishes overall platform user engagement baselines.
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(usage_id) AS total_telemetry_records,
    SUM(usage_count) AS total_feature_interactions,
    ROUND(SUM(usage_duration_secs) / 3600.0, 2) AS total_usage_hours,
    SUM(error_count) AS total_errors_logged
FROM analytics.feature_usage;
-- Expected Business Insight:
-- Aggregates macro platform usage events, engagement hours, and error logs.


-- -----------------------------------------------------------------------------
-- Business Question 6.2:
-- What are the top 10 most heavily used platform features by total interaction count?
--
-- Purpose:
-- Identifies core sticky features driving product adoption.
-- -----------------------------------------------------------------------------
SELECT 
    feature_name,
    COUNT(DISTINCT subscription_id) AS distinct_subscriptions_using,
    SUM(usage_count) AS total_usage_events,
    ROUND(SUM(usage_duration_secs) / 3600.0, 1) AS total_engagement_hours
FROM analytics.feature_usage
GROUP BY feature_name
ORDER BY total_usage_events DESC
LIMIT 10;
-- Expected Business Insight:
-- Ranks top 10 core features by user interaction volume.


-- -----------------------------------------------------------------------------
-- Business Question 6.3:
-- How does usage volume and error rates compare between beta features and standard GA features?
--
-- Purpose:
-- Evaluates beta feature stability and adoption prior to general release.
-- -----------------------------------------------------------------------------
SELECT 
    is_beta_feature,
    COUNT(DISTINCT feature_name) AS distinct_features_count,
    SUM(usage_count) AS total_usage_events,
    SUM(error_count) AS total_errors,
    ROUND(SUM(error_count) * 100.0 / NULLIF(SUM(usage_count), 0), 2) AS error_rate_pct
FROM analytics.feature_usage
GROUP BY is_beta_feature;
-- Expected Business Insight:
-- Compares error rate percentages between GA features and beta features.


-- -----------------------------------------------------------------------------
-- Business Question 6.4:
-- What is the average session usage duration (in minutes) per feature interaction?
--
-- Purpose:
-- Identifies high-engagement time-intensive platform capabilities.
-- -----------------------------------------------------------------------------
SELECT 
    feature_name,
    SUM(usage_count) AS total_interactions,
    ROUND(AVG(usage_duration_secs) / 60.0, 2) AS avg_session_duration_minutes
FROM analytics.feature_usage
GROUP BY feature_name
ORDER BY avg_session_duration_minutes DESC
LIMIT 10;
-- Expected Business Insight:
-- Highlights features requiring longest continuous user engagement.


-- =============================================================================
-- SECTION 7: SIMPLE CHURN OVERVIEW
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Business Question 7.1:
-- What is the overall customer account churn rate percentage across the entire dataset?
--
-- Purpose:
-- Establishes macro account churn rate baseline for the business.
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(account_id) AS total_accounts_ever,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) AS total_churned_accounts,
    SUM(CASE WHEN churn_flag = FALSE THEN 1 ELSE 0 END) AS total_active_accounts,
    ROUND(SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(account_id), 2) AS overall_churn_rate_pct
FROM analytics.accounts;
-- Expected Business Insight:
-- Measures overall account cancellation percentage baseline.


-- -----------------------------------------------------------------------------
-- Business Question 7.2:
-- Which industry verticals suffer from the highest customer churn counts and churn rates?
--
-- Purpose:
-- Pinpoints vulnerable industry segments experiencing higher cancellation risk.
-- -----------------------------------------------------------------------------
SELECT 
    industry,
    COUNT(account_id) AS total_industry_accounts,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) AS churned_industry_accounts,
    ROUND(SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(account_id), 2) AS industry_churn_rate_pct
FROM analytics.accounts
GROUP BY industry
ORDER BY industry_churn_rate_pct DESC;
-- Expected Business Insight:
-- Ranks industries by churn rate percentage to focus CS retention programs.


-- -----------------------------------------------------------------------------
-- Business Question 7.3:
-- What is the churn count and churn rate percentage breakdown across subscription plan tiers?
--
-- Purpose:
-- Evaluates tier stability and price sensitivity churn triggers.
-- -----------------------------------------------------------------------------
SELECT 
    plan_tier,
    COUNT(account_id) AS total_tier_accounts,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) AS churned_tier_accounts,
    ROUND(SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(account_id), 2) AS tier_churn_rate_pct
FROM analytics.accounts
GROUP BY plan_tier
ORDER BY tier_churn_rate_pct DESC;
-- Expected Business Insight:
-- Compares churn rates across Basic, Pro, and Enterprise tiers.


-- -----------------------------------------------------------------------------
-- Business Question 7.4:
-- What are the primary reason codes driving customer cancellations, and total refunds issued?
--
-- Purpose:
-- Identifies top root causes of churn (pricing, support, missing features, etc.) for product leadership.
-- -----------------------------------------------------------------------------
SELECT 
    reason_code,
    COUNT(churn_event_id) AS churn_event_count,
    SUM(refund_amount_usd) AS total_refunds_usd,
    ROUND(AVG(refund_amount_usd), 2) AS avg_refund_usd,
    ROUND(COUNT(churn_event_id) * 100.0 / (SELECT COUNT(*) FROM analytics.churn_events), 2) AS reason_share_pct
FROM analytics.churn_events
GROUP BY reason_code
ORDER BY churn_event_count DESC;
-- Expected Business Insight:
-- Categorizes cancellation drivers and total refund capital returned to customers.
