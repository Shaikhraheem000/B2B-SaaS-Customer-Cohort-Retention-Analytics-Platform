-- =============================================================================
-- Project:         B2B SaaS Customer Cohort & Retention Analytics Platform
-- File:            import_data.sql
-- Role:            Senior Data Engineer / PostgreSQL Database Administrator
-- Target Engine:   PostgreSQL 13+
-- Purpose:         Automated data ingestion script using psql \copy meta-commands.
--                  Imports processed CSV datasets into analytics schema tables.
-- =============================================================================

SET search_path TO analytics, public;

--------------------------------------------------------------------------------
-- 1. IMPORT ORDER & REFERENTIAL INTEGRITY NOTICE
-- Note: Must be executed in sequential order to satisfy Foreign Key constraints:
--       1. marketing_campaigns (No FK dependencies)
--       2. accounts            (References marketing_campaigns)
--       3. subscriptions       (References accounts)
--       4. feature_usage       (References subscriptions)
--       5. support_tickets     (References accounts)
--       6. churn_events        (References accounts)
--------------------------------------------------------------------------------

-- Truncate tables before fresh re-import (Optional, disabled by default)
-- TRUNCATE analytics.churn_events, analytics.support_tickets, analytics.feature_usage, 
--          analytics.subscriptions, analytics.accounts, analytics.marketing_campaigns CASCADE;

--------------------------------------------------------------------------------
-- Step 1: Import marketing_campaigns
--------------------------------------------------------------------------------
\echo 'Importing marketing_campaigns dataset...'
\copy analytics.marketing_campaigns (campaign_id, campaign_name, channel, campaign_type, start_date, end_date, budget_usd, impressions, clicks, conversions) FROM 'data/processed/marketing_campaigns.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

--------------------------------------------------------------------------------
-- Step 2: Import accounts
--------------------------------------------------------------------------------
\echo 'Importing accounts dataset...'
\copy analytics.accounts (account_id, account_name, industry, country, signup_date, referral_source, plan_tier, seats, is_trial, churn_flag, campaign_id) FROM 'data/processed/accounts.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

--------------------------------------------------------------------------------
-- Step 3: Import subscriptions
--------------------------------------------------------------------------------
\echo 'Importing subscriptions dataset...'
\copy analytics.subscriptions (subscription_id, account_id, start_date, end_date, plan_tier, seats, mrr_amount, arr_amount, is_trial, upgrade_flag, downgrade_flag, churn_flag, billing_frequency, auto_renew_flag) FROM 'data/processed/subscriptions.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

--------------------------------------------------------------------------------
-- Step 4: Import feature_usage
--------------------------------------------------------------------------------
\echo 'Importing feature_usage telemetry dataset...'
\copy analytics.feature_usage (usage_id, subscription_id, usage_date, feature_name, usage_count, usage_duration_secs, error_count, is_beta_feature) FROM 'data/processed/feature_usage.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

--------------------------------------------------------------------------------
-- Step 5: Import support_tickets
--------------------------------------------------------------------------------
\echo 'Importing support_tickets operations dataset...'
\copy analytics.support_tickets (ticket_id, account_id, submitted_at, closed_at, resolution_time_hours, priority, first_response_time_minutes, satisfaction_score, escalation_flag) FROM 'data/processed/support_tickets.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

--------------------------------------------------------------------------------
-- Step 6: Import churn_events
--------------------------------------------------------------------------------
\echo 'Importing churn_events dataset...'
\copy analytics.churn_events (churn_event_id, account_id, churn_date, reason_code, refund_amount_usd, preceding_upgrade_flag, preceding_downgrade_flag, is_reactivation, feedback_text) FROM 'data/processed/churn_events.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', NULL '');

\echo '======================================================================'
\echo 'Data Ingestion Completed Successfully!'
\echo '======================================================================'
