-- =============================================================================
-- Project:         B2B SaaS Customer Cohort & Retention Analytics Platform
-- File:            sql/01_database_verification.sql
-- Role:            Principal Data Analyst / Senior Analytics Engineer
-- Target Engine:   PostgreSQL 13+
-- Purpose:         Pre-analytics Database Health & Data Quality Verification Suite.
--                  Executed before running business analytics to validate row counts,
--                  primary/foreign key integrity, business rules, and date logic.
-- =============================================================================

SET search_path TO analytics, public;

-- =============================================================================
-- SECTION 1: ROW COUNT VERIFICATION
-- Purpose: Confirm all 6 datasets imported the expected row counts.
-- Expected Result:
--   - marketing_campaigns: 40
--   - accounts: 500
--   - subscriptions: 5,000
--   - feature_usage: 25,000
--   - support_tickets: 2,000
--   - churn_events: 600
-- =============================================================================

SELECT 'marketing_campaigns' AS table_name, COUNT(*) AS total_rows FROM analytics.marketing_campaigns
UNION ALL
SELECT 'accounts' AS table_name, COUNT(*) AS total_rows FROM analytics.accounts
UNION ALL
SELECT 'subscriptions' AS table_name, COUNT(*) AS total_rows FROM analytics.subscriptions
UNION ALL
SELECT 'feature_usage' AS table_name, COUNT(*) AS total_rows FROM analytics.feature_usage
UNION ALL
SELECT 'support_tickets' AS table_name, COUNT(*) AS total_rows FROM analytics.support_tickets
UNION ALL
SELECT 'churn_events' AS table_name, COUNT(*) AS total_rows FROM analytics.churn_events
ORDER BY total_rows DESC;


-- =============================================================================
-- SECTION 2: PRIMARY KEY VALIDATION
-- Purpose: Detect any duplicate primary keys across all domain tables.
-- Expected Result: 0 rows returned for all queries.
-- =============================================================================

-- 2.1 Marketing Campaigns PK Uniqueness
SELECT 
    'marketing_campaigns' AS entity,
    campaign_id AS primary_key_value, 
    COUNT(*) AS duplicate_count
FROM analytics.marketing_campaigns
GROUP BY campaign_id
HAVING COUNT(*) > 1;

-- 2.2 Accounts PK Uniqueness
SELECT 
    'accounts' AS entity,
    account_id AS primary_key_value, 
    COUNT(*) AS duplicate_count
FROM analytics.accounts
GROUP BY account_id
HAVING COUNT(*) > 1;

-- 2.3 Subscriptions PK Uniqueness
SELECT 
    'subscriptions' AS entity,
    subscription_id AS primary_key_value, 
    COUNT(*) AS duplicate_count
FROM analytics.subscriptions
GROUP BY subscription_id
HAVING COUNT(*) > 1;

-- 2.4 Feature Usage PK Uniqueness
SELECT 
    'feature_usage' AS entity,
    usage_id AS primary_key_value, 
    COUNT(*) AS duplicate_count
FROM analytics.feature_usage
GROUP BY usage_id
HAVING COUNT(*) > 1;

-- 2.5 Support Tickets PK Uniqueness
SELECT 
    'support_tickets' AS entity,
    ticket_id AS primary_key_value, 
    COUNT(*) AS duplicate_count
FROM analytics.support_tickets
GROUP BY ticket_id
HAVING COUNT(*) > 1;

-- 2.6 Churn Events PK Uniqueness
SELECT 
    'churn_events' AS entity,
    churn_event_id AS primary_key_value, 
    COUNT(*) AS duplicate_count
FROM analytics.churn_events
GROUP BY churn_event_id
HAVING COUNT(*) > 1;


-- =============================================================================
-- SECTION 3: FOREIGN KEY & REFERENTIAL INTEGRITY VALIDATION
-- Purpose: Identify orphaned records in child tables that fail to reference 
--          their corresponding parent record.
-- Expected Result: 0 rows returned for all checks.
-- =============================================================================

-- 3.1 accounts -> marketing_campaigns FK Audit
SELECT 
    'accounts -> marketing_campaigns' AS fk_relationship,
    a.account_id,
    a.campaign_id AS orphaned_foreign_key
FROM analytics.accounts a
LEFT JOIN analytics.marketing_campaigns mc ON a.campaign_id = mc.campaign_id
WHERE a.campaign_id IS NOT NULL AND mc.campaign_id IS NULL;

-- 3.2 subscriptions -> accounts FK Audit
SELECT 
    'subscriptions -> accounts' AS fk_relationship,
    s.subscription_id,
    s.account_id AS orphaned_foreign_key
FROM analytics.subscriptions s
LEFT JOIN analytics.accounts a ON s.account_id = a.account_id
WHERE a.account_id IS NULL;

-- 3.3 feature_usage -> subscriptions FK Audit
SELECT 
    'feature_usage -> subscriptions' AS fk_relationship,
    fu.usage_id,
    fu.subscription_id AS orphaned_foreign_key
FROM analytics.feature_usage fu
LEFT JOIN analytics.subscriptions s ON fu.subscription_id = s.subscription_id
WHERE s.subscription_id IS NULL;

-- 3.4 support_tickets -> accounts FK Audit
SELECT 
    'support_tickets -> accounts' AS fk_relationship,
    st.ticket_id,
    st.account_id AS orphaned_foreign_key
FROM analytics.support_tickets st
LEFT JOIN analytics.accounts a ON st.account_id = a.account_id
WHERE a.account_id IS NULL;

-- 3.5 churn_events -> accounts FK Audit
SELECT 
    'churn_events -> accounts' AS fk_relationship,
    ce.churn_event_id,
    ce.account_id AS orphaned_foreign_key
FROM analytics.churn_events ce
LEFT JOIN analytics.accounts a ON ce.account_id = a.account_id
WHERE a.account_id IS NULL;


-- =============================================================================
-- SECTION 4: NULL VALUE & COMPLETENESS ANALYSIS
-- Purpose: Check mandatory attributes for unexpected NULL occurrences.
-- Expected Result: 0 rows returned for mandatory column checks.
-- =============================================================================

-- 4.1 Accounts Mandatory Attributes Audit
SELECT 
    'accounts' AS table_name,
    account_id,
    account_name,
    signup_date,
    plan_tier
FROM analytics.accounts
WHERE account_name IS NULL 
   OR signup_date IS NULL 
   OR plan_tier IS NULL 
   OR seats IS NULL 
   OR industry IS NULL 
   OR country IS NULL;

-- 4.2 Subscriptions Mandatory Attributes Audit
SELECT 
    'subscriptions' AS table_name,
    subscription_id,
    account_id,
    start_date,
    mrr_amount
FROM analytics.subscriptions
WHERE account_id IS NULL 
   OR start_date IS NULL 
   OR mrr_amount IS NULL 
   OR arr_amount IS NULL 
   OR billing_frequency IS NULL;


-- =============================================================================
-- SECTION 5: REVENUE & FINANCIAL RANGE VALIDATION
-- Purpose: Detect negative monetary amounts and ARR/MRR ratio discrepancies.
-- Expected Result: 0 rows returned.
-- =============================================================================

-- 5.1 Subscriptions Financial Range Audit
SELECT 
    subscription_id,
    account_id,
    mrr_amount,
    arr_amount,
    (mrr_amount * 12) AS expected_arr
FROM analytics.subscriptions
WHERE mrr_amount < 0 
   OR arr_amount < 0 
   OR ABS(arr_amount - (mrr_amount * 12)) > 0.01;

-- 5.2 Marketing Campaigns Budget Audit
SELECT 
    campaign_id,
    campaign_name,
    budget_usd
FROM analytics.marketing_campaigns
WHERE budget_usd <= 0;

-- 5.3 Churn Events Refund Audit
SELECT 
    churn_event_id,
    account_id,
    refund_amount_usd
FROM analytics.churn_events
WHERE refund_amount_usd < 0;


-- =============================================================================
-- SECTION 6: CHRONOLOGICAL DATE LOGIC VALIDATION
-- Purpose: Ensure temporal consistency across start, end, and submission dates.
-- Expected Result: 0 rows returned.
-- =============================================================================

-- 6.1 Subscriptions Date Order Audit
SELECT 
    subscription_id,
    account_id,
    start_date,
    end_date
FROM analytics.subscriptions
WHERE end_date IS NOT NULL AND end_date < start_date;

-- 6.2 Support Tickets Timestamp Order Audit
SELECT 
    ticket_id,
    account_id,
    submitted_at,
    closed_at
FROM analytics.support_tickets
WHERE closed_at IS NOT NULL AND closed_at < submitted_at;

-- 6.3 Marketing Campaigns Date Order Audit
SELECT 
    campaign_id,
    campaign_name,
    start_date,
    end_date
FROM analytics.marketing_campaigns
WHERE end_date IS NOT NULL AND end_date < start_date;

-- 6.4 Churn Event vs Signup Date Audit
SELECT 
    ce.churn_event_id,
    a.account_id,
    a.signup_date,
    ce.churn_date
FROM analytics.churn_events ce
JOIN analytics.accounts a ON ce.account_id = a.account_id
WHERE ce.churn_date < a.signup_date;


-- =============================================================================
-- SECTION 7: BUSINESS RULE & ENUMERATION VALIDATION
-- Purpose: Validate allowed categorical values and numeric boundary rules.
-- Expected Result: 0 rows returned.
-- =============================================================================

-- 7.1 Subscription Billing Frequency Audit
SELECT 
    subscription_id,
    billing_frequency
FROM analytics.subscriptions
WHERE LOWER(billing_frequency) NOT IN ('monthly', 'annual', 'quarterly', 'yearly');

-- 7.2 Support Ticket Priority Audit
SELECT 
    ticket_id,
    priority
FROM analytics.support_tickets
WHERE LOWER(priority) NOT IN ('low', 'medium', 'high', 'urgent');

-- 7.3 Support CSAT Satisfaction Score Range Audit (1.0 to 5.0)
SELECT 
    ticket_id,
    satisfaction_score
FROM analytics.support_tickets
WHERE satisfaction_score IS NOT NULL 
  AND (satisfaction_score < 1.0 OR satisfaction_score > 5.0);

-- 7.4 Account Seat Allocation Audit
SELECT 
    account_id,
    seats
FROM analytics.accounts
WHERE seats < 0;


-- =============================================================================
-- SECTION 8: MARKETING CAMPAIGN COVERAGE & DISTRIBUTION
-- Purpose: Verify campaign attribution coverage, detect unused campaigns, 
--          and analyze account distribution across marketing channels.
-- Expected Result: 
--   - 100% campaign assignment coverage for all accounts.
--   - Distribution across channels (Google Ads, LinkedIn, Referral, etc.).
-- =============================================================================

-- 8.1 Campaign Assignment Coverage Check
SELECT 
    COUNT(*) AS total_accounts,
    COUNT(campaign_id) AS accounts_with_campaign,
    COUNT(*) - COUNT(campaign_id) AS accounts_missing_campaign,
    ROUND(COUNT(campaign_id) * 100.0 / COUNT(*), 2) AS coverage_pct
FROM analytics.accounts;

-- 8.2 Unused Campaigns Identification
SELECT 
    mc.campaign_id,
    mc.campaign_name,
    mc.channel,
    mc.budget_usd
FROM analytics.marketing_campaigns mc
LEFT JOIN analytics.accounts a ON mc.campaign_id = a.campaign_id
WHERE a.account_id IS NULL;

-- 8.3 Account Acquisition Distribution by Channel
SELECT 
    COALESCE(mc.channel, 'Unattributed') AS channel_name,
    COUNT(a.account_id) AS attributed_accounts,
    ROUND(COUNT(a.account_id) * 100.0 / (SELECT COUNT(*) FROM analytics.accounts), 2) AS account_share_pct
FROM analytics.accounts a
LEFT JOIN analytics.marketing_campaigns mc ON a.campaign_id = mc.campaign_id
GROUP BY COALESCE(mc.channel, 'Unattributed')
ORDER BY attributed_accounts DESC;


-- =============================================================================
-- SECTION 9: DATABASE HEALTH SUMMARY & OVERALL VERDICT
-- Purpose: Aggregate verification results into a single executive pass/fail metric.
-- Expected Result: PASS status with 0 integrity violations across all rules.
-- =============================================================================

WITH verification_metrics AS (
    SELECT 
        (SELECT COUNT(*) FROM (
            SELECT a.account_id FROM analytics.accounts a LEFT JOIN analytics.marketing_campaigns mc ON a.campaign_id = mc.campaign_id WHERE a.campaign_id IS NOT NULL AND mc.campaign_id IS NULL
            UNION ALL
            SELECT s.subscription_id FROM analytics.subscriptions s LEFT JOIN analytics.accounts a ON s.account_id = a.account_id WHERE a.account_id IS NULL
            UNION ALL
            SELECT fu.usage_id FROM analytics.feature_usage fu LEFT JOIN analytics.subscriptions s ON fu.subscription_id = s.subscription_id WHERE s.subscription_id IS NULL
            UNION ALL
            SELECT st.ticket_id FROM analytics.support_tickets st LEFT JOIN analytics.accounts a ON st.account_id = a.account_id WHERE a.account_id IS NULL
            UNION ALL
            SELECT ce.churn_event_id FROM analytics.churn_events ce LEFT JOIN analytics.accounts a ON ce.account_id = a.account_id WHERE a.account_id IS NULL
        ) fk_violations) AS fk_error_count,

        (SELECT COUNT(*) FROM analytics.subscriptions WHERE mrr_amount < 0 OR arr_amount < 0 OR ABS(arr_amount - (mrr_amount * 12)) > 0.01) AS financial_error_count,
        (SELECT COUNT(*) FROM analytics.subscriptions WHERE end_date IS NOT NULL AND end_date < start_date) AS date_error_count,
        (SELECT COUNT(*) FROM analytics.accounts WHERE campaign_id IS NULL) AS missing_campaign_count
)
SELECT 
    (SELECT COUNT(*) FROM analytics.accounts) AS verified_accounts_count,
    (SELECT COUNT(*) FROM analytics.subscriptions) AS verified_subscriptions_count,
    fk_error_count,
    financial_error_count,
    date_error_count,
    missing_campaign_count,
    CASE 
        WHEN (fk_error_count + financial_error_count + date_error_count + missing_campaign_count) = 0 THEN 'PASS - DATABASE READY FOR ANALYTICS'
        ELSE 'FAIL - INTEGRITY VIOLATIONS DETECTED'
    END AS database_health_verdict
FROM verification_metrics;
