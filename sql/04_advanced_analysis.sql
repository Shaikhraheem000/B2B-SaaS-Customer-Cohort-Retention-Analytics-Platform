-- =============================================================================
-- Project:         B2B SaaS Customer Cohort & Retention Analytics Platform
-- File:            sql/04_advanced_analysis.sql
-- Role:            Principal Data Analyst / Senior Analytics Engineer
-- Target Engine:   PostgreSQL 13+
-- Purpose:         Advanced analytical SQL suite utilizing Window Functions
--                  (ROW_NUMBER, RANK, DENSE_RANK, NTILE, LAG, LEAD, FIRST_VALUE,
--                  LAST_VALUE, running totals, moving averages, percent contribution).
-- =============================================================================

SET search_path TO analytics, public;


-- =============================================================================
-- SECTION 1: CUSTOMER RANKING
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 01
-- Business Question:
-- How do active customer accounts rank globally by Monthly Recurring Revenue (MRR) using ROW_NUMBER, RANK, and DENSE_RANK?
--
-- Business Objective:
-- Evaluate rank gaps and handle ties in revenue valuation across top customer accounts.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    SUM(s.mrr_amount) AS total_mrr,
    ROW_NUMBER() OVER (ORDER BY SUM(s.mrr_amount) DESC) AS row_num,
    RANK() OVER (ORDER BY SUM(s.mrr_amount) DESC) AS mrr_rank,
    DENSE_RANK() OVER (ORDER BY SUM(s.mrr_amount) DESC) AS mrr_dense_rank
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.churn_flag = FALSE
GROUP BY a.account_id, a.account_name, a.industry, a.plan_tier
ORDER BY total_mrr DESC
LIMIT 15;
-- Expected Business Insight:
-- Provides a strict, ranked leaderboard of top-spending customer accounts.


-- -----------------------------------------------------------------------------
-- Query 02
-- Business Question:
-- Who are the top 3 customer accounts by seat allocation within each industry vertical?
--
-- Business Objective:
-- Identify major deployment anchors per industry vertical to build industry-specific case studies.
-- -----------------------------------------------------------------------------
WITH industry_seat_ranks AS (
    SELECT 
        account_id,
        account_name,
        industry,
        plan_tier,
        seats,
        DENSE_RANK() OVER (PARTITION BY industry ORDER BY seats DESC) AS industry_seat_rank
    FROM analytics.accounts
)
SELECT 
    account_id,
    account_name,
    industry,
    plan_tier,
    seats,
    industry_seat_rank
FROM industry_seat_ranks
WHERE industry_seat_rank <= 3
ORDER BY industry, industry_seat_rank;
-- Expected Business Insight:
-- Highlights the top 3 largest seat deployments in every industry sector.


-- -----------------------------------------------------------------------------
-- Query 03
-- Business Question:
-- Who is the top revenue-generating customer account in each country?
--
-- Business Objective:
-- Identify country market anchor accounts for international executive sponsorship.
-- -----------------------------------------------------------------------------
WITH country_revenue_ranks AS (
    SELECT 
        a.account_id,
        a.account_name,
        a.country,
        a.industry,
        SUM(s.mrr_amount) AS total_mrr,
        ROW_NUMBER() OVER (PARTITION BY a.country ORDER BY SUM(s.mrr_amount) DESC) AS country_rank
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    WHERE s.churn_flag = FALSE
    GROUP BY a.account_id, a.account_name, a.country, a.industry
)
SELECT 
    country,
    account_id,
    account_name,
    industry,
    total_mrr
FROM country_revenue_ranks
WHERE country_rank = 1
ORDER BY total_mrr DESC;
-- Expected Business Insight:
-- Pinpoints the single highest-value account in every geographical market.


-- -----------------------------------------------------------------------------
-- Query 04
-- Business Question:
-- Which customer accounts represent the first (#1) signup acquired per marketing campaign?
--
-- Business Objective:
-- Identify campaign trailblazer signups to analyze initial ad campaign traction.
-- -----------------------------------------------------------------------------
WITH campaign_first_signups AS (
    SELECT 
        a.account_id,
        a.account_name,
        a.campaign_id,
        mc.campaign_name,
        mc.channel,
        a.signup_date,
        ROW_NUMBER() OVER (PARTITION BY a.campaign_id ORDER BY a.signup_date ASC) AS signup_order
    FROM analytics.accounts a
    INNER JOIN analytics.marketing_campaigns mc ON a.campaign_id = mc.campaign_id
)
SELECT 
    campaign_id,
    campaign_name,
    channel,
    account_id,
    account_name,
    signup_date
FROM campaign_first_signups
WHERE signup_order = 1
ORDER BY signup_date DESC;
-- Expected Business Insight:
-- Isolates initial customer conversions logged after campaign product launches.


-- -----------------------------------------------------------------------------
-- Query 05
-- Business Question:
-- How are active customer accounts grouped into 4 revenue quartiles using NTILE(4)?
--
-- Business Objective:
-- Categorize accounts into spending quartiles (Q1 Top 25% to Q4 Bottom 25%) for tiered support SLAs.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    SUM(s.mrr_amount) AS total_mrr,
    NTILE(4) OVER (ORDER BY SUM(s.mrr_amount) DESC) AS revenue_quartile
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.churn_flag = FALSE
GROUP BY a.account_id, a.account_name, a.industry, a.plan_tier
ORDER BY total_mrr DESC;
-- Expected Business Insight:
-- Segments customer portfolio into 4 distinct financial tiers for resource planning.


-- =============================================================================
-- SECTION 2: REVENUE ANALYTICS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 06
-- Business Question:
-- What is the cumulative running total of active MRR accumulated month-by-month as new accounts sign up?
--
-- Business Objective:
-- Track cumulative recurring revenue growth trajectory over time.
-- -----------------------------------------------------------------------------
WITH monthly_new_mrr AS (
    SELECT 
        TO_CHAR(a.signup_date, 'YYYY-MM') AS signup_month,
        SUM(s.mrr_amount) AS new_cohort_mrr
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    WHERE s.churn_flag = FALSE
    GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
)
SELECT 
    signup_month,
    new_cohort_mrr,
    SUM(new_cohort_mrr) OVER (ORDER BY signup_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_running_mrr
FROM monthly_new_mrr
ORDER BY signup_month ASC;
-- Expected Business Insight:
-- Displays month-over-month compounding cumulative MRR growth.


-- -----------------------------------------------------------------------------
-- Query 07
-- Business Question:
-- What is the 3-month moving average of monthly recurring revenue additions?
--
-- Business Objective:
-- Smooth out monthly seasonality revenue spikes to identify underlying growth trends.
-- -----------------------------------------------------------------------------
WITH monthly_mrr_aggregates AS (
    SELECT 
        TO_CHAR(s.start_date, 'YYYY-MM') AS contract_month,
        SUM(s.mrr_amount) AS monthly_mrr
    FROM analytics.subscriptions s
    WHERE s.churn_flag = FALSE
    GROUP BY TO_CHAR(s.start_date, 'YYYY-MM')
)
SELECT 
    contract_month,
    monthly_mrr,
    ROUND(AVG(monthly_mrr) OVER (ORDER BY contract_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_mrr_3m
FROM monthly_mrr_aggregates
ORDER BY contract_month ASC;
-- Expected Business Insight:
-- Provides a smooth 3-month rolling average trend of new subscription MRR momentum.


-- -----------------------------------------------------------------------------
-- Query 08
-- Business Question:
-- What percentage contribution does each customer account's MRR make to their total industry revenue?
--
-- Business Objective:
-- Detect revenue concentration risk within individual industry sectors.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    SUM(s.mrr_amount) AS account_mrr,
    SUM(SUM(s.mrr_amount)) OVER (PARTITION BY a.industry) AS total_industry_mrr,
    ROUND(SUM(s.mrr_amount) * 100.0 / SUM(SUM(s.mrr_amount)) OVER (PARTITION BY a.industry), 2) AS industry_revenue_share_pct
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.churn_flag = FALSE
GROUP BY a.account_id, a.account_name, a.industry
ORDER BY a.industry, account_mrr DESC;
-- Expected Business Insight:
-- Shows individual account weight relative to its overall industry vertical.


-- -----------------------------------------------------------------------------
-- Query 09
-- Business Question:
-- Which customer accounts belong to the top 20% revenue bucket using NTILE(5)?
--
-- Business Objective:
-- Isolate Pareto 80/20 rule top customer accounts for executive advisory boards.
-- -----------------------------------------------------------------------------
WITH account_revenue_pentiles AS (
    SELECT 
        a.account_id,
        a.account_name,
        a.industry,
        SUM(s.mrr_amount) AS account_mrr,
        NTILE(5) OVER (ORDER BY SUM(s.mrr_amount) DESC) AS revenue_pentile
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    WHERE s.churn_flag = FALSE
    GROUP BY a.account_id, a.account_name, a.industry
)
SELECT 
    account_id,
    account_name,
    industry,
    account_mrr
FROM account_revenue_pentiles
WHERE revenue_pentile = 1
ORDER BY account_mrr DESC;
-- Expected Business Insight:
-- Isolates top 20% highest spending accounts generating bulk of platform revenue.


-- -----------------------------------------------------------------------------
-- Query 10
-- Business Question:
-- How does each account's MRR compare against the minimum, average, and maximum MRR of its plan tier window?
--
-- Business Objective:
-- Audit price customization variance within plan tiers to detect under-priced contracts.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.plan_tier,
    SUM(s.mrr_amount) AS account_mrr,
    MIN(SUM(s.mrr_amount)) OVER (PARTITION BY a.plan_tier) AS tier_min_mrr,
    ROUND(AVG(SUM(s.mrr_amount)) OVER (PARTITION BY a.plan_tier), 2) AS tier_avg_mrr,
    MAX(SUM(s.mrr_amount)) OVER (PARTITION BY a.plan_tier) AS tier_max_mrr
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.churn_flag = FALSE
GROUP BY a.account_id, a.account_name, a.plan_tier
ORDER BY a.plan_tier, account_mrr DESC;
-- Expected Business Insight:
-- Compares individual account pricing against tier minimum, average, and maximum bounds.


-- =============================================================================
-- SECTION 3: SUBSCRIPTION TRENDS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 11
-- Business Question:
-- What was each account's previous subscription plan tier and MRR prior to their current contract using LAG()?
--
-- Business Objective:
-- Track plan migration patterns (Basic -> Pro -> Enterprise) across customer contract histories.
-- -----------------------------------------------------------------------------
SELECT 
    s.account_id,
    s.subscription_id,
    s.start_date,
    s.plan_tier AS current_plan_tier,
    s.mrr_amount AS current_mrr,
    LAG(s.plan_tier, 1) OVER (PARTITION BY s.account_id ORDER BY s.start_date ASC) AS previous_plan_tier,
    LAG(s.mrr_amount, 1) OVER (PARTITION BY s.account_id ORDER BY s.start_date ASC) AS previous_mrr
FROM analytics.subscriptions s
ORDER BY s.account_id, s.start_date ASC;
-- Expected Business Insight:
-- Details account-level plan upgrade and downgrade transitions over time.


-- -----------------------------------------------------------------------------
-- Query 12
-- Business Question:
-- What is the exact net revenue change (Expansion or Contraction MRR) between consecutive subscription contracts using LAG()?
--
-- Business Objective:
-- Calculate delta revenue per contract change event to quantify expansion vs contraction velocity.
-- -----------------------------------------------------------------------------
WITH subscription_deltas AS (
    SELECT 
        s.account_id,
        s.subscription_id,
        s.start_date,
        s.mrr_amount AS current_mrr,
        LAG(s.mrr_amount, 1) OVER (PARTITION BY s.account_id ORDER BY s.start_date ASC) AS previous_mrr
    FROM analytics.subscriptions s
)
SELECT 
    account_id,
    subscription_id,
    start_date,
    current_mrr,
    previous_mrr,
    (current_mrr - COALESCE(previous_mrr, 0.00)) AS mrr_delta,
    CASE 
        WHEN previous_mrr IS NULL THEN 'New Contract'
        WHEN current_mrr > previous_mrr THEN 'Expansion Upgrade'
        WHEN current_mrr < previous_mrr THEN 'Contraction Downgrade'
        ELSE 'Flat Renewal'
    END AS contract_change_type
FROM subscription_deltas
ORDER BY account_id, start_date ASC;
-- Expected Business Insight:
-- Classifies every contract event as New, Expansion Upgrade, Contraction Downgrade, or Flat Renewal.


-- -----------------------------------------------------------------------------
-- Query 13
-- Business Question:
-- What is the next planned subscription tier for accounts with multiple contract changes using LEAD()?
--
-- Business Objective:
-- Map contract progression sequences across customer lifecycles.
-- -----------------------------------------------------------------------------
SELECT 
    s.account_id,
    s.subscription_id,
    s.start_date,
    s.plan_tier AS current_plan,
    LEAD(s.plan_tier, 1) OVER (PARTITION BY s.account_id ORDER BY s.start_date ASC) AS next_plan
FROM analytics.subscriptions s
ORDER BY s.account_id, s.start_date ASC;
-- Expected Business Insight:
-- Shows sequential contract tier changes across account lifecycles.


-- -----------------------------------------------------------------------------
-- Query 14
-- Business Question:
-- What was each customer's initial starting plan tier and initial starting MRR using FIRST_VALUE()?
--
-- Business Objective:
-- Compare starting contract value against current contract value to calculate lifetime account expansion multiplier.
-- -----------------------------------------------------------------------------
SELECT DISTINCT
    s.account_id,
    a.account_name,
    FIRST_VALUE(s.plan_tier) OVER (PARTITION BY s.account_id ORDER BY s.start_date ASC) AS initial_plan_tier,
    FIRST_VALUE(s.mrr_amount) OVER (PARTITION BY s.account_id ORDER BY s.start_date ASC) AS initial_mrr,
    LAST_VALUE(s.mrr_amount) OVER (
        PARTITION BY s.account_id 
        ORDER BY s.start_date ASC 
        RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS latest_mrr
FROM analytics.subscriptions s
INNER JOIN analytics.accounts a ON s.account_id = a.account_id
ORDER BY s.account_id;
-- Expected Business Insight:
-- Displays initial signup contract baseline versus latest contract value per account.


-- -----------------------------------------------------------------------------
-- Query 15
-- Business Question:
-- Which customer accounts have changed subscription plans more than twice?
--
-- Business Objective:
-- Identify highly dynamic accounts experiencing frequent contract restructuring.
-- -----------------------------------------------------------------------------
WITH account_contract_counts AS (
    SELECT 
        s.account_id,
        a.account_name,
        a.industry,
        COUNT(s.subscription_id) OVER (PARTITION BY s.account_id) AS total_contracts_count
    FROM analytics.subscriptions s
    INNER JOIN analytics.accounts a ON s.account_id = a.account_id
)
SELECT DISTINCT
    account_id,
    account_name,
    industry,
    total_contracts_count
FROM account_contract_counts
WHERE total_contracts_count > 2
ORDER BY total_contracts_count DESC;
-- Expected Business Insight:
-- Highlights volatile accounts with frequent upgrades or downgrades.


-- =============================================================================
-- SECTION 4: MARKETING PERFORMANCE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 16
-- Business Question:
-- How do marketing campaigns rank by acquired customer accounts within each acquisition channel using RANK()?
--
-- Business Objective:
-- Identify top campaign winners per marketing channel.
-- -----------------------------------------------------------------------------
WITH channel_campaign_counts AS (
    SELECT 
        mc.channel,
        mc.campaign_id,
        mc.campaign_name,
        COUNT(a.account_id) AS acquired_accounts
    FROM analytics.marketing_campaigns mc
    LEFT JOIN analytics.accounts a ON mc.campaign_id = a.campaign_id
    GROUP BY mc.channel, mc.campaign_id, mc.campaign_name
)
SELECT 
    channel,
    campaign_id,
    campaign_name,
    acquired_accounts,
    RANK() OVER (PARTITION BY channel ORDER BY acquired_accounts DESC) AS channel_campaign_rank
FROM channel_campaign_counts
ORDER BY channel, channel_campaign_rank;
-- Expected Business Insight:
-- Ranks campaigns relative to channel peer campaigns.


-- -----------------------------------------------------------------------------
-- Query 17
-- Business Question:
-- What is the cumulative running spend of marketing campaign budget over time?
--
-- Business Objective:
-- Monitor budget burn rate and cumulative capital deployed across campaign launches.
-- -----------------------------------------------------------------------------
SELECT 
    campaign_id,
    campaign_name,
    channel,
    start_date,
    budget_usd,
    SUM(budget_usd) OVER (ORDER BY start_date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_budget_spent_usd
FROM analytics.marketing_campaigns
ORDER BY start_date ASC;
-- Expected Business Insight:
-- Shows cumulative marketing budget deployment over campaign start dates.


-- -----------------------------------------------------------------------------
-- Query 18
-- Business Question:
-- How are marketing campaigns categorized into 4 efficiency quartiles based on Cost Per Conversion using NTILE(4)?
--
-- Business Objective:
-- Classify campaigns into Q1 (Most Efficient CAC) down to Q4 (Least Efficient CAC).
-- -----------------------------------------------------------------------------
SELECT 
    campaign_id,
    campaign_name,
    channel,
    budget_usd,
    conversions,
    ROUND(budget_usd / NULLIF(conversions, 0), 2) AS cost_per_conversion,
    NTILE(4) OVER (ORDER BY (budget_usd / NULLIF(conversions, 0)) ASC) AS cac_efficiency_quartile
FROM analytics.marketing_campaigns
WHERE conversions > 0
ORDER BY cost_per_conversion ASC;
-- Expected Business Insight:
-- Segments campaigns into 4 cost efficiency buckets.


-- -----------------------------------------------------------------------------
-- Query 19
-- Business Question:
-- What percentage contribution does each campaign's budget make to the total channel budget?
--
-- Business Objective:
-- Audit campaign spend allocation concentration within individual marketing channels.
-- -----------------------------------------------------------------------------
SELECT 
    campaign_id,
    campaign_name,
    channel,
    budget_usd,
    SUM(budget_usd) OVER (PARTITION BY channel) AS total_channel_budget,
    ROUND(budget_usd * 100.0 / SUM(budget_usd) OVER (PARTITION BY channel), 2) AS campaign_channel_budget_share_pct
FROM analytics.marketing_campaigns
ORDER BY channel, budget_usd DESC;
-- Expected Business Insight:
-- Reveals budget weight of individual campaigns within their respective channel budgets.


-- -----------------------------------------------------------------------------
-- Query 20
-- Business Question:
-- How does each campaign's budget compare to the average budget of its acquisition channel?
--
-- Business Objective:
-- Benchmark campaign scale against channel averages to identify over-funded ad tests.
-- -----------------------------------------------------------------------------
SELECT 
    campaign_id,
    campaign_name,
    channel,
    budget_usd,
    ROUND(AVG(budget_usd) OVER (PARTITION BY channel), 2) AS channel_avg_budget,
    ROUND(budget_usd - AVG(budget_usd) OVER (PARTITION BY channel), 2) AS budget_variance_from_channel_avg
FROM analytics.marketing_campaigns
ORDER BY channel, budget_usd DESC;
-- Expected Business Insight:
-- Identifies campaign spend deviations from channel norms.


-- =============================================================================
-- SECTION 5: SUPPORT ANALYTICS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 21
-- Business Question:
-- How do customer accounts rank by total support ticket volume using DENSE_RANK()?
--
-- Business Objective:
-- Identify high-friction accounts submitting disproportionate ticket counts.
-- -----------------------------------------------------------------------------
WITH customer_ticket_counts AS (
    SELECT 
        a.account_id,
        a.account_name,
        a.plan_tier,
        COUNT(st.ticket_id) AS total_tickets
    FROM analytics.accounts a
    INNER JOIN analytics.support_tickets st ON a.account_id = st.account_id
    GROUP BY a.account_id, a.account_name, a.plan_tier
)
SELECT 
    account_id,
    account_name,
    plan_tier,
    total_tickets,
    DENSE_RANK() OVER (ORDER BY total_tickets DESC) AS support_volume_rank
FROM customer_ticket_counts
ORDER BY support_volume_rank ASC
LIMIT 15;
-- Expected Business Insight:
-- Leaderboard of top 15 highest-volume support ticket submitters.


-- -----------------------------------------------------------------------------
-- Query 22
-- Business Question:
-- What is the cumulative running total of support tickets submitted per month across the platform?
--
-- Business Objective:
-- Track operational support workload growth over time.
-- -----------------------------------------------------------------------------
WITH monthly_tickets AS (
    SELECT 
        TO_CHAR(submitted_at, 'YYYY-MM') AS ticket_month,
        COUNT(ticket_id) AS monthly_ticket_count
    FROM analytics.support_tickets
    GROUP BY TO_CHAR(submitted_at, 'YYYY-MM')
)
SELECT 
    ticket_month,
    monthly_ticket_count,
    SUM(monthly_ticket_count) OVER (ORDER BY ticket_month ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_running_tickets
FROM monthly_tickets
ORDER BY ticket_month ASC;
-- Expected Business Insight:
-- Displays cumulative support workload trend across calendar months.


-- -----------------------------------------------------------------------------
-- Query 23
-- Business Question:
-- How does each support ticket's resolution time compare to the moving average resolution time of its priority level?
--
-- Business Objective:
-- Detect individual ticket resolution outliers that exceed moving SLA averages.
-- -----------------------------------------------------------------------------
SELECT 
    ticket_id,
    account_id,
    priority,
    resolution_time_hours,
    ROUND(AVG(resolution_time_hours) OVER (
        PARTITION BY priority 
        ORDER BY submitted_at ASC 
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
    ), 2) AS priority_moving_avg_resolution_hours
FROM analytics.support_tickets
WHERE resolution_time_hours IS NOT NULL
ORDER BY priority, submitted_at ASC
LIMIT 20;
-- Expected Business Insight:
-- Benchmarks individual ticket resolution against 5-ticket moving averages.


-- -----------------------------------------------------------------------------
-- Query 24
-- Business Question:
-- How does each account's CSAT score compare against the average CSAT score of its subscription plan tier?
--
-- Business Objective:
-- Identify dissatisfied accounts operating below tier average customer satisfaction scores.
-- -----------------------------------------------------------------------------
WITH customer_csat AS (
    SELECT 
        a.account_id,
        a.account_name,
        a.plan_tier,
        AVG(st.satisfaction_score) AS account_avg_csat
    FROM analytics.accounts a
    INNER JOIN analytics.support_tickets st ON a.account_id = st.account_id
    WHERE st.satisfaction_score IS NOT NULL
    GROUP BY a.account_id, a.account_name, a.plan_tier
)
SELECT 
    account_id,
    account_name,
    plan_tier,
    ROUND(account_avg_csat, 2) AS account_csat,
    ROUND(AVG(account_avg_csat) OVER (PARTITION BY plan_tier), 2) AS tier_avg_csat,
    ROUND(account_avg_csat - AVG(account_avg_csat) OVER (PARTITION BY plan_tier), 2) AS csat_variance_from_tier
FROM customer_csat
ORDER BY plan_tier, csat_variance_from_tier ASC;
-- Expected Business Insight:
-- Isolates accounts scoring below tier satisfaction benchmarks.


-- -----------------------------------------------------------------------------
-- Query 25
-- Business Question:
-- What is the minimum and maximum resolution time recorded within each priority tier using FIRST_VALUE() and LAST_VALUE()?
--
-- Business Objective:
-- Evaluate resolution SLA span (best-case vs worst-case) across ticket priority windows.
-- -----------------------------------------------------------------------------
SELECT DISTINCT
    priority,
    FIRST_VALUE(resolution_time_hours) OVER (
        PARTITION BY priority 
        ORDER BY resolution_time_hours ASC 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS fastest_resolution_hours,
    LAST_VALUE(resolution_time_hours) OVER (
        PARTITION BY priority 
        ORDER BY resolution_time_hours ASC 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS slowest_resolution_hours
FROM analytics.support_tickets
WHERE resolution_time_hours IS NOT NULL
ORDER BY priority;
-- Expected Business Insight:
-- Displays resolution time boundaries (min vs max) per priority level.


-- =============================================================================
-- SECTION 6: PRODUCT ANALYTICS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 26
-- Business Question:
-- How do platform features rank by total usage interaction volume within beta vs GA categories using DENSE_RANK()?
--
-- Business Objective:
-- Rank feature popularity separately for standard GA features and experimental beta features.
-- -----------------------------------------------------------------------------
WITH feature_totals AS (
    SELECT 
        feature_name,
        is_beta_feature,
        SUM(usage_count) AS total_clicks
    FROM analytics.feature_usage
    GROUP BY feature_name, is_beta_feature
)
SELECT 
    feature_name,
    is_beta_feature,
    total_clicks,
    DENSE_RANK() OVER (PARTITION BY is_beta_feature ORDER BY total_clicks DESC) AS category_rank
FROM feature_totals
ORDER BY is_beta_feature, category_rank;
-- Expected Business Insight:
-- Ranks feature popularity within GA and Beta taxonomy categories.


-- -----------------------------------------------------------------------------
-- Query 27
-- Business Question:
-- What is the cumulative running total of feature usage interaction events logged over calendar dates?
--
-- Business Objective:
-- Track product adoption acceleration over time.
-- -----------------------------------------------------------------------------
WITH daily_feature_events AS (
    SELECT 
        usage_date,
        SUM(usage_count) AS daily_clicks
    FROM analytics.feature_usage
    GROUP BY usage_date
)
SELECT 
    usage_date,
    daily_clicks,
    SUM(daily_clicks) OVER (ORDER BY usage_date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_running_usage
FROM daily_feature_events
ORDER BY usage_date ASC;
-- Expected Business Insight:
-- Cumulative timeline of total product feature interactions.


-- -----------------------------------------------------------------------------
-- Query 28
-- Business Question:
-- How does each feature's error rate percentage compare against the average error rate of its category?
--
-- Business Objective:
-- Identify unstable features generating error rates above category averages.
-- -----------------------------------------------------------------------------
WITH feature_error_rates AS (
    SELECT 
        feature_name,
        is_beta_feature,
        SUM(usage_count) AS total_clicks,
        SUM(error_count) AS total_errors,
        ROUND(SUM(error_count) * 100.0 / NULLIF(SUM(usage_count), 0), 2) AS feature_error_rate_pct
    FROM analytics.feature_usage
    GROUP BY feature_name, is_beta_feature
)
SELECT 
    feature_name,
    is_beta_feature,
    feature_error_rate_pct,
    ROUND(AVG(feature_error_rate_pct) OVER (PARTITION BY is_beta_feature), 2) AS category_avg_error_rate_pct,
    ROUND(feature_error_rate_pct - AVG(feature_error_rate_pct) OVER (PARTITION BY is_beta_feature), 2) AS error_rate_variance
FROM feature_error_rates
ORDER BY is_beta_feature, error_rate_variance DESC;
-- Expected Business Insight:
-- Flags bug-prone features exhibiting error rates higher than category averages.


-- -----------------------------------------------------------------------------
-- Query 29
-- Business Question:
-- How do customer accounts rank by product engagement hours within their subscription plan tier?
--
-- Business Objective:
-- Discover top power users in each pricing tier to create customer success champions.
-- -----------------------------------------------------------------------------
WITH account_engagement AS (
    SELECT 
        a.account_id,
        a.account_name,
        a.plan_tier,
        ROUND(SUM(fu.usage_duration_secs) / 3600.0, 1) AS engagement_hours
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    INNER JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY a.account_id, a.account_name, a.plan_tier
)
SELECT 
    account_id,
    account_name,
    plan_tier,
    engagement_hours,
    ROW_NUMBER() OVER (PARTITION BY plan_tier ORDER BY engagement_hours DESC) AS tier_engagement_rank
FROM account_engagement
ORDER BY plan_tier, tier_engagement_rank ASC;
-- Expected Business Insight:
-- Ranks power-user accounts within each subscription tier.


-- -----------------------------------------------------------------------------
-- Query 30
-- Business Question:
-- How are platform features divided into 4 adoption quartiles using NTILE(4)?
--
-- Business Objective:
-- Categorize features into Q1 (Core Mainstream) down to Q4 (Niche Low-Adoption).
-- -----------------------------------------------------------------------------
WITH feature_usage_totals AS (
    SELECT 
        feature_name,
        SUM(usage_count) AS total_clicks
    FROM analytics.feature_usage
    GROUP BY feature_name
)
SELECT 
    feature_name,
    total_clicks,
    NTILE(4) OVER (ORDER BY total_clicks DESC) AS feature_adoption_quartile
FROM feature_usage_totals
ORDER BY total_clicks DESC;
-- Expected Business Insight:
-- Segments entire feature catalog into 4 adoption quartiles.


-- =============================================================================
-- SECTION 7: CHURN INTELLIGENCE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 31
-- Business Question:
-- What is the monthly running cumulative sum of lost MRR due to customer churn events?
--
-- Business Objective:
-- Quantify cumulative revenue loss trajectory resulting from account cancellations.
-- -----------------------------------------------------------------------------
WITH monthly_churn_mrr AS (
    SELECT 
        TO_CHAR(ce.churn_date, 'YYYY-MM') AS churn_month,
        COUNT(ce.churn_event_id) AS churned_events_count,
        COALESCE(SUM(s.mrr_amount), 0.00) AS lost_mrr
    FROM analytics.churn_events ce
    LEFT JOIN analytics.subscriptions s ON ce.account_id = s.account_id AND s.churn_flag = TRUE
    GROUP BY TO_CHAR(ce.churn_date, 'YYYY-MM')
)
SELECT 
    churn_month,
    churned_events_count,
    lost_mrr,
    SUM(lost_mrr) OVER (ORDER BY churn_month ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_lost_mrr
FROM monthly_churn_mrr
ORDER BY churn_month ASC;
-- Expected Business Insight:
-- Tracks compounding cumulative revenue destruction over monthly cancellation events.


-- -----------------------------------------------------------------------------
-- Query 32
-- Business Question:
-- How do churn primary reason codes rank by total monetary refund issued using RANK()?
--
-- Business Objective:
-- Rank cancellation root causes by financial refund impact.
-- -----------------------------------------------------------------------------
WITH reason_refund_totals AS (
    SELECT 
        reason_code,
        COUNT(churn_event_id) AS churn_count,
        SUM(refund_amount_usd) AS total_refunds_usd
    FROM analytics.churn_events
    GROUP BY reason_code
)
SELECT 
    reason_code,
    churn_count,
    total_refunds_usd,
    RANK() OVER (ORDER BY total_refunds_usd DESC) AS refund_rank
FROM reason_refund_totals
ORDER BY refund_rank ASC;
-- Expected Business Insight:
-- Ranks churn reason codes by direct refund financial cost.


-- -----------------------------------------------------------------------------
-- Query 33
-- Business Question:
-- How does current month churn event volume compare against the previous month churn event volume using LAG()?
--
-- Business Objective:
-- Detect month-over-month acceleration or deceleration in customer cancellation events.
-- -----------------------------------------------------------------------------
WITH monthly_churn_counts AS (
    SELECT 
        TO_CHAR(churn_date, 'YYYY-MM') AS churn_month,
        COUNT(churn_event_id) AS monthly_churn_events
    FROM analytics.churn_events
    GROUP BY TO_CHAR(churn_date, 'YYYY-MM')
)
SELECT 
    churn_month,
    monthly_churn_events,
    LAG(monthly_churn_events, 1) OVER (ORDER BY churn_month ASC) AS previous_month_churn_events,
    (monthly_churn_events - LAG(monthly_churn_events, 1) OVER (ORDER BY churn_month ASC)) AS mom_churn_event_delta
FROM monthly_churn_counts
ORDER BY churn_month ASC;
-- Expected Business Insight:
-- Measures month-over-month change in account churn event counts.


-- -----------------------------------------------------------------------------
-- Query 34
-- Business Question:
-- What percentage contribution does each industry's churn count make to total company churn events?
--
-- Business Objective:
-- Evaluate industry concentration risk in customer cancellation volume.
-- -----------------------------------------------------------------------------
WITH industry_churn_counts AS (
    SELECT 
        a.industry,
        COUNT(ce.churn_event_id) AS industry_churn_count
    FROM analytics.churn_events ce
    INNER JOIN analytics.accounts a ON ce.account_id = a.account_id
    GROUP BY a.industry
)
SELECT 
    industry,
    industry_churn_count,
    SUM(industry_churn_count) OVER () AS grand_total_churn_events,
    ROUND(industry_churn_count * 100.0 / SUM(industry_churn_count) OVER (), 2) AS industry_churn_share_pct
FROM industry_churn_counts
ORDER BY industry_churn_count DESC;
-- Expected Business Insight:
-- Shows individual industry share of overall company cancellation events.


-- -----------------------------------------------------------------------------
-- Query 35
-- Business Question:
-- Which customer accounts churned immediately following a subscription contract downgrade using LAG(downgrade_flag)?
--
-- Business Objective:
-- Prove contraction downgrades act as an immediate precursor to complete account churn.
-- -----------------------------------------------------------------------------
WITH account_contract_history AS (
    SELECT 
        s.account_id,
        s.subscription_id,
        s.start_date,
        s.plan_tier,
        s.downgrade_flag,
        s.churn_flag,
        LAG(s.downgrade_flag, 1) OVER (PARTITION BY s.account_id ORDER BY s.start_date ASC) AS prior_was_downgrade
    FROM analytics.subscriptions s
)
SELECT 
    h.account_id,
    a.account_name,
    a.industry,
    h.subscription_id,
    h.plan_tier
FROM account_contract_history h
INNER JOIN analytics.accounts a ON h.account_id = a.account_id
WHERE h.churn_flag = TRUE 
  AND h.prior_was_downgrade = TRUE;
-- Expected Business Insight:
-- Identifies accounts that downgraded contracts prior to cancelling completely.


-- =============================================================================
-- SECTION 8: EXECUTIVE ANALYTICS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 36
-- Business Question:
-- What is the executive summary of monthly customer signups, cumulative customer count, monthly revenue, cumulative revenue, and MoM revenue growth rate using window functions?
--
-- Business Objective:
-- Provide a unified monthly scorecard for Board of Directors and Executive Leadership.
-- -----------------------------------------------------------------------------
WITH monthly_kpi_summary AS (
    SELECT 
        TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
        COUNT(DISTINCT a.account_id) AS new_accounts,
        SUM(s.mrr_amount) AS new_mrr
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    WHERE s.churn_flag = FALSE
    GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
)
SELECT 
    cohort_month,
    new_accounts,
    SUM(new_accounts) OVER (ORDER BY cohort_month ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_accounts,
    new_mrr,
    SUM(new_mrr) OVER (ORDER BY cohort_month ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_mrr,
    LAG(new_mrr, 1) OVER (ORDER BY cohort_month ASC) AS prev_month_mrr,
    ROUND(
        (new_mrr - LAG(new_mrr, 1) OVER (ORDER BY cohort_month ASC)) * 100.0 / 
        NULLIF(LAG(new_mrr, 1) OVER (ORDER BY cohort_month ASC), 0), 2
    ) AS mom_mrr_growth_rate_pct
FROM monthly_kpi_summary
ORDER BY cohort_month ASC;
-- Expected Business Insight:
-- Deliver executive overview of monthly user growth, cumulative user base, MRR additions, and MoM % growth rate.
