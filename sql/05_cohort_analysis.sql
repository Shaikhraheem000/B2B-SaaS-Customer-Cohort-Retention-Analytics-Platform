-- =============================================================================
-- Project:         B2B SaaS Customer Cohort & Retention Analytics Platform
-- File:            sql/05_cohort_analysis.sql
-- Role:            Principal Data Analyst / Senior Analytics Engineer
-- Target Engine:   PostgreSQL 13+
-- Purpose:         Production SaaS Cohort Analytics Suite implementing logo retention
--                  matrices, Net Revenue Retention (NRR %), Gross Revenue Retention
--                  (GRR %), cohort churn dynamics, and feature/support behavior.
-- =============================================================================

SET search_path TO analytics, public;


-- =============================================================================
-- SECTION 1: COHORT IDENTIFICATION
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 01
-- Business Question:
-- What is the customer signup volume breakdown across monthly acquisition cohorts (YYYY-MM)?
--
-- Business Objective:
-- Establish baseline monthly signup cohorts to track acquisition velocity.
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(signup_date, 'YYYY-MM') AS cohort_month,
    COUNT(account_id) AS total_acquired_customers,
    SUM(seats) AS total_initial_seats,
    ROUND(AVG(seats), 1) AS avg_seats_per_customer
FROM analytics.accounts
GROUP BY TO_CHAR(signup_date, 'YYYY-MM')
ORDER BY cohort_month ASC;
-- Expected Business Insight:
-- Details month-by-month customer logo acquisition volume and initial seat allocations.


-- -----------------------------------------------------------------------------
-- Query 02
-- Business Question:
-- What is the customer signup distribution across quarterly acquisition cohorts (YYYY-Q#)?
--
-- Business Objective:
-- Measure macro quarterly cohort growth trends for quarterly business reviews (QBR).
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(signup_date, 'YYYY"-Q"') || TO_CHAR(signup_date, 'Q') AS cohort_quarter,
    COUNT(account_id) AS total_acquired_customers,
    SUM(seats) AS total_seats
FROM analytics.accounts
GROUP BY TO_CHAR(signup_date, 'YYYY"-Q"') || TO_CHAR(signup_date, 'Q')
ORDER BY cohort_quarter ASC;
-- Expected Business Insight:
-- Aggregates customer signups into quarterly cohorts for macro trend evaluation.


-- -----------------------------------------------------------------------------
-- Query 03
-- Business Question:
-- How are annual customer cohorts (YYYY) distributed across initial subscription plan tiers?
--
-- Business Objective:
-- Evaluate long-term shifts in initial plan tier adoption across annual cohorts.
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(signup_date, 'YYYY') AS cohort_year,
    plan_tier,
    COUNT(account_id) AS customer_count,
    ROUND(COUNT(account_id) * 100.0 / SUM(COUNT(account_id)) OVER (PARTITION BY TO_CHAR(signup_date, 'YYYY')), 2) AS tier_share_pct
FROM analytics.accounts
GROUP BY TO_CHAR(signup_date, 'YYYY'), plan_tier
ORDER BY cohort_year ASC, customer_count DESC;
-- Expected Business Insight:
-- Tracks annual evolution of entry-level pricing plan mix.


-- -----------------------------------------------------------------------------
-- Query 04
-- Business Question:
-- What is the distribution of acquisition channels across monthly customer cohorts?
--
-- Business Objective:
-- Analyze channel mix migration across acquisition cohorts over time.
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
    COALESCE(mc.channel, 'Organic/Direct') AS acquisition_channel,
    COUNT(a.account_id) AS acquired_count
FROM analytics.accounts a
LEFT JOIN analytics.marketing_campaigns mc ON a.campaign_id = mc.campaign_id
GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM'), COALESCE(mc.channel, 'Organic/Direct')
ORDER BY cohort_month ASC, acquired_count DESC;
-- Expected Business Insight:
-- Maps changing channel acquisition contributions over monthly cohort windows.


-- =============================================================================
-- SECTION 2: RETENTION ANALYSIS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 05
-- Business Question:
-- What is the customer logo retention matrix by relative month index (Month 0 to Month 12)?
--
-- Business Objective:
-- Build the foundation for Power BI / BI Dashboard Logo Retention Heatmaps.
-- -----------------------------------------------------------------------------
WITH customer_cohorts AS (
    SELECT 
        account_id,
        TO_CHAR(signup_date, 'YYYY-MM') AS cohort_month,
        signup_date
    FROM analytics.accounts
),
monthly_snapshots AS (
    SELECT 
        cc.cohort_month,
        c.account_id,
        s.subscription_id,
        s.start_date,
        s.end_date,
        -- Relative month index calculation
        (EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM cc.signup_date)) * 12 +
        (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM cc.signup_date)) AS period_month
    FROM customer_cohorts cc
    INNER JOIN analytics.accounts c ON cc.account_id = c.account_id
    INNER JOIN analytics.subscriptions s ON c.account_id = s.account_id
    WHERE s.churn_flag = FALSE
)
SELECT 
    cohort_month,
    period_month,
    COUNT(DISTINCT account_id) AS retained_customers
FROM monthly_snapshots
WHERE period_month BETWEEN 0 AND 12
GROUP BY cohort_month, period_month
ORDER BY cohort_month ASC, period_month ASC;
-- Expected Business Insight:
-- Produces absolute retained customer counts for relative months 0 to 12.


-- -----------------------------------------------------------------------------
-- Query 06
-- Business Question:
-- What is the Logo Retention Percentage (%) matrix across monthly cohorts for relative Month 0 through Month 12?
--
-- Business Objective:
-- Generate normalized retention percentages for executive cohort decay curves and heatmaps.
-- -----------------------------------------------------------------------------
WITH cohort_sizes AS (
    SELECT 
        TO_CHAR(signup_date, 'YYYY-MM') AS cohort_month,
        COUNT(account_id) AS initial_size
    FROM analytics.accounts
    GROUP BY TO_CHAR(signup_date, 'YYYY-MM')
),
cohort_activity AS (
    SELECT 
        TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
        (EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM a.signup_date)) * 12 +
        (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM a.signup_date)) AS period_month,
        COUNT(DISTINCT a.account_id) AS active_logos
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    WHERE s.churn_flag = FALSE
    GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM'), period_month
)
SELECT 
    ca.cohort_month,
    ca.period_month,
    cs.initial_size AS cohort_start_size,
    ca.active_logos AS retained_logos,
    ROUND(ca.active_logos * 100.0 / cs.initial_size, 2) AS logo_retention_pct
FROM cohort_activity ca
INNER JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
WHERE ca.period_month BETWEEN 0 AND 12
ORDER BY ca.cohort_month ASC, ca.period_month ASC;
-- Expected Business Insight:
-- Generates logo retention percentages per cohort across relative months $M_0 \dots M_{12}$.


-- -----------------------------------------------------------------------------
-- Query 07
-- Business Question:
-- What is the cumulative count of lost customer logos per cohort at 30, 60, 90, 180, and 365 days post-signup?
--
-- Business Objective:
-- Identify early churn inflection windows across cohorts to trigger Customer Success playbooks.
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
    COUNT(a.account_id) AS total_cohort_size,
    SUM(CASE WHEN ce.churn_date <= a.signup_date + INTERVAL '30 days' THEN 1 ELSE 0 END) AS lost_within_30d,
    SUM(CASE WHEN ce.churn_date <= a.signup_date + INTERVAL '60 days' THEN 1 ELSE 0 END) AS lost_within_60d,
    SUM(CASE WHEN ce.churn_date <= a.signup_date + INTERVAL '90 days' THEN 1 ELSE 0 END) AS lost_within_90d,
    SUM(CASE WHEN ce.churn_date <= a.signup_date + INTERVAL '180 days' THEN 1 ELSE 0 END) AS lost_within_180d,
    SUM(CASE WHEN ce.churn_date <= a.signup_date + INTERVAL '365 days' THEN 1 ELSE 0 END) AS lost_within_365d
FROM analytics.accounts a
LEFT JOIN analytics.churn_events ce ON a.account_id = ce.account_id
GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
ORDER BY cohort_month ASC;
-- Expected Business Insight:
-- Quantifies early customer drop-off milestones (30d, 60d, 90d) per cohort.


-- -----------------------------------------------------------------------------
-- Query 08
-- Business Question:
-- What is the quarterly cohort logo retention curve across relative quarters (Q0, Q1, Q2, Q3, Q4)?
--
-- Business Objective:
-- Provide macro quarterly retention curves for executive leadership updates.
-- -----------------------------------------------------------------------------
WITH quarterly_cohort_sizes AS (
    SELECT 
        TO_CHAR(signup_date, 'YYYY"-Q"') || TO_CHAR(signup_date, 'Q') AS cohort_quarter,
        COUNT(account_id) AS initial_size
    FROM analytics.accounts
    GROUP BY TO_CHAR(signup_date, 'YYYY"-Q"') || TO_CHAR(signup_date, 'Q')
),
quarterly_activity AS (
    SELECT 
        TO_CHAR(a.signup_date, 'YYYY"-Q"') || TO_CHAR(signup_date, 'Q') AS cohort_quarter,
        FLOOR(((EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM a.signup_date)) * 12 +
               (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM a.signup_date))) / 3.0) AS period_quarter,
        COUNT(DISTINCT a.account_id) AS active_logos
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    WHERE s.churn_flag = FALSE
    GROUP BY TO_CHAR(a.signup_date, 'YYYY"-Q"') || TO_CHAR(signup_date, 'Q'), period_quarter
)
SELECT 
    qa.cohort_quarter,
    qa.period_quarter,
    qs.initial_size,
    qa.active_logos,
    ROUND(qa.active_logos * 100.0 / qs.initial_size, 2) AS quarterly_retention_pct
FROM quarterly_activity qa
INNER JOIN quarterly_cohort_sizes qs ON qa.cohort_quarter = qs.cohort_quarter
WHERE qa.period_quarter BETWEEN 0 AND 4
ORDER BY qa.cohort_quarter ASC, qa.period_quarter ASC;
-- Expected Business Insight:
-- Summarizes quarterly retention trends over relative quarters $Q_0 \dots Q_4$.


-- -----------------------------------------------------------------------------
-- Query 09
-- Business Question:
-- How does Month 12 logo retention compare between Enterprise cohorts and Basic plan cohorts?
--
-- Business Objective:
-- Validate hypothesis that Enterprise plan cohorts exhibit higher retention than Basic cohorts.
-- -----------------------------------------------------------------------------
WITH plan_cohort_sizes AS (
    SELECT 
        TO_CHAR(signup_date, 'YYYY-MM') AS cohort_month,
        plan_tier,
        COUNT(account_id) AS initial_size
    FROM analytics.accounts
    GROUP BY TO_CHAR(signup_date, 'YYYY-MM'), plan_tier
),
m12_retention AS (
    SELECT 
        TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
        a.plan_tier,
        COUNT(DISTINCT a.account_id) AS m12_retained_logos
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    WHERE s.churn_flag = FALSE
      AND ((EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM a.signup_date)) * 12 +
           (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM a.signup_date))) = 12
    GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM'), a.plan_tier
)
SELECT 
    pcs.cohort_month,
    pcs.plan_tier,
    pcs.initial_size,
    COALESCE(m12.m12_retained_logos, 0) AS m12_retained,
    ROUND(COALESCE(m12.m12_retained_logos, 0) * 100.0 / pcs.initial_size, 2) AS m12_retention_pct
FROM plan_cohort_sizes pcs
LEFT JOIN m12_retention m12 ON pcs.cohort_month = m12.cohort_month AND pcs.plan_tier = m12.plan_tier
ORDER BY pcs.cohort_month ASC, pcs.plan_tier;
-- Expected Business Insight:
-- Proves Enterprise plan cohorts achieve superior Month 12 logo retention percentages.


-- =============================================================================
-- SECTION 3: REVENUE BY COHORT
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 10
-- Business Question:
-- What is the initial starting Monthly Recurring Revenue (Month 0 MRR) generated by each monthly signup cohort?
--
-- Business Objective:
-- Measure new cohort revenue creation capacity per month.
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
    COUNT(DISTINCT a.account_id) AS total_acquired_customers,
    SUM(s.mrr_amount) AS initial_m0_mrr_usd,
    SUM(s.arr_amount) AS initial_m0_arr_usd,
    ROUND(SUM(s.mrr_amount) / COUNT(DISTINCT a.account_id), 2) AS initial_arpa_usd
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE (EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM a.signup_date)) * 12 +
      (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM a.signup_date)) = 0
GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
ORDER BY cohort_month ASC;
-- Expected Business Insight:
-- Tracks Month 0 starting MRR, ARR, and ARPA for new signup cohorts.


-- -----------------------------------------------------------------------------
-- Query 11
-- Business Question:
-- What is the Net Revenue Retention (NRR %) matrix across monthly cohorts for relative Month 0 through Month 12?
--
-- Business Objective:
-- Calculate the primary SaaS valuation metric: Net Revenue Retention (NRR > 100% indicates expansion).
-- -----------------------------------------------------------------------------
WITH initial_cohort_mrr AS (
    SELECT 
        TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
        SUM(s.mrr_amount) AS m0_starting_mrr
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    WHERE ((EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM a.signup_date)) * 12 +
           (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM a.signup_date))) = 0
    GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
),
monthly_retained_mrr AS (
    SELECT 
        TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
        (EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM a.signup_date)) * 12 +
        (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM a.signup_date)) AS period_month,
        SUM(s.mrr_amount) AS period_retained_mrr
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    WHERE s.churn_flag = FALSE
    GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM'), period_month
)
SELECT 
    mrm.cohort_month,
    mrm.period_month,
    icm.m0_starting_mrr,
    mrm.period_retained_mrr,
    ROUND(mrm.period_retained_mrr * 100.0 / NULLIF(icm.m0_starting_mrr, 0), 2) AS net_revenue_retention_nrr_pct
FROM monthly_retained_mrr mrm
INNER JOIN initial_cohort_mrr icm ON mrm.cohort_month = icm.cohort_month
WHERE mrm.period_month BETWEEN 0 AND 12
ORDER BY mrm.cohort_month ASC, mrm.period_month ASC;
-- Expected Business Insight:
-- Delivers the core Net Revenue Retention (NRR %) matrix across relative months $M_0 \dots M_{12}$.


-- -----------------------------------------------------------------------------
-- Query 12
-- Business Question:
-- What is the Gross Revenue Retention (GRR %) matrix excluding expansion revenue across monthly cohorts?
--
-- Business Objective:
-- Measure pure revenue retention capping values at 100% to evaluate underlying churn/contraction loss.
-- -----------------------------------------------------------------------------
WITH initial_cohort_mrr AS (
    SELECT 
        TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
        SUM(s.mrr_amount) AS m0_starting_mrr
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    WHERE ((EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM a.signup_date)) * 12 +
           (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM a.signup_date))) = 0
    GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
),
monthly_grr_mrr AS (
    SELECT 
        TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
        (EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM a.signup_date)) * 12 +
        (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM a.signup_date)) AS period_month,
        SUM(LEAST(s.mrr_amount, s_m0.mrr_amount)) AS period_grr_mrr
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    INNER JOIN analytics.subscriptions s_m0 ON a.account_id = s_m0.account_id 
           AND ((EXTRACT(YEAR FROM s_m0.start_date) - EXTRACT(YEAR FROM a.signup_date)) * 12 +
                (EXTRACT(MONTH FROM s_m0.start_date) - EXTRACT(MONTH FROM a.signup_date))) = 0
    WHERE s.churn_flag = FALSE
    GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM'), period_month
)
SELECT 
    mgr.cohort_month,
    mgr.period_month,
    icm.m0_starting_mrr,
    mgr.period_grr_mrr,
    LEAST(ROUND(mgr.period_grr_mrr * 100.0 / NULLIF(icm.m0_starting_mrr, 0), 2), 100.00) AS gross_revenue_retention_grr_pct
FROM monthly_grr_mrr mgr
INNER JOIN initial_cohort_mrr icm ON mgr.cohort_month = icm.cohort_month
WHERE mgr.period_month BETWEEN 0 AND 12
ORDER BY mgr.cohort_month ASC, mgr.period_month ASC;
-- Expected Business Insight:
-- Produces Gross Revenue Retention (GRR %) capped at 100% to evaluate underlying revenue stability.


-- -----------------------------------------------------------------------------
-- Query 13
-- Business Question:
-- How does cumulative cohort MRR expansion compare to cumulative cohort contraction over relative months?
--
-- Business Objective:
-- Measure net expansion velocity per cohort over time.
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
    SUM(CASE WHEN s.upgrade_flag = TRUE THEN s.mrr_amount ELSE 0 END) AS expansion_mrr_usd,
    SUM(CASE WHEN s.downgrade_flag = TRUE THEN s.mrr_amount ELSE 0 END) AS contraction_mrr_usd,
    SUM(CASE WHEN s.upgrade_flag = TRUE THEN s.mrr_amount ELSE 0 END) - 
    SUM(CASE WHEN s.downgrade_flag = TRUE THEN s.mrr_amount ELSE 0 END) AS net_expansion_mrr_usd
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
ORDER BY cohort_month ASC;
-- Expected Business Insight:
-- Compares total expansion upgrade dollars against contraction downgrade dollars by cohort.


-- -----------------------------------------------------------------------------
-- Query 14
-- Business Question:
-- What is the Average Revenue Per Account (ARPA) trajectory by cohort over relative month indexes?
--
-- Business Objective:
-- Monitor if surviving cohort accounts grow their spend over time (upsell trajectory).
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
    (EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM a.signup_date)) * 12 +
    (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM a.signup_date)) AS period_month,
    COUNT(DISTINCT a.account_id) AS active_accounts,
    SUM(s.mrr_amount) AS total_retained_mrr,
    ROUND(SUM(s.mrr_amount) / NULLIF(COUNT(DISTINCT a.account_id), 0), 2) AS cohort_arpa_usd
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.churn_flag = FALSE
GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM'), period_month
HAVING (EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM a.signup_date)) * 12 +
       (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM a.signup_date)) IN (0, 3, 6, 12)
ORDER BY cohort_month ASC, period_month ASC;
-- Expected Business Insight:
-- Shows ARPA growth from M0 to M12 as retained accounts upgrade.


-- =============================================================================
-- SECTION 4: CHURN BY COHORT
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 15
-- Business Question:
-- What is the cumulative 90-day churn rate percentage across monthly acquisition cohorts?
--
-- Business Objective:
-- Identify cohorts suffering from high early onboarding churn.
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
    COUNT(a.account_id) AS initial_cohort_size,
    COUNT(ce.churn_event_id) AS total_churned_accounts,
    SUM(CASE WHEN ce.churn_date <= a.signup_date + INTERVAL '90 days' THEN 1 ELSE 0 END) AS churned_within_90d,
    ROUND(
        SUM(CASE WHEN ce.churn_date <= a.signup_date + INTERVAL '90 days' THEN 1 ELSE 0 END) * 100.0 / 
        COUNT(a.account_id), 2
    ) AS churn_rate_90d_pct
FROM analytics.accounts a
LEFT JOIN analytics.churn_events ce ON a.account_id = ce.account_id
GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
ORDER BY churn_rate_90d_pct DESC;
-- Expected Business Insight:
-- Ranks monthly cohorts by 90-day onboarding churn vulnerability.


-- -----------------------------------------------------------------------------
-- Query 16
-- Business Question:
-- Which monthly signup cohorts suffered the highest total refund dollars issued upon cancellation?
--
-- Business Objective:
-- Analyze financial refund losses associated with specific customer cohorts.
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
    COUNT(DISTINCT a.account_id) AS cohort_size,
    COUNT(ce.churn_event_id) AS total_churned_accounts,
    COALESCE(SUM(ce.refund_amount_usd), 0.00) AS total_refunds_issued_usd,
    ROUND(COALESCE(SUM(ce.refund_amount_usd), 0.00) / COUNT(a.account_id), 2) AS avg_refund_per_cohort_account_usd
FROM analytics.accounts a
LEFT JOIN analytics.churn_events ce ON a.account_id = ce.account_id
GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
ORDER BY total_refunds_issued_usd DESC;
-- Expected Business Insight:
-- Pinpoints cohorts incurring heavy refund payouts during churn.


-- -----------------------------------------------------------------------------
-- Query 17
-- Business Question:
-- What is the average active customer lifespan (in months) per signup cohort prior to cancellation?
--
-- Business Objective:
-- Measure average customer lifetime duration before churn events occur.
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
    COUNT(ce.churn_event_id) AS total_churned_customers,
    ROUND(AVG((ce.churn_date - a.signup_date) / 30.44), 1) AS avg_customer_lifespan_months,
    MIN(ce.churn_date - a.signup_date) AS min_lifespan_days,
    MAX(ce.churn_date - a.signup_date) AS max_lifespan_days
FROM analytics.accounts a
INNER JOIN analytics.churn_events ce ON a.account_id = ce.account_id
GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
ORDER BY avg_customer_lifespan_months ASC;
-- Expected Business Insight:
-- Calculates average active tenure prior to cancellation across cohorts.


-- -----------------------------------------------------------------------------
-- Query 18
-- Business Question:
-- Which 3 monthly signup cohorts experienced the fastest early churn velocity (cancellations within 60 days)?
--
-- Business Objective:
-- Isolate cohorts impacted by flawed marketing acquisition or buggy product releases.
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
    COUNT(a.account_id) AS total_acquired,
    SUM(CASE WHEN ce.churn_date <= a.signup_date + INTERVAL '60 days' THEN 1 ELSE 0 END) AS early_churns_60d,
    ROUND(
        SUM(CASE WHEN ce.churn_date <= a.signup_date + INTERVAL '60 days' THEN 1 ELSE 0 END) * 100.0 / 
        COUNT(a.account_id), 2
    ) AS early_churn_rate_pct
FROM analytics.accounts a
LEFT JOIN analytics.churn_events ce ON a.account_id = ce.account_id
GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
ORDER BY early_churn_rate_pct DESC
LIMIT 3;
-- Expected Business Insight:
-- Isolates the 3 worst-performing cohorts suffering from rapid 60-day churn.


-- =============================================================================
-- SECTION 5: FEATURE ADOPTION BY COHORT
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 19
-- Business Question:
-- What is the average feature interaction volume per account across customer signup cohorts?
--
-- Business Objective:
-- Correlate initial feature usage intensity with long-term cohort retention.
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
    COUNT(DISTINCT a.account_id) AS total_cohort_accounts,
    COALESCE(SUM(fu.usage_count), 0) AS total_feature_clicks,
    ROUND(COALESCE(SUM(fu.usage_count), 0) * 1.0 / COUNT(DISTINCT a.account_id), 1) AS avg_clicks_per_account
FROM analytics.accounts a
LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id
LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
ORDER BY avg_clicks_per_account DESC;
-- Expected Business Insight:
-- Evaluates cohort product engagement density.


-- -----------------------------------------------------------------------------
-- Query 20
-- Business Question:
-- What percentage of customer accounts in each signup cohort adopted beta features within their first 90 days?
--
-- Business Objective:
-- Measure innovation and beta feature penetration across customer cohorts.
-- -----------------------------------------------------------------------------
WITH cohort_beta_adoption AS (
    SELECT DISTINCT
        a.account_id,
        TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    INNER JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    WHERE fu.is_beta_feature = TRUE
      AND fu.usage_date <= a.signup_date + INTERVAL '90 days'
)
SELECT 
    TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
    COUNT(a.account_id) AS total_cohort_accounts,
    COUNT(cba.account_id) AS beta_adopting_accounts,
    ROUND(COUNT(cba.account_id) * 100.0 / COUNT(a.account_id), 2) AS beta_adoption_rate_pct
FROM analytics.accounts a
LEFT JOIN cohort_beta_adoption cba ON a.account_id = cba.account_id
GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
ORDER BY cohort_month ASC;
-- Expected Business Insight:
-- Measures early beta feature adoption rates across cohorts.


-- -----------------------------------------------------------------------------
-- Query 21
-- Business Question:
-- Which monthly signup cohorts produced the highest density of power-user accounts (>1,000 usage events)?
--
-- Business Objective:
-- Identify cohorts that generated highly engaged long-term customer accounts.
-- -----------------------------------------------------------------------------
WITH power_user_accounts AS (
    SELECT 
        s.account_id,
        SUM(fu.usage_count) AS total_clicks
    FROM analytics.subscriptions s
    INNER JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY s.account_id
    HAVING SUM(fu.usage_count) >= 1000
)
SELECT 
    TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
    COUNT(a.account_id) AS total_cohort_size,
    COUNT(pua.account_id) AS power_user_count,
    ROUND(COUNT(pua.account_id) * 100.0 / COUNT(a.account_id), 2) AS power_user_density_pct
FROM analytics.accounts a
LEFT JOIN power_user_accounts pua ON a.account_id = pua.account_id
GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
ORDER BY power_user_density_pct DESC;
-- Expected Business Insight:
-- Ranks cohorts by power-user concentration percentage.


-- =============================================================================
-- SECTION 6: SUPPORT BEHAVIOUR BY COHORT
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 22
-- Business Question:
-- What is the average support ticket volume submitted per customer account across signup cohorts?
--
-- Business Objective:
-- Assess customer support load generated per cohort.
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
    COUNT(DISTINCT a.account_id) AS total_cohort_accounts,
    COUNT(st.ticket_id) AS total_support_tickets,
    ROUND(COUNT(st.ticket_id) * 1.0 / COUNT(DISTINCT a.account_id), 2) AS avg_tickets_per_account
FROM analytics.accounts a
LEFT JOIN analytics.support_tickets st ON a.account_id = st.account_id
GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
ORDER BY avg_tickets_per_account DESC;
-- Expected Business Insight:
-- Identifies high-friction cohorts requiring excessive support ticket intervention.


-- -----------------------------------------------------------------------------
-- Query 23
-- Business Question:
-- What is the average SLA resolution time (in hours) experienced by each customer signup cohort?
--
-- Business Objective:
-- Audit support team SLA fulfillment consistency across customer cohorts.
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
    COUNT(st.ticket_id) AS total_tickets,
    ROUND(AVG(st.resolution_time_hours), 1) AS avg_resolution_time_hours,
    ROUND(AVG(st.first_response_time_minutes), 1) AS avg_first_response_mins
FROM analytics.accounts a
INNER JOIN analytics.support_tickets st ON a.account_id = st.account_id
GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
ORDER BY cohort_month ASC;
-- Expected Business Insight:
-- Evaluates resolution speed and first response SLAs experienced by cohorts.


-- -----------------------------------------------------------------------------
-- Query 24
-- Business Question:
-- What is the average Customer Satisfaction Score (CSAT) score across customer signup cohorts?
--
-- Business Objective:
-- Track customer sentiment trends by acquisition cohort.
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
    COUNT(st.satisfaction_score) AS rated_tickets_count,
    ROUND(AVG(st.satisfaction_score), 2) AS avg_cohort_csat_score
FROM analytics.accounts a
INNER JOIN analytics.support_tickets st ON a.account_id = st.account_id
WHERE st.satisfaction_score IS NOT NULL
GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
ORDER BY avg_cohort_csat_score DESC;
-- Expected Business Insight:
-- Measures customer satisfaction scores across acquisition cohorts.


-- -----------------------------------------------------------------------------
-- Query 25
-- Business Question:
-- Which customer signup cohorts triggered the highest support ticket escalation rate percentage?
--
-- Business Objective:
-- Identify cohorts encountering severe product bugs or complex setup hurdles.
-- -----------------------------------------------------------------------------
SELECT 
    TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
    COUNT(st.ticket_id) AS total_tickets,
    SUM(CASE WHEN st.escalation_flag = TRUE THEN 1 ELSE 0 END) AS escalated_tickets,
    ROUND(
        SUM(CASE WHEN st.escalation_flag = TRUE THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(COUNT(st.ticket_id), 0), 2
    ) AS escalation_rate_pct
FROM analytics.accounts a
INNER JOIN analytics.support_tickets st ON a.account_id = st.account_id
GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
ORDER BY escalation_rate_pct DESC;
-- Expected Business Insight:
-- Highlights cohorts suffering from high engineering escalation rates.


-- =============================================================================
-- SECTION 7: EXECUTIVE COHORT KPIS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 26
-- Business Question:
-- What are the top 3 highest Net Revenue Retention (NRR %) cohorts at Month 12?
--
-- Business Objective:
-- Identify best-in-class historical cohorts to replicate acquisition strategies.
-- -----------------------------------------------------------------------------
WITH m0_mrr AS (
    SELECT 
        TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
        SUM(s.mrr_amount) AS m0_mrr
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    WHERE ((EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM a.signup_date)) * 12 +
           (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM a.signup_date))) = 0
    GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
),
m12_mrr AS (
    SELECT 
        TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
        SUM(s.mrr_amount) AS m12_mrr
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    WHERE s.churn_flag = FALSE
      AND ((EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM a.signup_date)) * 12 +
           (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM a.signup_date))) = 12
    GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
)
SELECT 
    m0.cohort_month,
    m0.m0_mrr AS initial_mrr,
    COALESCE(m12.m12_mrr, 0.00) AS retained_m12_mrr,
    ROUND(COALESCE(m12.m12_mrr, 0.00) * 100.0 / NULLIF(m0.m0_mrr, 0), 2) AS m12_nrr_pct
FROM m0_mrr m0
LEFT JOIN m12_mrr m12 ON m0.cohort_month = m12.cohort_month
ORDER BY m12_nrr_pct DESC
LIMIT 3;
-- Expected Business Insight:
-- Identifies top 3 highest NRR cohorts at Month 12 benchmark.


-- -----------------------------------------------------------------------------
-- Query 27
-- Business Question:
-- Comprehensive Executive Cohort Master Table: Monthly cohort signup count, Month 0 MRR, Month 12 retained MRR, Month 12 NRR %, and Month 12 Logo Retention %?
--
-- Business Objective:
-- Generate master summary view for executive dashboard and investor pitch decks.
-- -----------------------------------------------------------------------------
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
        SUM(s.mrr_amount) AS starting_mrr
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
        SUM(s.mrr_amount) AS m12_mrr
    FROM analytics.accounts a
    INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
    WHERE s.churn_flag = FALSE
      AND ((EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM a.signup_date)) * 12 +
           (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM a.signup_date))) = 12
    GROUP BY TO_CHAR(a.signup_date, 'YYYY-MM')
)
SELECT 
    cb.cohort_month,
    cb.initial_logos,
    COALESCE(m12.m12_logos, 0) AS m12_retained_logos,
    ROUND(COALESCE(m12.m12_logos, 0) * 100.0 / cb.initial_logos, 2) AS m12_logo_retention_pct,
    COALESCE(m0.starting_mrr, 0.00) AS m0_starting_mrr,
    COALESCE(m12.m12_mrr, 0.00) AS m12_retained_mrr,
    ROUND(COALESCE(m12.m12_mrr, 0.00) * 100.0 / NULLIF(m0.starting_mrr, 0), 2) AS m12_nrr_pct
FROM cohort_base cb
LEFT JOIN m0_revenue m0 ON cb.cohort_month = m0.cohort_month
LEFT JOIN m12_metrics m12 ON cb.cohort_month = m12.cohort_month
ORDER BY cb.cohort_month ASC;
-- Expected Business Insight:
-- Delivers complete executive cohort scorecard summarizing Month 0 to Month 12 retention performance.
