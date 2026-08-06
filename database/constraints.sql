-- =============================================================================
-- Project:         B2B SaaS Customer Cohort & Retention Analytics Platform
-- File:            constraints.sql
-- Role:            Senior Data Architect / PostgreSQL Database Administrator
-- Target Engine:   PostgreSQL 13+
-- Purpose:         Relational integrity constraints including Primary Keys,
--                  Foreign Keys, and domain CHECK rules.
-- =============================================================================

SET search_path TO analytics, public;

--------------------------------------------------------------------------------
-- 1. PRIMARY KEY CONSTRAINTS
--------------------------------------------------------------------------------

ALTER TABLE analytics.marketing_campaigns
    ADD CONSTRAINT pk_marketing_campaigns PRIMARY KEY (campaign_id);

ALTER TABLE analytics.accounts
    ADD CONSTRAINT pk_accounts PRIMARY KEY (account_id);

ALTER TABLE analytics.subscriptions
    ADD CONSTRAINT pk_subscriptions PRIMARY KEY (subscription_id);

ALTER TABLE analytics.feature_usage
    ADD CONSTRAINT pk_feature_usage PRIMARY KEY (usage_id);

ALTER TABLE analytics.support_tickets
    ADD CONSTRAINT pk_support_tickets PRIMARY KEY (ticket_id);

ALTER TABLE analytics.churn_events
    ADD CONSTRAINT pk_churn_events PRIMARY KEY (churn_event_id);


--------------------------------------------------------------------------------
-- 2. FOREIGN KEY CONSTRAINTS
--------------------------------------------------------------------------------

-- FK: accounts -> marketing_campaigns
ALTER TABLE analytics.accounts
    ADD CONSTRAINT fk_accounts_marketing_campaigns 
    FOREIGN KEY (campaign_id) 
    REFERENCES analytics.marketing_campaigns (campaign_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

-- FK: subscriptions -> accounts
ALTER TABLE analytics.subscriptions
    ADD CONSTRAINT fk_subscriptions_accounts 
    FOREIGN KEY (account_id) 
    REFERENCES analytics.accounts (account_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE;

-- FK: feature_usage -> subscriptions
ALTER TABLE analytics.feature_usage
    ADD CONSTRAINT fk_feature_usage_subscriptions 
    FOREIGN KEY (subscription_id) 
    REFERENCES analytics.subscriptions (subscription_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

-- FK: support_tickets -> accounts
ALTER TABLE analytics.support_tickets
    ADD CONSTRAINT fk_support_tickets_accounts 
    FOREIGN KEY (account_id) 
    REFERENCES analytics.accounts (account_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

-- FK: churn_events -> accounts
ALTER TABLE analytics.churn_events
    ADD CONSTRAINT fk_churn_events_accounts 
    FOREIGN KEY (account_id) 
    REFERENCES analytics.accounts (account_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;


--------------------------------------------------------------------------------
-- 3. DOMAIN CHECK CONSTRAINTS
--------------------------------------------------------------------------------

-- marketing_campaigns CHECK rules
ALTER TABLE analytics.marketing_campaigns
    ADD CONSTRAINT chk_campaign_dates 
        CHECK (end_date IS NULL OR end_date >= start_date),
    ADD CONSTRAINT chk_campaign_budget_positive 
        CHECK (budget_usd >= 0),
    ADD CONSTRAINT chk_campaign_impressions_positive 
        CHECK (impressions >= 0),
    ADD CONSTRAINT chk_campaign_clicks_positive 
        CHECK (clicks >= 0),
    ADD CONSTRAINT chk_campaign_conversions_positive 
        CHECK (conversions >= 0);

-- accounts CHECK rules
ALTER TABLE analytics.accounts
    ADD CONSTRAINT chk_accounts_seats_positive 
        CHECK (seats >= 0),
    ADD CONSTRAINT chk_accounts_plan_tier 
        CHECK (LOWER(plan_tier) IN ('basic', 'pro', 'enterprise', 'starter', 'free'));

-- subscriptions CHECK rules
ALTER TABLE analytics.subscriptions
    ADD CONSTRAINT chk_sub_dates 
        CHECK (end_date IS NULL OR end_date >= start_date),
    ADD CONSTRAINT chk_sub_mrr_positive 
        CHECK (mrr_amount >= 0),
    ADD CONSTRAINT chk_sub_arr_positive 
        CHECK (arr_amount >= 0),
    ADD CONSTRAINT chk_sub_seats_positive 
        CHECK (seats >= 0),
    ADD CONSTRAINT chk_sub_billing_frequency 
        CHECK (LOWER(billing_frequency) IN ('monthly', 'annual', 'quarterly', 'yearly')),
    ADD CONSTRAINT chk_sub_plan_tier 
        CHECK (LOWER(plan_tier) IN ('basic', 'pro', 'enterprise', 'starter', 'free'));

-- feature_usage CHECK rules
ALTER TABLE analytics.feature_usage
    ADD CONSTRAINT chk_usage_count_positive 
        CHECK (usage_count >= 0),
    ADD CONSTRAINT chk_usage_duration_positive 
        CHECK (usage_duration_secs >= 0),
    ADD CONSTRAINT chk_error_count_positive 
        CHECK (error_count >= 0);

-- support_tickets CHECK rules
ALTER TABLE analytics.support_tickets
    ADD CONSTRAINT chk_ticket_timestamps 
        CHECK (closed_at IS NULL OR closed_at >= submitted_at),
    ADD CONSTRAINT chk_ticket_priority 
        CHECK (LOWER(priority) IN ('low', 'medium', 'high', 'urgent')),
    ADD CONSTRAINT chk_ticket_resolution_time_positive 
        CHECK (resolution_time_hours IS NULL OR resolution_time_hours >= 0),
    ADD CONSTRAINT chk_ticket_response_time_positive 
        CHECK (first_response_time_minutes IS NULL OR first_response_time_minutes >= 0),
    ADD CONSTRAINT chk_ticket_satisfaction_score_range 
        CHECK (satisfaction_score IS NULL OR (satisfaction_score >= 1.0 AND satisfaction_score <= 5.0));

-- churn_events CHECK rules
ALTER TABLE analytics.churn_events
    ADD CONSTRAINT chk_churn_refund_positive 
        CHECK (refund_amount_usd >= 0);
