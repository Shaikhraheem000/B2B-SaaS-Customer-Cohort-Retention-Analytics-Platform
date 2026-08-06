-- =============================================================================
-- Project:         B2B SaaS Customer Cohort & Retention Analytics Platform
-- File:            indexes.sql
-- Role:            Senior Data Architect / PostgreSQL Database Administrator
-- Target Engine:   PostgreSQL 13+
-- Purpose:         Performance tuning & B-tree indexes for foreign keys,
--                  frequent filtering parameters, and join predicates.
-- =============================================================================

SET search_path TO analytics, public;

--------------------------------------------------------------------------------
-- 1. INDEXES: marketing_campaigns
--------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_marketing_campaigns_channel 
    ON analytics.marketing_campaigns (channel);

CREATE INDEX IF NOT EXISTS idx_marketing_campaigns_dates 
    ON analytics.marketing_campaigns (start_date, end_date);


--------------------------------------------------------------------------------
-- 2. INDEXES: accounts
--------------------------------------------------------------------------------
-- FK index for marketing campaign joins
CREATE INDEX IF NOT EXISTS idx_accounts_campaign_id 
    ON analytics.accounts (campaign_id);

-- Cohort grouping by signup date
CREATE INDEX IF NOT EXISTS idx_accounts_signup_date 
    ON analytics.accounts (signup_date);

-- Demographic & segmentation filtering
CREATE INDEX IF NOT EXISTS idx_accounts_country 
    ON analytics.accounts (country);

CREATE INDEX IF NOT EXISTS idx_accounts_industry 
    ON analytics.accounts (industry);

CREATE INDEX IF NOT EXISTS idx_accounts_plan_tier 
    ON analytics.accounts (plan_tier);

-- Churn filtering index
CREATE INDEX IF NOT EXISTS idx_accounts_churn_flag 
    ON analytics.accounts (churn_flag);

-- Composite index for cohort analysis filtering
CREATE INDEX IF NOT EXISTS idx_accounts_cohort_filter 
    ON analytics.accounts (signup_date, plan_tier, industry);


--------------------------------------------------------------------------------
-- 3. INDEXES: subscriptions
--------------------------------------------------------------------------------
-- FK index for account joins
CREATE INDEX IF NOT EXISTS idx_subscriptions_account_id 
    ON analytics.subscriptions (account_id);

-- Date filtering indexes
CREATE INDEX IF NOT EXISTS idx_subscriptions_start_date 
    ON analytics.subscriptions (start_date);

CREATE INDEX IF NOT EXISTS idx_subscriptions_end_date 
    ON analytics.subscriptions (end_date);

-- Subscription status & plan parameters
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan_tier 
    ON analytics.subscriptions (plan_tier);

CREATE INDEX IF NOT EXISTS idx_subscriptions_churn_flag 
    ON analytics.subscriptions (churn_flag);

CREATE INDEX IF NOT EXISTS idx_subscriptions_billing_frequency 
    ON analytics.subscriptions (billing_frequency);

-- Composite index for MRR rollups by active contract window
CREATE INDEX IF NOT EXISTS idx_subscriptions_active_mrr 
    ON analytics.subscriptions (account_id, start_date, end_date, mrr_amount);


--------------------------------------------------------------------------------
-- 4. INDEXES: feature_usage
--------------------------------------------------------------------------------
-- FK index for subscription joins
CREATE INDEX IF NOT EXISTS idx_feature_usage_subscription_id 
    ON analytics.feature_usage (subscription_id);

-- Usage date indexing for time-series analysis
CREATE INDEX IF NOT EXISTS idx_feature_usage_usage_date 
    ON analytics.feature_usage (usage_date);

-- Feature taxonomy lookup
CREATE INDEX IF NOT EXISTS idx_feature_usage_feature_name 
    ON analytics.feature_usage (feature_name);

-- Composite index for daily usage aggregation per subscription
CREATE INDEX IF NOT EXISTS idx_feature_usage_sub_date 
    ON analytics.feature_usage (subscription_id, usage_date);


--------------------------------------------------------------------------------
-- 5. INDEXES: support_tickets
--------------------------------------------------------------------------------
-- FK index for account joins
CREATE INDEX IF NOT EXISTS idx_support_tickets_account_id 
    ON analytics.support_tickets (account_id);

-- Ticket submission timestamp index for SLA tracking
CREATE INDEX IF NOT EXISTS idx_support_tickets_submitted_at 
    ON analytics.support_tickets (submitted_at);

-- Priority & Satisfaction filtering
CREATE INDEX IF NOT EXISTS idx_support_tickets_priority 
    ON analytics.support_tickets (priority);

CREATE INDEX IF NOT EXISTS idx_support_tickets_satisfaction_score 
    ON analytics.support_tickets (satisfaction_score);

-- Composite index for open ticket SLA performance checks
CREATE INDEX IF NOT EXISTS idx_support_tickets_sla 
    ON analytics.support_tickets (account_id, priority, submitted_at, closed_at);


--------------------------------------------------------------------------------
-- 6. INDEXES: churn_events
--------------------------------------------------------------------------------
-- FK index for account joins
CREATE INDEX IF NOT EXISTS idx_churn_events_account_id 
    ON analytics.churn_events (account_id);

-- Churn event date indexing
CREATE INDEX IF NOT EXISTS idx_churn_events_churn_date 
    ON analytics.churn_events (churn_date);

-- Churn reason analysis lookup
CREATE INDEX IF NOT EXISTS idx_churn_events_reason_code 
    ON analytics.churn_events (reason_code);
