-- =============================================================================
-- Project:         B2B SaaS Customer Cohort & Retention Analytics Platform
-- File:            sql/06_rfm_analysis.sql
-- Role:            Principal Data Analyst / Senior Analytics Engineer
-- Target Engine:   PostgreSQL 13+
-- Purpose:         Production B2B SaaS Customer RFM (Recency, Frequency, Monetary)
--                  Segmentation & Behavioral Analytics Suite.
-- =============================================================================

SET search_path TO analytics, public;


-- =============================================================================
-- SECTION 1: CUSTOMER RECENCY
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 01
-- Business Question:
-- How many days have elapsed since each customer account's last active subscription start date?
--
-- Business Objective:
-- Measure contract recency to identify accounts approaching renewal or experiencing stagnant contract activity.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    MAX(s.start_date) AS last_subscription_start_date,
    (CURRENT_DATE - MAX(s.start_date)) AS subscription_recency_days
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
GROUP BY a.account_id, a.account_name, a.industry
ORDER BY subscription_recency_days ASC;
-- Expected Business Insight:
-- Quantifies days elapsed since most recent subscription contract start.


-- -----------------------------------------------------------------------------
-- Query 02
-- Business Question:
-- What is the recency (in days) of each customer account's most recent product feature interaction?
--
-- Business Objective:
-- Identify inactive or disengaged customer accounts based on product telemetry recency.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.plan_tier,
    MAX(fu.usage_date) AS last_feature_usage_date,
    (CURRENT_DATE - MAX(fu.usage_date)) AS product_usage_recency_days
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
INNER JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
GROUP BY a.account_id, a.account_name, a.plan_tier
ORDER BY product_usage_recency_days ASC;
-- Expected Business Insight:
-- Highlights product engagement recency to spot silent account drop-offs.


-- -----------------------------------------------------------------------------
-- Query 03
-- Business Question:
-- How many days have elapsed since each customer account last submitted a support ticket?
--
-- Business Objective:
-- Assess recent support interactions to detect recent customer friction.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.plan_tier,
    MAX(st.submitted_at::date) AS last_ticket_date,
    (CURRENT_DATE - MAX(st.submitted_at::date)) AS support_recency_days
FROM analytics.accounts a
LEFT JOIN analytics.support_tickets st ON a.account_id = st.account_id
GROUP BY a.account_id, a.account_name, a.plan_tier
ORDER BY support_recency_days ASC NULLS LAST;
-- Expected Business Insight:
-- Evaluates recent customer support interaction recency.


-- -----------------------------------------------------------------------------
-- Query 04
-- Business Question:
-- What is the account tenure in days since initial account signup date?
--
-- Business Objective:
-- Measure overall account age to distinguish new customers from seasoned accounts.
-- -----------------------------------------------------------------------------
SELECT 
    account_id,
    account_name,
    signup_date,
    (CURRENT_DATE - signup_date) AS account_tenure_days,
    ROUND((CURRENT_DATE - signup_date) / 30.44, 1) AS account_tenure_months
FROM analytics.accounts
ORDER BY account_tenure_days DESC;
-- Expected Business Insight:
-- Calculates total account age in days and months.


-- -----------------------------------------------------------------------------
-- Query 05
-- Business Question:
-- Multi-dimensional Recency Matrix: Compare subscription recency, product usage recency, and support ticket recency per account.
--
-- Business Objective:
-- Deliver a unified multi-touchpoint recency dashboard per customer account.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    (CURRENT_DATE - MAX(s.start_date)) AS sub_recency_days,
    (CURRENT_DATE - MAX(fu.usage_date)) AS usage_recency_days,
    (CURRENT_DATE - MAX(st.submitted_at::date)) AS support_recency_days
FROM analytics.accounts a
LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id
LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
LEFT JOIN analytics.support_tickets st ON a.account_id = st.account_id
GROUP BY a.account_id, a.account_name, a.industry
ORDER BY usage_recency_days ASC NULLS LAST;
-- Expected Business Insight:
-- Unified recency matrix across subscription, usage, and support domain interactions.


-- =============================================================================
-- SECTION 2: CUSTOMER FREQUENCY
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 06
-- Business Question:
-- What is the total subscription contract frequency count recorded per customer account?
--
-- Business Objective:
-- Measure historical contract renewal and expansion event frequency.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    COUNT(s.subscription_id) AS total_subscription_contracts
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
GROUP BY a.account_id, a.account_name, a.industry
ORDER BY total_subscription_contracts DESC;
-- Expected Business Insight:
-- Ranks accounts by total subscription contract count frequency.


-- -----------------------------------------------------------------------------
-- Query 07
-- Business Question:
-- What is the total cumulative product telemetry interaction frequency per customer account?
--
-- Business Objective:
-- Quantify total feature usage interactions to evaluate product stickiness.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.plan_tier,
    COALESCE(SUM(fu.usage_count), 0) AS total_feature_interactions
FROM analytics.accounts a
LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id
LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
GROUP BY a.account_id, a.account_name, a.plan_tier
ORDER BY total_feature_interactions DESC;
-- Expected Business Insight:
-- Quantifies total feature clicks logged per account.


-- -----------------------------------------------------------------------------
-- Query 08
-- Business Question:
-- What is the total support ticket submission frequency per customer account?
--
-- Business Objective:
-- Assess customer support engagement frequency to identify high-touch accounts.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.plan_tier,
    COUNT(st.ticket_id) AS total_support_tickets_submitted
FROM analytics.accounts a
LEFT JOIN analytics.support_tickets st ON a.account_id = st.account_id
GROUP BY a.account_id, a.account_name, a.plan_tier
ORDER BY total_support_tickets_submitted DESC;
-- Expected Business Insight:
-- Measures support ticket creation frequency per account.


-- -----------------------------------------------------------------------------
-- Query 09
-- Business Question:
-- What is the average monthly feature interaction frequency per active month per customer account?
--
-- Business Objective:
-- Normalize feature usage frequency by account tenure to compare user engagement velocity fairly.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    ROUND((CURRENT_DATE - a.signup_date) / 30.44, 1) AS tenure_months,
    COALESCE(SUM(fu.usage_count), 0) AS total_interactions,
    ROUND(
        COALESCE(SUM(fu.usage_count), 0) / NULLIF((CURRENT_DATE - a.signup_date) / 30.44, 0), 1
    ) AS avg_monthly_interaction_frequency
FROM analytics.accounts a
LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id
LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
GROUP BY a.account_id, a.account_name, a.signup_date
ORDER BY avg_monthly_interaction_frequency DESC;
-- Expected Business Insight:
-- Calculates monthly feature usage velocity per tenure month.


-- -----------------------------------------------------------------------------
-- Query 10
-- Business Question:
-- Unified Frequency Profile: Combine subscription count, product session count, and support engagement into a single profile.
--
-- Business Objective:
-- Aggregate multi-channel interaction frequency to build holistic customer engagement scores.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    COUNT(DISTINCT s.subscription_id) AS subscription_frequency,
    COALESCE(SUM(fu.usage_count), 0) AS usage_frequency,
    COUNT(DISTINCT st.ticket_id) AS support_frequency
FROM analytics.accounts a
LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id
LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
LEFT JOIN analytics.support_tickets st ON a.account_id = st.account_id
GROUP BY a.account_id, a.account_name
ORDER BY usage_frequency DESC;
-- Expected Business Insight:
-- Multi-channel frequency summary table combining contract, usage, and support volume.


-- =============================================================================
-- SECTION 3: MONETARY ANALYSIS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 11
-- Business Question:
-- What is the total lifetime recurring revenue (MRR & ARR) generated by each customer account?
--
-- Business Objective:
-- Measure total financial capital contributed by each customer account across all contracts.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    COALESCE(SUM(s.mrr_amount), 0.00) AS total_lifetime_mrr_usd,
    COALESCE(SUM(s.arr_amount), 0.00) AS total_lifetime_arr_usd
FROM analytics.accounts a
LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id
GROUP BY a.account_id, a.account_name, a.industry, a.plan_tier
ORDER BY total_lifetime_mrr_usd DESC;
-- Expected Business Insight:
-- Ranks customer accounts by total lifetime recurring revenue generated.


-- -----------------------------------------------------------------------------
-- Query 12
-- Business Question:
-- What is the current active Monthly Recurring Revenue (MRR) contribution per customer account?
--
-- Business Objective:
-- Focus revenue optimization efforts on active recurring revenue contributions.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.plan_tier,
    COALESCE(SUM(s.mrr_amount), 0.00) AS active_mrr_usd
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.churn_flag = FALSE
GROUP BY a.account_id, a.account_name, a.plan_tier
ORDER BY active_mrr_usd DESC;
-- Expected Business Insight:
-- Ranks accounts by current active Monthly Recurring Revenue.


-- -----------------------------------------------------------------------------
-- Query 13
-- Business Question:
-- What is the current active Annualized Recurring Revenue (ARR) contribution per customer account?
--
-- Business Objective:
-- Identify high ARR customers for executive quarterly business reviews.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    COALESCE(SUM(s.arr_amount), 0.00) AS active_arr_usd
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.churn_flag = FALSE
GROUP BY a.account_id, a.account_name, a.industry
ORDER BY active_arr_usd DESC;
-- Expected Business Insight:
-- Highlights top ARR contributing customer accounts.


-- -----------------------------------------------------------------------------
-- Query 14
-- Business Question:
-- What is the cumulative refund amount issued to each customer account upon subscription cancellation or downgrade?
--
-- Business Objective:
-- Track financial refund leakage per account to audit billing adjustments.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    COALESCE(SUM(ce.refund_amount_usd), 0.00) AS total_refunds_usd
FROM analytics.accounts a
INNER JOIN analytics.churn_events ce ON a.account_id = ce.account_id
GROUP BY a.account_id, a.account_name, a.industry
HAVING SUM(ce.refund_amount_usd) > 0
ORDER BY total_refunds_usd DESC;
-- Expected Business Insight:
-- Details account-level refund payout totals.


-- -----------------------------------------------------------------------------
-- Query 15
-- Business Question:
-- What is the average contract monetary value (ARPA) across each customer's subscription history?
--
-- Business Objective:
-- Measure individual account average transaction value density.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    COUNT(s.subscription_id) AS total_contracts,
    ROUND(AVG(s.mrr_amount), 2) AS avg_contract_mrr_usd,
    SUM(s.mrr_amount) AS total_mrr_usd
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
GROUP BY a.account_id, a.account_name
ORDER BY avg_contract_mrr_usd DESC;
-- Expected Business Insight:
-- Calculates average contract value across customer account histories.


-- =============================================================================
-- SECTION 4: RFM SCORE CALCULATION
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 16
-- Business Question:
-- How are raw Recency, Frequency, and Monetary metrics compiled per account prior to scoring?
--
-- Business Objective:
-- Build base CTE containing raw R, F, M values per customer account.
-- -----------------------------------------------------------------------------
WITH rfm_raw AS (
    SELECT 
        a.account_id,
        a.account_name,
        -- Recency: Days since last product usage
        (CURRENT_DATE - COALESCE(MAX(fu.usage_date), a.signup_date)) AS recency_days,
        -- Frequency: Total product feature interactions
        COALESCE(SUM(fu.usage_count), 0) AS frequency_count,
        -- Monetary: Active MRR amount
        COALESCE(SUM(s.mrr_amount), 0.00) AS monetary_mrr
    FROM analytics.accounts a
    LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id AND s.churn_flag = FALSE
    LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY a.account_id, a.account_name, a.signup_date
)
SELECT * FROM rfm_raw
ORDER BY monetary_mrr DESC;
-- Expected Business Insight:
-- Base data matrix containing raw Recency (days), Frequency (usage count), and Monetary (MRR) inputs.


-- -----------------------------------------------------------------------------
-- Query 17
-- Business Question:
-- How are customer accounts assigned 1-5 quintile scores for Recency (R_Score), Frequency (F_Score), and Monetary (M_Score) using NTILE(5)?
--
-- Business Objective:
-- Standardize raw metrics into 1-5 quintiles (5 = Best, 1 = Worst). Note: Recency is inverted (lower days = higher score).
-- -----------------------------------------------------------------------------
WITH rfm_raw AS (
    SELECT 
        a.account_id,
        a.account_name,
        (CURRENT_DATE - COALESCE(MAX(fu.usage_date), a.signup_date)) AS recency_days,
        COALESCE(SUM(fu.usage_count), 0) AS frequency_count,
        COALESCE(SUM(s.mrr_amount), 0.00) AS monetary_mrr
    FROM analytics.accounts a
    LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id AND s.churn_flag = FALSE
    LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY a.account_id, a.account_name, a.signup_date
)
SELECT 
    account_id,
    account_name,
    recency_days,
    frequency_count,
    monetary_mrr,
    -- Recency: Inverted scoring (Lowest days gets 5)
    NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency_count ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary_mrr ASC) AS m_score
FROM rfm_raw
ORDER BY m_score DESC, f_score DESC, r_score DESC;
-- Expected Business Insight:
-- Assigns normalized 1 to 5 scores for R, F, and M dimensions.


-- -----------------------------------------------------------------------------
-- Query 18
-- Business Question:
-- How are R_Score, F_Score, and M_Score combined into a 3-digit RFM Code (e.g. '555', '543') and Total RFM Score?
--
-- Business Objective:
-- Create actionable composite RFM codes for customer segment tagging.
-- -----------------------------------------------------------------------------
WITH rfm_raw AS (
    SELECT 
        a.account_id,
        a.account_name,
        (CURRENT_DATE - COALESCE(MAX(fu.usage_date), a.signup_date)) AS recency_days,
        COALESCE(SUM(fu.usage_count), 0) AS frequency_count,
        COALESCE(SUM(s.mrr_amount), 0.00) AS monetary_mrr
    FROM analytics.accounts a
    LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id AND s.churn_flag = FALSE
    LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY a.account_id, a.account_name, a.signup_date
),
rfm_scores AS (
    SELECT 
        account_id,
        account_name,
        recency_days,
        frequency_count,
        monetary_mrr,
        NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency_count ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary_mrr ASC) AS m_score
    FROM rfm_raw
)
SELECT 
    account_id,
    account_name,
    recency_days,
    frequency_count,
    monetary_mrr,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_cell_code,
    (r_score + f_score + m_score) AS total_rfm_score
FROM rfm_scores
ORDER BY total_rfm_score DESC;
-- Expected Business Insight:
-- Generates 3-digit RFM cell codes ('555', '543', '111') and total composite score (3 to 15).


-- -----------------------------------------------------------------------------
-- Query 19
-- Business Question:
-- What is the distribution of customer accounts across distinct RFM Cell Codes?
--
-- Business Objective:
-- Audit density across RFM score combinations.
-- -----------------------------------------------------------------------------
WITH rfm_scores AS (
    SELECT 
        a.account_id,
        NTILE(5) OVER (ORDER BY (CURRENT_DATE - COALESCE(MAX(fu.usage_date), a.signup_date)) ASC) AS r_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(fu.usage_count), 0) ASC) AS f_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(s.mrr_amount), 0.00) ASC) AS m_score
    FROM analytics.accounts a
    LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id AND s.churn_flag = FALSE
    LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY a.account_id, a.signup_date
)
SELECT 
    CONCAT(r_score, f_score, m_score) AS rfm_cell_code,
    COUNT(account_id) AS account_count,
    ROUND(COUNT(account_id) * 100.0 / (SELECT COUNT(*) FROM analytics.accounts), 2) AS cell_share_pct
FROM rfm_scores
GROUP BY r_score, f_score, m_score
ORDER BY account_count DESC;
-- Expected Business Insight:
-- Groups customer base into 3-digit RFM cells to evaluate portfolio distribution.


-- =============================================================================
-- SECTION 5: CUSTOMER SEGMENTATION
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 20
-- Business Question:
-- How are customer accounts classified into strategic B2B SaaS segments (Champions, Loyal Customers, Power Users, At Risk, Lost) using RFM rules?
--
-- Business Objective:
-- Categorize entire customer base into actionable behavioral segments.
-- -----------------------------------------------------------------------------
WITH rfm_scores AS (
    SELECT 
        a.account_id,
        a.account_name,
        a.industry,
        a.plan_tier,
        COALESCE(SUM(s.mrr_amount), 0.00) AS active_mrr,
        NTILE(5) OVER (ORDER BY (CURRENT_DATE - COALESCE(MAX(fu.usage_date), a.signup_date)) ASC) AS r_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(fu.usage_count), 0) ASC) AS f_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(s.mrr_amount), 0.00) ASC) AS m_score
    FROM analytics.accounts a
    LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id AND s.churn_flag = FALSE
    LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY a.account_id, a.account_name, a.industry, a.plan_tier, a.signup_date
)
SELECT 
    account_id,
    account_name,
    industry,
    plan_tier,
    active_mrr,
    r_score, f_score, m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_code,
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
    END AS customer_segment
FROM rfm_scores
ORDER BY active_mrr DESC;
-- Expected Business Insight:
-- Complete customer segmentation table categorizing all accounts into 10 SaaS behavioral segments.


-- -----------------------------------------------------------------------------
-- Query 21
-- Business Question:
-- Who are our 'Champions' (R >= 4, F >= 4, M >= 4)?
--
-- Business Objective:
-- Build VIP customer advisory board and request strategic co-marketing testimonials.
-- -----------------------------------------------------------------------------
WITH rfm_scores AS (
    SELECT 
        a.account_id,
        a.account_name,
        a.industry,
        a.plan_tier,
        COALESCE(SUM(s.mrr_amount), 0.00) AS active_mrr,
        NTILE(5) OVER (ORDER BY (CURRENT_DATE - COALESCE(MAX(fu.usage_date), a.signup_date)) ASC) AS r_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(fu.usage_count), 0) ASC) AS f_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(s.mrr_amount), 0.00) ASC) AS m_score
    FROM analytics.accounts a
    LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id AND s.churn_flag = FALSE
    LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY a.account_id, a.account_name, a.industry, a.plan_tier, a.signup_date
)
SELECT 
    account_id,
    account_name,
    industry,
    plan_tier,
    active_mrr
FROM rfm_scores
WHERE r_score >= 4 AND f_score >= 4 AND m_score >= 4
ORDER BY active_mrr DESC;
-- Expected Business Insight:
-- Filters elite 'Champions' accounts driving high usage and high revenue.


-- -----------------------------------------------------------------------------
-- Query 22
-- Business Question:
-- Who are our 'Cannot Lose Them' and 'At Risk' customer accounts (Low Recency, High Monetary)?
--
-- Business Objective:
-- Generate immediate save list for executive Customer Success intervention before churn occurs.
-- -----------------------------------------------------------------------------
WITH rfm_scores AS (
    SELECT 
        a.account_id,
        a.account_name,
        a.industry,
        a.plan_tier,
        COALESCE(SUM(s.mrr_amount), 0.00) AS active_mrr,
        NTILE(5) OVER (ORDER BY (CURRENT_DATE - COALESCE(MAX(fu.usage_date), a.signup_date)) ASC) AS r_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(fu.usage_count), 0) ASC) AS f_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(s.mrr_amount), 0.00) ASC) AS m_score
    FROM analytics.accounts a
    LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id AND s.churn_flag = FALSE
    LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY a.account_id, a.account_name, a.industry, a.plan_tier, a.signup_date
)
SELECT 
    account_id,
    account_name,
    industry,
    plan_tier,
    active_mrr,
    r_score, f_score, m_score
FROM rfm_scores
WHERE r_score <= 2 AND m_score >= 3
ORDER BY active_mrr DESC;
-- Expected Business Insight:
-- Targets high-spending accounts exhibiting low recency for emergency CS outreach.


-- -----------------------------------------------------------------------------
-- Query 23
-- Business Question:
-- Who are our 'Potential Loyalists' and 'Promising' accounts (High Recency, Moderate Frequency/Monetary)?
--
-- Business Objective:
-- Focus account expansion and upsell campaigns on recently engaged growing accounts.
-- -----------------------------------------------------------------------------
WITH rfm_scores AS (
    SELECT 
        a.account_id,
        a.account_name,
        a.industry,
        a.plan_tier,
        COALESCE(SUM(s.mrr_amount), 0.00) AS active_mrr,
        NTILE(5) OVER (ORDER BY (CURRENT_DATE - COALESCE(MAX(fu.usage_date), a.signup_date)) ASC) AS r_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(fu.usage_count), 0) ASC) AS f_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(s.mrr_amount), 0.00) ASC) AS m_score
    FROM analytics.accounts a
    LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id AND s.churn_flag = FALSE
    LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY a.account_id, a.account_name, a.industry, a.plan_tier, a.signup_date
)
SELECT 
    account_id,
    account_name,
    industry,
    plan_tier,
    active_mrr
FROM rfm_scores
WHERE r_score >= 4 AND f_score BETWEEN 2 AND 4 AND m_score BETWEEN 2 AND 4
ORDER BY active_mrr DESC;
-- Expected Business Insight:
-- Identifies accounts suitable for cross-selling seat expansion and plan upgrades.


-- =============================================================================
-- SECTION 6: SEGMENT ANALYSIS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 24
-- Business Question:
-- What is the aggregate breakdown of customer account count, total MRR, total ARR, and average seats by RFM segment?
--
-- Business Objective:
-- Provide comprehensive financial comparison across customer segments.
-- -----------------------------------------------------------------------------
WITH rfm_scores AS (
    SELECT 
        a.account_id,
        a.seats,
        COALESCE(SUM(s.mrr_amount), 0.00) AS active_mrr,
        COALESCE(SUM(s.arr_amount), 0.00) AS active_arr,
        NTILE(5) OVER (ORDER BY (CURRENT_DATE - COALESCE(MAX(fu.usage_date), a.signup_date)) ASC) AS r_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(fu.usage_count), 0) ASC) AS f_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(s.mrr_amount), 0.00) ASC) AS m_score
    FROM analytics.accounts a
    LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id AND s.churn_flag = FALSE
    LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY a.account_id, a.seats, a.signup_date
),
rfm_segmented AS (
    SELECT 
        account_id,
        seats,
        active_mrr,
        active_arr,
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
        END AS customer_segment
    FROM rfm_scores
)
SELECT 
    customer_segment,
    COUNT(account_id) AS total_accounts,
    ROUND(COUNT(account_id) * 100.0 / (SELECT COUNT(*) FROM analytics.accounts), 2) AS account_share_pct,
    SUM(active_mrr) AS segment_mrr_usd,
    SUM(active_arr) AS segment_arr_usd,
    ROUND(AVG(active_mrr), 2) AS segment_arpa_usd,
    ROUND(AVG(seats), 1) AS avg_seats_per_account
FROM rfm_segmented
GROUP BY customer_segment
ORDER BY segment_mrr_usd DESC;
-- Expected Business Insight:
-- Financial summary table detailing revenue contribution and account volume by RFM segment.


-- -----------------------------------------------------------------------------
-- Query 25
-- Business Question:
-- What is the average product feature interaction volume, total usage hours, and error rate percentage per RFM segment?
--
-- Business Objective:
-- Evaluate product telemetry engagement metrics across customer segments.
-- -----------------------------------------------------------------------------
WITH rfm_scores AS (
    SELECT 
        a.account_id,
        COALESCE(SUM(fu.usage_count), 0) AS total_clicks,
        COALESCE(SUM(fu.usage_duration_secs), 0) AS total_duration_secs,
        COALESCE(SUM(fu.error_count), 0) AS total_errors,
        NTILE(5) OVER (ORDER BY (CURRENT_DATE - COALESCE(MAX(fu.usage_date), a.signup_date)) ASC) AS r_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(fu.usage_count), 0) ASC) AS f_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(s.mrr_amount), 0.00) ASC) AS m_score
    FROM analytics.accounts a
    LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id AND s.churn_flag = FALSE
    LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY a.account_id, a.signup_date
),
rfm_segmented AS (
    SELECT 
        account_id,
        total_clicks,
        total_duration_secs,
        total_errors,
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
        END AS customer_segment
    FROM rfm_scores
)
SELECT 
    customer_segment,
    COUNT(account_id) AS account_count,
    ROUND(AVG(total_clicks), 1) AS avg_feature_clicks,
    ROUND(SUM(total_duration_secs) / (COUNT(account_id) * 3600.0), 1) AS avg_usage_hours_per_account,
    ROUND(SUM(total_errors) * 100.0 / NULLIF(SUM(total_clicks), 0), 2) AS error_rate_pct
FROM rfm_segmented
GROUP BY customer_segment
ORDER BY avg_feature_clicks DESC;
-- Expected Business Insight:
-- Links RFM segments with product feature adoption density and technical error rates.


-- -----------------------------------------------------------------------------
-- Query 26
-- Business Question:
-- What is the support operation summary (ticket volume, CSAT, resolution time, escalations) across RFM segments?
--
-- Business Objective:
-- Audit customer support operational metrics across RFM segments.
-- -----------------------------------------------------------------------------
WITH rfm_scores AS (
    SELECT 
        a.account_id,
        NTILE(5) OVER (ORDER BY (CURRENT_DATE - COALESCE(MAX(fu.usage_date), a.signup_date)) ASC) AS r_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(fu.usage_count), 0) ASC) AS f_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(s.mrr_amount), 0.00) ASC) AS m_score
    FROM analytics.accounts a
    LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id AND s.churn_flag = FALSE
    LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY a.account_id, a.signup_date
),
rfm_segmented AS (
    SELECT 
        account_id,
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
        END AS customer_segment
    FROM rfm_scores
)
SELECT 
    rs.customer_segment,
    COUNT(DISTINCT rs.account_id) AS total_accounts,
    COUNT(st.ticket_id) AS total_support_tickets,
    ROUND(COUNT(st.ticket_id) * 1.0 / COUNT(DISTINCT rs.account_id), 2) AS tickets_per_account,
    ROUND(AVG(st.satisfaction_score), 2) AS avg_csat_score,
    ROUND(AVG(st.resolution_time_hours), 1) AS avg_resolution_time_hours,
    ROUND(SUM(CASE WHEN st.escalation_flag = TRUE THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(st.ticket_id), 0), 2) AS escalation_rate_pct
FROM rfm_segmented rs
LEFT JOIN analytics.support_tickets st ON rs.account_id = st.account_id
GROUP BY rs.customer_segment
ORDER BY tickets_per_account DESC;
-- Expected Business Insight:
-- Displays support ticket load, CSAT ratings, and escalation rates across RFM customer segments.


-- =============================================================================
-- SECTION 7: EXECUTIVE INSIGHTS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 27
-- Business Question:
-- Which RFM customer segment contributes the highest percentage of total company Monthly Recurring Revenue (MRR)?
--
-- Business Objective:
-- Identify the core revenue pillar segment driving top-line revenue performance.
-- -----------------------------------------------------------------------------
WITH rfm_scores AS (
    SELECT 
        a.account_id,
        COALESCE(SUM(s.mrr_amount), 0.00) AS active_mrr,
        NTILE(5) OVER (ORDER BY (CURRENT_DATE - COALESCE(MAX(fu.usage_date), a.signup_date)) ASC) AS r_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(fu.usage_count), 0) ASC) AS f_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(s.mrr_amount), 0.00) ASC) AS m_score
    FROM analytics.accounts a
    LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id AND s.churn_flag = FALSE
    LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY a.account_id, a.signup_date
),
segment_mrr AS (
    SELECT 
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
        END AS customer_segment,
        SUM(active_mrr) AS total_segment_mrr
    FROM rfm_scores
    GROUP BY customer_segment
)
SELECT 
    customer_segment,
    total_segment_mrr,
    ROUND(total_segment_mrr * 100.0 / (SELECT SUM(total_segment_mrr) FROM segment_mrr), 2) AS mrr_contribution_pct
FROM segment_mrr
ORDER BY total_segment_mrr DESC
LIMIT 1;
-- Expected Business Insight:
-- Reveals the #1 highest revenue-contributing RFM segment.


-- -----------------------------------------------------------------------------
-- Query 28
-- Business Question:
-- Which RFM customer segment exhibits the highest customer account churn rate percentage?
--
-- Business Objective:
-- Identify segments experiencing maximum account cancellations to guide retention campaigns.
-- -----------------------------------------------------------------------------
WITH rfm_scores AS (
    SELECT 
        a.account_id,
        a.churn_flag,
        NTILE(5) OVER (ORDER BY (CURRENT_DATE - COALESCE(MAX(fu.usage_date), a.signup_date)) ASC) AS r_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(fu.usage_count), 0) ASC) AS f_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(s.mrr_amount), 0.00) ASC) AS m_score
    FROM analytics.accounts a
    LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id
    LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY a.account_id, a.churn_flag, a.signup_date
),
segment_churn AS (
    SELECT 
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
        END AS customer_segment,
        COUNT(account_id) AS total_accounts,
        SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) AS churned_accounts
    FROM rfm_scores
    GROUP BY customer_segment
)
SELECT 
    customer_segment,
    total_accounts,
    churned_accounts,
    ROUND(churned_accounts * 100.0 / total_accounts, 2) AS segment_churn_rate_pct
FROM segment_churn
ORDER BY segment_churn_rate_pct DESC;
-- Expected Business Insight:
-- Ranks RFM segments by churn rate percentage to prioritize Customer Success save playbooks.


-- -----------------------------------------------------------------------------
-- Query 29
-- Business Question:
-- Executive Summary Scorecard: Unified RFM segment breakdown showing accounts, MRR, ARR, CSAT, usage, and recommended strategic actions.
--
-- Business Objective:
-- Generate executive dashboard master table mapping RFM segments directly to strategic business actions.
-- -----------------------------------------------------------------------------
WITH rfm_scores AS (
    SELECT 
        a.account_id,
        a.seats,
        COALESCE(SUM(s.mrr_amount), 0.00) AS active_mrr,
        COALESCE(SUM(s.arr_amount), 0.00) AS active_arr,
        NTILE(5) OVER (ORDER BY (CURRENT_DATE - COALESCE(MAX(fu.usage_date), a.signup_date)) ASC) AS r_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(fu.usage_count), 0) ASC) AS f_score,
        NTILE(5) OVER (ORDER BY COALESCE(SUM(s.mrr_amount), 0.00) ASC) AS m_score
    FROM analytics.accounts a
    LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id AND s.churn_flag = FALSE
    LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY a.account_id, a.seats, a.signup_date
),
rfm_segmented AS (
    SELECT 
        account_id,
        seats,
        active_mrr,
        active_arr,
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
        END AS customer_segment,
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
    FROM rfm_scores
)
SELECT 
    customer_segment,
    COUNT(account_id) AS total_accounts,
    ROUND(COUNT(account_id) * 100.0 / (SELECT COUNT(*) FROM analytics.accounts), 2) AS account_share_pct,
    SUM(active_mrr) AS segment_mrr_usd,
    SUM(active_arr) AS segment_arr_usd,
    ROUND(AVG(active_mrr), 2) AS segment_arpa_usd,
    strategic_action_playbook
FROM rfm_segmented
GROUP BY customer_segment, strategic_action_playbook
ORDER BY segment_mrr_usd DESC;
-- Expected Business Insight:
-- Executive Master Scorecard mapping RFM customer segments directly to actionable revenue playbooks.
