-- =============================================================================
-- Project:         B2B SaaS Customer Cohort & Retention Analytics Platform
-- File:            validation.sql
-- Role:            Senior Data Architect / PostgreSQL Database Administrator
-- Target Engine:   PostgreSQL 13+
-- Purpose:         Data quality audit suite, referential integrity verification,
--                  and business logic sanity validation queries.
-- =============================================================================

SET search_path TO analytics, public;

--------------------------------------------------------------------------------
-- 1. DUPLICATE PRIMARY KEY CHECKS
-- Expected Result: 0 rows returned for all checks.
--------------------------------------------------------------------------------

-- 1.1 Accounts Primary Key Duplicates
SELECT 'accounts' AS table_name, account_id AS key_value, COUNT(*) AS duplicate_count
FROM analytics.accounts
GROUP BY account_id
HAVING COUNT(*) > 1;

-- 1.2 Subscriptions Primary Key Duplicates
SELECT 'subscriptions' AS table_name, subscription_id AS key_value, COUNT(*) AS duplicate_count
FROM analytics.subscriptions
GROUP BY subscription_id
HAVING COUNT(*) > 1;

-- 1.3 Feature Usage Primary Key Duplicates
SELECT 'feature_usage' AS table_name, usage_id AS key_value, COUNT(*) AS duplicate_count
FROM analytics.feature_usage
GROUP BY usage_id
HAVING COUNT(*) > 1;

-- 1.4 Support Tickets Primary Key Duplicates
SELECT 'support_tickets' AS table_name, ticket_id AS key_value, COUNT(*) AS duplicate_count
FROM analytics.support_tickets
GROUP BY ticket_id
HAVING COUNT(*) > 1;

-- 1.5 Churn Events Primary Key Duplicates
SELECT 'churn_events' AS table_name, churn_event_id AS key_value, COUNT(*) AS duplicate_count
FROM analytics.churn_events
GROUP BY churn_event_id
HAVING COUNT(*) > 1;

-- 1.6 Marketing Campaigns Primary Key Duplicates
SELECT 'marketing_campaigns' AS table_name, campaign_id AS key_value, COUNT(*) AS duplicate_count
FROM analytics.marketing_campaigns
GROUP BY campaign_id
HAVING COUNT(*) > 1;


--------------------------------------------------------------------------------
-- 2. NULL CHECK VALIDATIONS ON MANDATORY COLUMNS
-- Expected Result: 0 rows returned.
--------------------------------------------------------------------------------

-- 2.1 Accounts mandatory fields check
SELECT 'accounts' AS table_name, account_id
FROM analytics.accounts
WHERE account_name IS NULL 
   OR industry IS NULL 
   OR country IS NULL 
   OR signup_date IS NULL 
   OR plan_tier IS NULL 
   OR seats IS NULL;

-- 2.2 Subscriptions mandatory fields check
SELECT 'subscriptions' AS table_name, subscription_id
FROM analytics.subscriptions
WHERE account_id IS NULL 
   OR start_date IS NULL 
   OR plan_tier IS NULL 
   OR mrr_amount IS NULL 
   OR arr_amount IS NULL 
   OR billing_frequency IS NULL;


--------------------------------------------------------------------------------
-- 3. BROKEN FOREIGN KEY / ORPHANED RECORD CHECKS
-- Expected Result: 0 rows returned.
--------------------------------------------------------------------------------

-- 3.1 Subscriptions referencing non-existent Accounts
SELECT 'subscriptions' AS table_name, s.subscription_id, s.account_id
FROM analytics.subscriptions s
LEFT JOIN analytics.accounts a ON s.account_id = a.account_id
WHERE a.account_id IS NULL;

-- 3.2 Feature Usage referencing non-existent Subscriptions
SELECT 'feature_usage' AS table_name, fu.usage_id, fu.subscription_id
FROM analytics.feature_usage fu
LEFT JOIN analytics.subscriptions s ON fu.subscription_id = s.subscription_id
WHERE s.subscription_id IS NULL;

-- 3.3 Support Tickets referencing non-existent Accounts
SELECT 'support_tickets' AS table_name, st.ticket_id, st.account_id
FROM analytics.support_tickets st
LEFT JOIN analytics.accounts a ON st.account_id = a.account_id
WHERE a.account_id IS NULL;

-- 3.4 Churn Events referencing non-existent Accounts
SELECT 'churn_events' AS table_name, ce.churn_event_id, ce.account_id
FROM analytics.churn_events ce
LEFT JOIN analytics.accounts a ON ce.account_id = a.account_id
WHERE a.account_id IS NULL;

-- 3.5 Accounts referencing non-existent Marketing Campaigns
SELECT 'accounts' AS table_name, a.account_id, a.campaign_id
FROM analytics.accounts a
LEFT JOIN analytics.marketing_campaigns mc ON a.campaign_id = mc.campaign_id
WHERE a.campaign_id IS NOT NULL AND mc.campaign_id IS NULL;


--------------------------------------------------------------------------------
-- 4. FINANCIAL VALUE RANGE & SANITY CHECKS
-- Expected Result: 0 rows returned.
--------------------------------------------------------------------------------

-- 4.1 Negative MRR or ARR in Subscriptions
SELECT subscription_id, mrr_amount, arr_amount
FROM analytics.subscriptions
WHERE mrr_amount < 0 OR arr_amount < 0;

-- 4.2 Negative budget in Marketing Campaigns
SELECT campaign_id, budget_usd
FROM analytics.marketing_campaigns
WHERE budget_usd < 0;

-- 4.3 Negative refund amount in Churn Events
SELECT churn_event_id, refund_amount_usd
FROM analytics.churn_events
WHERE refund_amount_usd < 0;

-- 4.4 ARR to MRR Ratio Discrepancy (ARR should equal MRR * 12)
SELECT subscription_id, mrr_amount, arr_amount, (mrr_amount * 12) AS expected_arr
FROM analytics.subscriptions
WHERE ABS(arr_amount - (mrr_amount * 12)) > 0.01;


--------------------------------------------------------------------------------
-- 5. CATEGORICAL ENUMERATION & DOMAIN CHECKS
-- Expected Result: 0 rows returned.
--------------------------------------------------------------------------------

-- 5.1 Invalid Billing Frequency
SELECT subscription_id, billing_frequency
FROM analytics.subscriptions
WHERE LOWER(billing_frequency) NOT IN ('monthly', 'annual', 'quarterly', 'yearly');

-- 5.2 Invalid Support Ticket Priority
SELECT ticket_id, priority
FROM analytics.support_tickets
WHERE LOWER(priority) NOT IN ('low', 'medium', 'high', 'urgent');

-- 5.3 Invalid CSAT Satisfaction Score
SELECT ticket_id, satisfaction_score
FROM analytics.support_tickets
WHERE satisfaction_score IS NOT NULL AND (satisfaction_score < 1.0 OR satisfaction_score > 5.0);


--------------------------------------------------------------------------------
-- 6. CHRONOLOGICAL DATE LOGIC CHECKS
-- Expected Result: 0 rows returned.
--------------------------------------------------------------------------------

-- 6.1 Subscription end_date preceding start_date
SELECT subscription_id, start_date, end_date
FROM analytics.subscriptions
WHERE end_date IS NOT NULL AND end_date < start_date;

-- 6.2 Ticket closed_at preceding submitted_at
SELECT ticket_id, submitted_at, closed_at
FROM analytics.support_tickets
WHERE closed_at IS NOT NULL AND closed_at < submitted_at;

-- 6.3 Churn date preceding account signup_date
SELECT ce.churn_event_id, a.account_id, a.signup_date, ce.churn_date
FROM analytics.churn_events ce
JOIN analytics.accounts a ON ce.account_id = a.account_id
WHERE ce.churn_date < a.signup_date;


--------------------------------------------------------------------------------
-- 7. CHURN FLAG CONSISTENCY AUDIT
-- Description: Detect accounts marked churn_flag = TRUE but missing churn_events.
--------------------------------------------------------------------------------
SELECT a.account_id, a.account_name, a.churn_flag
FROM analytics.accounts a
LEFT JOIN analytics.churn_events ce ON a.account_id = ce.account_id
WHERE a.churn_flag = TRUE AND ce.churn_event_id IS NULL;
