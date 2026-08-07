-- =============================================================================
-- Project:         B2B SaaS Customer Cohort & Retention Analytics Platform
-- File:            sql/03_intermediate_analysis.sql
-- Role:            Principal Data Analyst / Senior Analytics Engineer
-- Target Engine:   PostgreSQL 13+
-- Purpose:         Intermediate SQL business analytics suite demonstrating CTEs,
--                  correlated subqueries, EXISTS/NOT EXISTS, conditional aggregations,
--                  and multi-table join patterns across SaaS operational domains.
-- =============================================================================

SET search_path TO analytics, public;


-- =============================================================================
-- SECTION 1: CUSTOMER SEGMENTATION
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 01
-- Business Question:
-- Which customer accounts generate Monthly Recurring Revenue (MRR) above the overall company average MRR?
--
-- Business Objective:
-- Identify high-value customer accounts to target for premium retention and executive advocacy programs.
-- -----------------------------------------------------------------------------
WITH company_avg_mrr AS (
    SELECT AVG(mrr_amount) AS avg_mrr
    FROM analytics.subscriptions
    WHERE churn_flag = FALSE
)
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    SUM(s.mrr_amount) AS total_account_mrr
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.churn_flag = FALSE
GROUP BY a.account_id, a.account_name, a.industry, a.plan_tier
HAVING SUM(s.mrr_amount) > (SELECT avg_mrr FROM company_avg_mrr)
ORDER BY total_account_mrr DESC;
-- Expected Business Insight:
-- Pinpoints top-tier accounts contributing revenue significantly higher than the baseline average.


-- -----------------------------------------------------------------------------
-- Query 02
-- Business Question:
-- Which industries have an Average Revenue Per User (ARPU) higher than the overall company ARPU?
--
-- Business Objective:
-- Evaluate market segment performance to prioritize sales team expansion efforts toward lucrative verticals.
-- -----------------------------------------------------------------------------
WITH overall_arpu AS (
    SELECT SUM(mrr_amount) / COUNT(DISTINCT account_id) AS benchmark_arpu
    FROM analytics.subscriptions
    WHERE churn_flag = FALSE
)
SELECT 
    a.industry,
    COUNT(DISTINCT a.account_id) AS active_accounts,
    SUM(s.mrr_amount) AS total_industry_mrr,
    ROUND(SUM(s.mrr_amount) / COUNT(DISTINCT a.account_id), 2) AS industry_arpu
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.churn_flag = FALSE
GROUP BY a.industry
HAVING (SUM(s.mrr_amount) / COUNT(DISTINCT a.account_id)) > (SELECT benchmark_arpu FROM overall_arpu)
ORDER BY industry_arpu DESC;
-- Expected Business Insight:
-- Ranks outperforming industry verticals generating premium average customer yields.


-- -----------------------------------------------------------------------------
-- Query 03
-- Business Question:
-- Which customer accounts hold more than one subscription contract?
--
-- Business Objective:
-- Identify multi-product or multi-department accounts for cross-selling and consolidation analysis.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    COUNT(s.subscription_id) AS total_subscriptions_count,
    SUM(s.mrr_amount) AS cumulative_mrr
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
GROUP BY a.account_id, a.account_name, a.industry, a.plan_tier
HAVING COUNT(s.subscription_id) > 1
ORDER BY total_subscriptions_count DESC, cumulative_mrr DESC;
-- Expected Business Insight:
-- Highlights accounts with multi-contract footprint requiring master service agreement (MSA) consolidation.


-- -----------------------------------------------------------------------------
-- Query 04
-- Business Question:
-- Who are the Enterprise plan customers with seat allocations exceeding the overall average seat count?
--
-- Business Objective:
-- Identify mega-enterprise deployment accounts for dedicated Customer Success Manager (CSM) coverage.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.seats,
    a.signup_date
FROM analytics.accounts a
WHERE LOWER(a.plan_tier) = 'enterprise'
  AND a.seats > (
      SELECT AVG(seats) 
      FROM analytics.accounts 
      WHERE LOWER(plan_tier) = 'enterprise'
  )
ORDER BY a.seats DESC;
-- Expected Business Insight:
-- Filters heavy enterprise deployments operating above average license scale.


-- -----------------------------------------------------------------------------
-- Query 05
-- Business Question:
-- Which active customer accounts have never submitted a support ticket?
--
-- Business Objective:
-- Spot silent accounts that may suffer from low product adoption or unexpressed churn risk.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    a.signup_date
FROM analytics.accounts a
WHERE a.churn_flag = FALSE
  AND NOT EXISTS (
      SELECT 1 
      FROM analytics.support_tickets st 
      WHERE st.account_id = a.account_id
  )
ORDER BY a.signup_date ASC;
-- Expected Business Insight:
-- Lists quiet accounts requiring proactive Customer Success health check-ins.


-- -----------------------------------------------------------------------------
-- Query 06
-- Business Question:
-- Which customers have submitted support tickets but have never churned?
--
-- Business Objective:
-- Analyze engaged accounts utilizing support channels effectively while remaining loyal subscribers.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    COUNT(st.ticket_id) AS total_support_tickets,
    ROUND(AVG(st.satisfaction_score), 2) AS avg_csat
FROM analytics.accounts a
INNER JOIN analytics.support_tickets st ON a.account_id = st.account_id
WHERE a.churn_flag = FALSE
  AND NOT EXISTS (
      SELECT 1 
      FROM analytics.churn_events ce 
      WHERE ce.account_id = a.account_id
  )
GROUP BY a.account_id, a.account_name, a.industry, a.plan_tier
HAVING COUNT(st.ticket_id) >= 2
ORDER BY total_support_tickets DESC;
-- Expected Business Insight:
-- Demonstrates that active support interaction correlates with account retention when CSAT is maintained.


-- =============================================================================
-- SECTION 2: SUBSCRIPTION INTELLIGENCE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 07
-- Business Question:
-- Which accounts successfully upgraded to a paid subscription contract after starting on a free trial?
--
-- Business Objective:
-- Measure product-led growth (PLG) free trial conversion efficiency and revenue expansion.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    s.subscription_id,
    s.plan_tier,
    s.mrr_amount,
    s.start_date
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE a.is_trial = FALSE 
  AND s.is_trial = FALSE
  AND EXISTS (
      SELECT 1 
      FROM analytics.subscriptions s_sub 
      WHERE s_sub.account_id = a.account_id 
        AND s_sub.is_trial = TRUE
  )
ORDER BY s.start_date DESC;
-- Expected Business Insight:
-- Identifies accounts that successfully completed trial conversion into recurring revenue contracts.


-- -----------------------------------------------------------------------------
-- Query 08
-- Business Question:
-- Which customer accounts experienced a subscription downgrade contract event?
--
-- Business Objective:
-- Detect contraction MRR trends to intervene before accounts progress to complete churn.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    s.subscription_id,
    s.plan_tier,
    s.mrr_amount,
    s.start_date
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.downgrade_flag = TRUE
ORDER BY s.start_date DESC;
-- Expected Business Insight:
-- Highlights contraction contracts for Account Executive save review.


-- -----------------------------------------------------------------------------
-- Query 09
-- Business Question:
-- What are the top 10 longest running active subscription contracts currently active?
--
-- Business Objective:
-- Identify anchor customer contracts for strategic case studies and testimonial requests.
-- -----------------------------------------------------------------------------
SELECT 
    s.subscription_id,
    a.account_name,
    a.industry,
    s.plan_tier,
    s.start_date,
    (CURRENT_DATE - s.start_date) AS active_tenure_days,
    ROUND((CURRENT_DATE - s.start_date) / 30.44, 1) AS active_tenure_months,
    s.mrr_amount
FROM analytics.subscriptions s
INNER JOIN analytics.accounts a ON s.account_id = a.account_id
WHERE s.churn_flag = FALSE 
  AND (s.end_date IS NULL OR s.end_date >= CURRENT_DATE)
ORDER BY active_tenure_days DESC
LIMIT 10;
-- Expected Business Insight:
-- Pinpoints loyal customer contracts with long tenure and strong retention stability.


-- -----------------------------------------------------------------------------
-- Query 10
-- Business Question:
-- Which customer accounts currently maintain multiple active subscriptions simultaneously?
--
-- Business Objective:
-- Uncover complex accounts running parallel product lines or multiple regional teams.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    COUNT(s.subscription_id) AS active_contract_count,
    SUM(s.mrr_amount) AS total_active_mrr
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.churn_flag = FALSE 
  AND (s.end_date IS NULL OR s.end_date >= CURRENT_DATE)
GROUP BY a.account_id, a.account_name
HAVING COUNT(s.subscription_id) > 1
ORDER BY active_contract_count DESC;
-- Expected Business Insight:
-- Identifies accounts with multi-subscription footprints for unified contract negotiations.


-- -----------------------------------------------------------------------------
-- Query 11
-- Business Question:
-- Which Monthly billing customers generate revenue equal to or greater than the Enterprise plan threshold ($1,000+ MRR)?
--
-- Business Objective:
-- Identify candidates on monthly billing for annual contract conversion incentives.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    s.subscription_id,
    s.billing_frequency,
    s.mrr_amount,
    s.arr_amount
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE LOWER(s.billing_frequency) = 'monthly'
  AND s.mrr_amount >= 1000.00
  AND s.churn_flag = FALSE
ORDER BY s.mrr_amount DESC;
-- Expected Business Insight:
-- Targets high-spending monthly accounts to convert to annual billing for cash predictability.


-- -----------------------------------------------------------------------------
-- Query 12
-- Business Question:
-- Which Annual billing customers generate lower Monthly Recurring Revenue than the company average monthly contract MRR?
--
-- Business Objective:
-- Detect under-monetized annual contracts for tier upgrade campaign targeting.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    s.plan_tier,
    s.mrr_amount,
    s.arr_amount
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE LOWER(s.billing_frequency) = 'annual'
  AND s.mrr_amount < (
      SELECT AVG(mrr_amount) 
      FROM analytics.subscriptions 
      WHERE churn_flag = FALSE
  )
  AND s.churn_flag = FALSE
ORDER BY s.mrr_amount ASC;
-- Expected Business Insight:
-- Identifies low-spending annual subscribers suitable for cross-selling add-on licenses.


-- =============================================================================
-- SECTION 3: REVENUE INTELLIGENCE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 13
-- Business Question:
-- Which customer accounts generate MRR higher than their specific industry segment average MRR?
--
-- Business Objective:
-- Benchmark customer accounts against industry peer averages to identify outperforming accounts.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    s.mrr_amount,
    ROUND(ind_avg.avg_industry_mrr, 2) AS industry_benchmark_mrr
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
INNER JOIN (
    SELECT a_sub.industry, AVG(s_sub.mrr_amount) AS avg_industry_mrr
    FROM analytics.accounts a_sub
    INNER JOIN analytics.subscriptions s_sub ON a_sub.account_id = s_sub.account_id
    WHERE s_sub.churn_flag = FALSE
    GROUP BY a_sub.industry
) ind_avg ON a.industry = ind_avg.industry
WHERE s.mrr_amount > ind_avg.avg_industry_mrr
  AND s.churn_flag = FALSE
ORDER BY a.industry, s.mrr_amount DESC;
-- Expected Business Insight:
-- Highlights vertical market leaders exceeding peer industry average spend.


-- -----------------------------------------------------------------------------
-- Query 14
-- Business Question:
-- Which customer accounts generate MRR higher than their country's average account MRR?
--
-- Business Objective:
-- Perform regional pricing parity analysis to adjust local sales expansion strategies.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.country,
    s.mrr_amount,
    ROUND(ctry_avg.avg_country_mrr, 2) AS country_benchmark_mrr
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
INNER JOIN (
    SELECT a_sub.country, AVG(s_sub.mrr_amount) AS avg_country_mrr
    FROM analytics.accounts a_sub
    INNER JOIN analytics.subscriptions s_sub ON a_sub.account_id = s_sub.account_id
    WHERE s_sub.churn_flag = FALSE
    GROUP BY a_sub.country
) ctry_avg ON a.country = ctry_avg.country
WHERE s.mrr_amount > ctry_avg.avg_country_mrr
  AND s.churn_flag = FALSE
ORDER BY a.country, s.mrr_amount DESC;
-- Expected Business Insight:
-- Reveals geographically dominant accounts operating above national baseline spend.


-- -----------------------------------------------------------------------------
-- Query 15
-- Business Question:
-- Which industry verticals contribute more than 10% of total company Monthly Recurring Revenue?
--
-- Business Objective:
-- Identify strategic core industry pillars driving overall company revenue.
-- -----------------------------------------------------------------------------
WITH total_company_mrr AS (
    SELECT SUM(mrr_amount) AS grand_total_mrr
    FROM analytics.subscriptions
    WHERE churn_flag = FALSE
)
SELECT 
    a.industry,
    COUNT(DISTINCT a.account_id) AS account_count,
    SUM(s.mrr_amount) AS industry_mrr,
    ROUND(SUM(s.mrr_amount) * 100.0 / (SELECT grand_total_mrr FROM total_company_mrr), 2) AS revenue_contribution_pct
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.churn_flag = FALSE
GROUP BY a.industry
HAVING SUM(s.mrr_amount) * 100.0 / (SELECT grand_total_mrr FROM total_company_mrr) > 10.0
ORDER BY industry_mrr DESC;
-- Expected Business Insight:
-- Pinpoints core revenue-generating verticals contributing >10% of company MRR.


-- -----------------------------------------------------------------------------
-- Query 16
-- Business Question:
-- Which high-value customer accounts contribute to the top 25th percentile of overall company MRR?
--
-- Business Objective:
-- Protect key accounts against competitive poaching and executive turnover risk.
-- -----------------------------------------------------------------------------
WITH revenue_threshold AS (
    SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY mrr_amount) AS p75_mrr
    FROM analytics.subscriptions
    WHERE churn_flag = FALSE
)
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    s.mrr_amount
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.churn_flag = FALSE
  AND s.mrr_amount >= (SELECT p75_mrr FROM revenue_threshold)
ORDER BY s.mrr_amount DESC;
-- Expected Business Insight:
-- Filters top 25% revenue-generating customer accounts for VIP executive sponsorship.


-- -----------------------------------------------------------------------------
-- Query 17
-- Business Question:
-- Which active customer accounts currently generate zero ARR (e.g. active trial or free tier accounts)?
--
-- Business Objective:
-- Focus Inside Sales team outreach on converting active zero-revenue accounts into paid subscribers.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.signup_date,
    s.subscription_id,
    s.plan_tier
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.churn_flag = FALSE 
  AND (s.arr_amount = 0 OR s.mrr_amount = 0)
ORDER BY a.signup_date ASC;
-- Expected Business Insight:
-- Lists non-monetized active users available for sales conversion campaigns.


-- -----------------------------------------------------------------------------
-- Query 18
-- Business Question:
-- Which customer accounts have received total refund amounts above the company-wide average refund?
--
-- Business Objective:
-- Investigate product flaws or service breakdowns leading to abnormal refund payouts.
-- -----------------------------------------------------------------------------
WITH avg_refund AS (
    SELECT AVG(refund_amount_usd) AS overall_avg_refund
    FROM analytics.churn_events
    WHERE refund_amount_usd > 0
)
SELECT 
    ce.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    ce.reason_code,
    SUM(ce.refund_amount_usd) AS total_refund_issued
FROM analytics.churn_events ce
INNER JOIN analytics.accounts a ON ce.account_id = a.account_id
GROUP BY ce.account_id, a.account_name, a.industry, a.plan_tier, ce.reason_code
HAVING SUM(ce.refund_amount_usd) > (SELECT overall_avg_refund FROM avg_refund)
ORDER BY total_refund_issued DESC;
-- Expected Business Insight:
-- Highlights high-refund cancellation events to uncover systemic billing or product issues.


-- =============================================================================
-- SECTION 4: MARKETING INTELLIGENCE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 19
-- Business Question:
-- Which marketing campaigns successfully acquired high-value enterprise customers ($2,000+ MRR)?
--
-- Business Objective:
-- Identify marketing programs producing enterprise-grade deals to reallocate ad spend.
-- -----------------------------------------------------------------------------
SELECT 
    mc.campaign_id,
    mc.campaign_name,
    mc.channel,
    mc.campaign_type,
    COUNT(DISTINCT a.account_id) AS enterprise_accounts_acquired,
    SUM(s.mrr_amount) AS total_mrr_acquired
FROM analytics.marketing_campaigns mc
INNER JOIN analytics.accounts a ON mc.campaign_id = a.campaign_id
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.mrr_amount >= 2000.00 AND s.churn_flag = FALSE
GROUP BY mc.campaign_id, mc.campaign_name, mc.channel, mc.campaign_type
ORDER BY total_mrr_acquired DESC;
-- Expected Business Insight:
-- Evaluates marketing campaign effectiveness in driving high-value customer acquisition.


-- -----------------------------------------------------------------------------
-- Query 20
-- Business Question:
-- Which marketing channels achieved a campaign conversion rate higher than the overall average conversion rate?
--
-- Business Objective:
-- Reallocate acquisition capital to high-converting marketing channels.
-- -----------------------------------------------------------------------------
WITH overall_conversion_rate AS (
    SELECT SUM(conversions) * 100.0 / NULLIF(SUM(clicks), 0) AS benchmark_cr
    FROM analytics.marketing_campaigns
)
SELECT 
    channel,
    SUM(clicks) AS total_clicks,
    SUM(conversions) AS total_conversions,
    ROUND(SUM(conversions) * 100.0 / NULLIF(SUM(clicks), 0), 2) AS channel_conversion_rate_pct
FROM analytics.marketing_campaigns
GROUP BY channel
HAVING (SUM(conversions) * 100.0 / NULLIF(SUM(clicks), 0)) > (SELECT benchmark_cr FROM overall_conversion_rate)
ORDER BY channel_conversion_rate_pct DESC;
-- Expected Business Insight:
-- Highlights top-converting acquisition channels outperforming company benchmarks.


-- -----------------------------------------------------------------------------
-- Query 21
-- Business Question:
-- Which specific marketing campaigns converted accounts directly into Enterprise plan tiers?
--
-- Business Objective:
-- Optimize ad messaging and targeting strategies tailored to enterprise buyer personas.
-- -----------------------------------------------------------------------------
SELECT 
    mc.campaign_id,
    mc.campaign_name,
    mc.channel,
    COUNT(a.account_id) AS enterprise_signups_count
FROM analytics.marketing_campaigns mc
INNER JOIN analytics.accounts a ON mc.campaign_id = a.campaign_id
WHERE LOWER(a.plan_tier) = 'enterprise'
GROUP BY mc.campaign_id, mc.campaign_name, mc.channel
ORDER BY enterprise_signups_count DESC;
-- Expected Business Insight:
-- Links marketing campaigns directly to Enterprise account acquisition success.


-- -----------------------------------------------------------------------------
-- Query 22
-- Business Question:
-- Which marketing campaigns spent budget but resulted in zero customer acquisitions?
--
-- Business Objective:
-- Terminate underperforming ad campaigns and prevent budget waste.
-- -----------------------------------------------------------------------------
SELECT 
    mc.campaign_id,
    mc.campaign_name,
    mc.channel,
    mc.budget_usd,
    mc.impressions,
    mc.clicks
FROM analytics.marketing_campaigns mc
WHERE mc.budget_usd > 0
  AND NOT EXISTS (
      SELECT 1 
      FROM analytics.accounts a 
      WHERE a.campaign_id = mc.campaign_id
  )
ORDER BY mc.budget_usd DESC;
-- Expected Business Insight:
-- Flags zero-yield marketing spend for immediate campaign cancellation.


-- -----------------------------------------------------------------------------
-- Query 23
-- Business Question:
-- What is the Return on Marketing Investment (ROMI) expressed as MRR generated per dollar of campaign budget spent by channel?
--
-- Business Objective:
-- Measure financial ROI by channel to optimize marketing capital allocation.
-- -----------------------------------------------------------------------------
SELECT 
    mc.channel,
    SUM(mc.budget_usd) AS total_budget_spent_usd,
    COALESCE(SUM(s.mrr_amount), 0.00) AS total_mrr_acquired_usd,
    ROUND(COALESCE(SUM(s.mrr_amount), 0.00) / NULLIF(SUM(mc.budget_usd), 0), 2) AS mrr_yield_per_budget_dollar
FROM analytics.marketing_campaigns mc
LEFT JOIN analytics.accounts a ON mc.campaign_id = a.campaign_id
LEFT JOIN analytics.subscriptions s ON a.account_id = s.account_id AND s.churn_flag = FALSE
GROUP BY mc.channel
ORDER BY mrr_yield_per_budget_dollar DESC;
-- Expected Business Insight:
-- Ranks marketing channels by MRR yield generated per dollar of marketing budget.


-- -----------------------------------------------------------------------------
-- Query 24
-- Business Question:
-- Which customer accounts were acquired organically or via referral channels but generate top-tier revenue ($1,500+ MRR)?
--
-- Business Objective:
-- Identify highly profitable organic and referral customers with zero paid CAC.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.referral_source,
    a.industry,
    s.mrr_amount
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.mrr_amount >= 1500.00 
  AND s.churn_flag = FALSE
  AND LOWER(a.referral_source) IN ('partner', 'organic', 'referral', 'direct')
ORDER BY s.mrr_amount DESC;
-- Expected Business Insight:
-- Highlights zero-CAC high-margin revenue accounts acquired via organic referrals.


-- =============================================================================
-- SECTION 5: SUPPORT INTELLIGENCE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 25
-- Business Question:
-- Which customer accounts have submitted a support ticket volume higher than the overall account average?
--
-- Business Objective:
-- Identify high-touch accounts experiencing frequent operational issues.
-- -----------------------------------------------------------------------------
WITH avg_tickets_per_account AS (
    SELECT COUNT(ticket_id) * 1.0 / COUNT(DISTINCT account_id) AS benchmark_tickets
    FROM analytics.support_tickets
)
SELECT 
    a.account_id,
    a.account_name,
    a.plan_tier,
    COUNT(st.ticket_id) AS ticket_count
FROM analytics.accounts a
INNER JOIN analytics.support_tickets st ON a.account_id = st.account_id
GROUP BY a.account_id, a.account_name, a.plan_tier
HAVING COUNT(st.ticket_id) > (SELECT benchmark_tickets FROM avg_tickets_per_account)
ORDER BY ticket_count DESC;
-- Expected Business Insight:
-- Flags accounts exceeding support baseline for dedicated Customer Success intervention.


-- -----------------------------------------------------------------------------
-- Query 26
-- Business Question:
-- Which customer accounts maintain high satisfaction scores (CSAT >= 4.5) despite experiencing SLA resolution times under 12 hours?
--
-- Business Objective:
-- Recognize high-performing Customer Support teams and successful SLA resolution dynamics.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    COUNT(st.ticket_id) AS total_tickets,
    ROUND(AVG(st.resolution_time_hours), 1) AS avg_resolution_hours,
    ROUND(AVG(st.satisfaction_score), 2) AS avg_csat
FROM analytics.accounts a
INNER JOIN analytics.support_tickets st ON a.account_id = st.account_id
WHERE st.satisfaction_score IS NOT NULL
GROUP BY a.account_id, a.account_name, a.industry
HAVING AVG(st.satisfaction_score) >= 4.5 
   AND AVG(st.resolution_time_hours) < 12.0
ORDER BY avg_csat DESC, total_tickets DESC;
-- Expected Business Insight:
-- Identifies accounts receiving rapid resolution and rating CSAT near perfect 5.0.


-- -----------------------------------------------------------------------------
-- Query 27
-- Business Question:
-- Which customer accounts have experienced multiple support ticket escalations?
--
-- Business Objective:
-- Spot accounts suffering from complex technical product defects requiring engineering fixes.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.plan_tier,
    COUNT(st.ticket_id) AS total_escalated_tickets,
    ROUND(AVG(st.resolution_time_hours), 1) AS avg_escalated_resolution_hours
FROM analytics.accounts a
INNER JOIN analytics.support_tickets st ON a.account_id = st.account_id
WHERE st.escalation_flag = TRUE
GROUP BY a.account_id, a.account_name, a.plan_tier
HAVING COUNT(st.ticket_id) >= 2
ORDER BY total_escalated_tickets DESC;
-- Expected Business Insight:
-- Highlights recurring technical escalation pain-points impacting key accounts.


-- -----------------------------------------------------------------------------
-- Query 28
-- Business Question:
-- Which industry verticals generate an excessive support ticket volume relative to their account population?
--
-- Business Objective:
-- Identify vertical-specific product UX or compliance hurdles requiring specialized support documentation.
-- -----------------------------------------------------------------------------
SELECT 
    a.industry,
    COUNT(DISTINCT a.account_id) AS total_accounts,
    COUNT(st.ticket_id) AS total_support_tickets,
    ROUND(COUNT(st.ticket_id) * 1.0 / COUNT(DISTINCT a.account_id), 2) AS tickets_per_account_ratio
FROM analytics.accounts a
LEFT JOIN analytics.support_tickets st ON a.account_id = st.account_id
GROUP BY a.industry
ORDER BY tickets_per_account_ratio DESC;
-- Expected Business Insight:
-- Pinpoints industries with high support load per account (e.g., FinTech compliance queries).


-- -----------------------------------------------------------------------------
-- Query 29
-- Business Question:
-- Which support tickets remained unresolved beyond the 48-hour critical business SLA threshold?
--
-- Business Objective:
-- Audit SLA breaches to improve support team scheduling and escalation protocols.
-- -----------------------------------------------------------------------------
SELECT 
    st.ticket_id,
    a.account_name,
    a.plan_tier,
    st.priority,
    st.submitted_at,
    st.closed_at,
    st.resolution_time_hours
FROM analytics.support_tickets st
INNER JOIN analytics.accounts a ON st.account_id = a.account_id
WHERE st.resolution_time_hours > 48.0
ORDER BY st.resolution_time_hours DESC;
-- Expected Business Insight:
-- Details critical support SLA breaches (>48 hours) for operations review.


-- =============================================================================
-- SECTION 6: PRODUCT INTELLIGENCE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 30
-- Business Question:
-- Which platform features experience total interaction counts above the average feature usage volume?
--
-- Business Objective:
-- Identify core value-driver features to prioritize for product engineering roadmap investments.
-- -----------------------------------------------------------------------------
WITH feature_avg_usage AS (
    SELECT AVG(total_clicks) AS benchmark_usage
    FROM (
        SELECT feature_name, SUM(usage_count) AS total_clicks
        FROM analytics.feature_usage
        GROUP BY feature_name
    ) sub
)
SELECT 
    fu.feature_name,
    COUNT(DISTINCT fu.subscription_id) AS active_subscriptions_using,
    SUM(fu.usage_count) AS total_usage_events,
    ROUND(SUM(fu.usage_duration_secs) / 3600.0, 1) AS total_usage_hours
FROM analytics.feature_usage fu
GROUP BY fu.feature_name
HAVING SUM(fu.usage_count) > (SELECT benchmark_usage FROM feature_avg_usage)
ORDER BY total_usage_events DESC;
-- Expected Business Insight:
-- Isolates top tier heavily adopted platform features.


-- -----------------------------------------------------------------------------
-- Query 31
-- Business Question:
-- Which active customer accounts actively engage with beta features on the platform?
--
-- Business Objective:
-- Identify product innovator accounts suitable for early-access beta testing programs.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    COUNT(DISTINCT fu.feature_name) AS distinct_beta_features_used,
    SUM(fu.usage_count) AS total_beta_interactions
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
INNER JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
WHERE fu.is_beta_feature = TRUE AND a.churn_flag = FALSE
GROUP BY a.account_id, a.account_name, a.industry, a.plan_tier
ORDER BY total_beta_interactions DESC;
-- Expected Business Insight:
-- Builds a roster of tech-forward customer accounts participating in beta features.


-- -----------------------------------------------------------------------------
-- Query 32
-- Business Question:
-- Which customer accounts use zero beta features?
--
-- Business Objective:
-- Identify conservative customer accounts requiring education on upcoming release features.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    a.plan_tier
FROM analytics.accounts a
WHERE a.churn_flag = FALSE
  AND NOT EXISTS (
      SELECT 1 
      FROM analytics.subscriptions s 
      INNER JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
      WHERE s.account_id = a.account_id AND fu.is_beta_feature = TRUE
  )
ORDER BY a.account_id;
-- Expected Business Insight:
-- Lists conservative accounts that stick strictly to core GA features.


-- -----------------------------------------------------------------------------
-- Query 33
-- Business Question:
-- Which customer accounts display high feature usage engagement (top 25%) but generate below-average MRR?
--
-- Business Objective:
-- Identify highly engaged under-monetized power-user accounts ripe for contract expansion upgrades.
-- -----------------------------------------------------------------------------
WITH usage_rank AS (
    SELECT s.account_id, SUM(fu.usage_count) AS total_clicks
    FROM analytics.subscriptions s
    INNER JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY s.account_id
),
avg_mrr_benchmark AS (
    SELECT AVG(mrr_amount) AS avg_mrr FROM analytics.subscriptions WHERE churn_flag = FALSE
)
SELECT 
    a.account_id,
    a.account_name,
    a.plan_tier,
    ur.total_clicks AS engagement_events,
    SUM(s.mrr_amount) AS current_mrr
FROM analytics.accounts a
INNER JOIN usage_rank ur ON a.account_id = ur.account_id
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE s.churn_flag = FALSE
GROUP BY a.account_id, a.account_name, a.plan_tier, ur.total_clicks
HAVING ur.total_clicks > (SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_clicks) FROM usage_rank)
   AND SUM(s.mrr_amount) < (SELECT avg_mrr FROM avg_mrr_benchmark)
ORDER BY ur.total_clicks DESC;
-- Expected Business Insight:
-- Targets power users paying below-average MRR for contract tier upgrades.


-- -----------------------------------------------------------------------------
-- Query 34
-- Business Question:
-- Which customer accounts generate high MRR (top 25%) but display below-average product feature adoption?
--
-- Business Objective:
-- Detect high-value accounts at risk of churn due to low product adoption and shelfware syndrome.
-- -----------------------------------------------------------------------------
WITH usage_summary AS (
    SELECT s.account_id, COALESCE(SUM(fu.usage_count), 0) AS total_clicks
    FROM analytics.subscriptions s
    LEFT JOIN analytics.feature_usage fu ON s.subscription_id = fu.subscription_id
    GROUP BY s.account_id
),
high_mrr_benchmark AS (
    SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY mrr_amount) AS p75_mrr
    FROM analytics.subscriptions WHERE churn_flag = FALSE
)
SELECT 
    a.account_id,
    a.account_name,
    a.plan_tier,
    SUM(s.mrr_amount) AS high_mrr,
    us.total_clicks AS low_usage_events
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
INNER JOIN usage_summary us ON a.account_id = us.account_id
WHERE s.churn_flag = FALSE
GROUP BY a.account_id, a.account_name, a.plan_tier, us.total_clicks
HAVING SUM(s.mrr_amount) >= (SELECT p75_mrr FROM high_mrr_benchmark)
   AND us.total_clicks < (SELECT AVG(total_clicks) FROM usage_summary)
ORDER BY high_mrr DESC;
-- Expected Business Insight:
-- Flags VIP accounts suffering from shelfware (high spending, low usage) for immediate CS onboarding.


-- =============================================================================
-- SECTION 7: RETENTION INTELLIGENCE
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 35
-- Business Question:
-- Which active customer accounts are at high risk of churn due to low usage (< 100 sessions) AND urgent support tickets?
--
-- Business Objective:
-- Build an early-warning account health alert list for Customer Success intervention.
-- -----------------------------------------------------------------------------
SELECT DISTINCT
    a.account_id,
    a.account_name,
    a.industry,
    a.plan_tier,
    SUM(s.mrr_amount) AS at_risk_mrr
FROM analytics.accounts a
INNER JOIN analytics.subscriptions s ON a.account_id = s.account_id
WHERE a.churn_flag = FALSE AND s.churn_flag = FALSE
  AND EXISTS (
      SELECT 1 
      FROM analytics.support_tickets st 
      WHERE st.account_id = a.account_id 
        AND LOWER(st.priority) IN ('urgent', 'high')
  )
  AND EXISTS (
      SELECT 1 
      FROM analytics.feature_usage fu 
      WHERE fu.subscription_id = s.subscription_id 
      GROUP BY fu.subscription_id 
      HAVING SUM(fu.usage_count) < 100
  )
GROUP BY a.account_id, a.account_name, a.industry, a.plan_tier
ORDER BY at_risk_mrr DESC;
-- Expected Business Insight:
-- Generates an actionable high-priority account save list for CS leadership.


-- -----------------------------------------------------------------------------
-- Query 36
-- Business Question:
-- Which industry verticals suffer from a customer account churn concentration rate exceeding 15%?
--
-- Business Objective:
-- Re-evaluate product-market fit and pricing models in vulnerable industry verticals.
-- -----------------------------------------------------------------------------
SELECT 
    industry,
    COUNT(account_id) AS total_accounts,
    SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) AS churned_accounts,
    ROUND(SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(account_id), 2) AS industry_churn_rate_pct
FROM analytics.accounts
GROUP BY industry
HAVING (SUM(CASE WHEN churn_flag = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(account_id)) > 15.0
ORDER BY industry_churn_rate_pct DESC;
-- Expected Business Insight:
-- Highlights vertical segments experiencing elevated cancellation concentration.


-- -----------------------------------------------------------------------------
-- Query 37
-- Business Question:
-- Which churned customer accounts experienced a subscription downgrade contract event prior to cancellation?
--
-- Business Objective:
-- Analyze the contraction-to-churn trajectory to build automated trigger warnings.
-- -----------------------------------------------------------------------------
SELECT 
    a.account_id,
    a.account_name,
    a.industry,
    ce.churn_date,
    ce.reason_code,
    ce.refund_amount_usd
FROM analytics.accounts a
INNER JOIN analytics.churn_events ce ON a.account_id = ce.account_id
WHERE a.churn_flag = TRUE
  AND EXISTS (
      SELECT 1 
      FROM analytics.subscriptions s 
      WHERE s.account_id = a.account_id 
        AND s.downgrade_flag = TRUE
  )
ORDER BY ce.churn_date DESC;
-- Expected Business Insight:
-- Confirms contract downgrades serve as a leading indicator of upcoming account cancellation.


-- -----------------------------------------------------------------------------
-- Query 38
-- Business Question:
-- Which customer accounts represent reactivated cancellations after a prior churn event?
--
-- Business Objective:
-- Study win-back campaign effectiveness and reactivation revenue streams.
-- -----------------------------------------------------------------------------
SELECT 
    ce.churn_event_id,
    a.account_id,
    a.account_name,
    a.industry,
    ce.churn_date,
    ce.reason_code,
    a.churn_flag AS current_churn_status
FROM analytics.churn_events ce
INNER JOIN analytics.accounts a ON ce.account_id = a.account_id
WHERE ce.is_reactivation = TRUE OR a.churn_flag = FALSE
ORDER BY ce.churn_date DESC;
-- Expected Business Insight:
-- Highlights successfully win-backed accounts returning to active status.
