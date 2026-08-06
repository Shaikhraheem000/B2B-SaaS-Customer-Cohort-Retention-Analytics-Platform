-- =============================================================================
-- Project:         B2B SaaS Customer Cohort & Retention Analytics Platform
-- File:            tables.sql
-- Role:            Senior Data Architect / PostgreSQL Database Administrator
-- Target Engine:   PostgreSQL 13+
-- Purpose:         DDL table definitions, data types, nullability rules, and
--                  comprehensive table & column documentation comments.
-- =============================================================================

SET search_path TO analytics, public;

--------------------------------------------------------------------------------
-- 1. DROP TABLE STATEMENT (Clean Re-creation Cascade)
--------------------------------------------------------------------------------
DROP TABLE IF EXISTS analytics.churn_events CASCADE;
DROP TABLE IF EXISTS analytics.support_tickets CASCADE;
DROP TABLE IF EXISTS analytics.feature_usage CASCADE;
DROP TABLE IF EXISTS analytics.subscriptions CASCADE;
DROP TABLE IF EXISTS analytics.accounts CASCADE;
DROP TABLE IF EXISTS analytics.marketing_campaigns CASCADE;

--------------------------------------------------------------------------------
-- 2. TABLE: marketing_campaigns (New Marketing Acquisition Domain)
--------------------------------------------------------------------------------
CREATE TABLE analytics.marketing_campaigns (
    campaign_id     VARCHAR(50)     NOT NULL,
    campaign_name   VARCHAR(100)    NOT NULL,
    channel         VARCHAR(50)     NOT NULL,
    campaign_type   VARCHAR(50)     NOT NULL,
    start_date      DATE            NOT NULL,
    end_date        DATE,
    budget_usd      NUMERIC(12,2)   NOT NULL DEFAULT 0.00,
    impressions     BIGINT          NOT NULL DEFAULT 0,
    clicks          BIGINT          NOT NULL DEFAULT 0,
    conversions     INT             NOT NULL DEFAULT 0
);

COMMENT ON TABLE analytics.marketing_campaigns IS 
'Stores paid and organic marketing campaigns, budget allocations, performance metrics, and acquisition channel metadata.';

COMMENT ON COLUMN analytics.marketing_campaigns.campaign_id IS 'Unique primary key identifier for each marketing campaign (e.g., CAMP-001).';
COMMENT ON COLUMN analytics.marketing_campaigns.campaign_name IS 'Descriptive title of marketing campaign (e.g., Q1_Google_Ads_Search).';
COMMENT ON COLUMN analytics.marketing_campaigns.channel IS 'Marketing acquisition channel (e.g., Google_Ads, LinkedIn, SEO, Partner, Event).';
COMMENT ON COLUMN analytics.marketing_campaigns.campaign_type IS 'Strategy classification (e.g., Paid_Search, Content_Marketing, Outbound, Webinar).';
COMMENT ON COLUMN analytics.marketing_campaigns.start_date IS 'Official launch date of marketing campaign.';
COMMENT ON COLUMN analytics.marketing_campaigns.end_date IS 'Concluding date of campaign. NULL indicates ongoing evergreen campaign.';
COMMENT ON COLUMN analytics.marketing_campaigns.budget_usd IS 'Total capital allocated or spent on campaign in USD.';
COMMENT ON COLUMN analytics.marketing_campaigns.impressions IS 'Total ad view impressions logged for campaign.';
COMMENT ON COLUMN analytics.marketing_campaigns.clicks IS 'Total user click-through actions logged.';
COMMENT ON COLUMN analytics.marketing_campaigns.conversions IS 'Total registered account signups attributed to campaign.';

--------------------------------------------------------------------------------
-- 3. TABLE: accounts (Master Customer Account Profile)
--------------------------------------------------------------------------------
CREATE TABLE analytics.accounts (
    account_id      VARCHAR(50)     NOT NULL,
    account_name    VARCHAR(100)    NOT NULL,
    industry        VARCHAR(50)     NOT NULL,
    country         VARCHAR(50)     NOT NULL,
    signup_date     DATE            NOT NULL,
    referral_source VARCHAR(50),
    plan_tier       VARCHAR(50)     NOT NULL,
    seats           INT             NOT NULL DEFAULT 1,
    is_trial        BOOLEAN         NOT NULL DEFAULT FALSE,
    churn_flag      BOOLEAN         NOT NULL DEFAULT FALSE,
    campaign_id     VARCHAR(50)
);

COMMENT ON TABLE analytics.accounts IS 
'Master customer accounts entity storing account profiles, tier classifications, acquisition channels, and churn flags.';

COMMENT ON COLUMN analytics.accounts.account_id IS 'Unique primary key identifier for customer account (e.g., A-2e4581).';
COMMENT ON COLUMN analytics.accounts.account_name IS 'Company or customer account name.';
COMMENT ON COLUMN analytics.accounts.industry IS 'Industry domain classification (e.g., EdTech, FinTech, DevTools, HealthTech).';
COMMENT ON COLUMN analytics.accounts.country IS 'Headquarter country ISO code or name (e.g., US, IN, UK, DE, CA).';
COMMENT ON COLUMN analytics.accounts.signup_date IS 'Calendar date account was created.';
COMMENT ON COLUMN analytics.accounts.referral_source IS 'Organic or partner referral attribution source (e.g., partner, organic, direct).';
COMMENT ON COLUMN analytics.accounts.plan_tier IS 'Current plan tier level (e.g., Basic, Pro, Enterprise).';
COMMENT ON COLUMN analytics.accounts.seats IS 'Number of provisioned user seats allocated to account.';
COMMENT ON COLUMN analytics.accounts.is_trial IS 'Boolean flag indicating if account is currently on a trial evaluation period.';
COMMENT ON COLUMN analytics.accounts.churn_flag IS 'Boolean flag indicating if account has cancelled all active subscriptions.';
COMMENT ON COLUMN analytics.accounts.campaign_id IS 'Foreign key referencing marketing_campaigns table for paid acquisition attribution.';

--------------------------------------------------------------------------------
-- 4. TABLE: subscriptions (Contract Lifecycle & Revenue)
--------------------------------------------------------------------------------
CREATE TABLE analytics.subscriptions (
    subscription_id     VARCHAR(50)     NOT NULL,
    account_id          VARCHAR(50)     NOT NULL,
    start_date          DATE            NOT NULL,
    end_date            DATE,
    plan_tier           VARCHAR(50)     NOT NULL,
    seats               INT             NOT NULL DEFAULT 1,
    mrr_amount          NUMERIC(12,2)   NOT NULL DEFAULT 0.00,
    arr_amount          NUMERIC(12,2)   NOT NULL DEFAULT 0.00,
    is_trial            BOOLEAN         NOT NULL DEFAULT FALSE,
    upgrade_flag        BOOLEAN         NOT NULL DEFAULT FALSE,
    downgrade_flag      BOOLEAN         NOT NULL DEFAULT FALSE,
    churn_flag          BOOLEAN         NOT NULL DEFAULT FALSE,
    billing_frequency   VARCHAR(20)     NOT NULL,
    auto_renew_flag     BOOLEAN         NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE analytics.subscriptions IS 
'Stores individual subscription contracts, recurring revenue (MRR/ARR), plan changes, and renewal statuses.';

COMMENT ON COLUMN analytics.subscriptions.subscription_id IS 'Unique primary key identifier for subscription contract (e.g., S-8cec59).';
COMMENT ON COLUMN analytics.subscriptions.account_id IS 'Foreign key referencing accounts table.';
COMMENT ON COLUMN analytics.subscriptions.start_date IS 'Effective start date of subscription contract.';
COMMENT ON COLUMN analytics.subscriptions.end_date IS 'Expiration or cancellation date. NULL if subscription is active.';
COMMENT ON COLUMN analytics.subscriptions.plan_tier IS 'Subscription plan tier (e.g., Basic, Pro, Enterprise).';
COMMENT ON COLUMN analytics.subscriptions.seats IS 'Number of active user licenses in contract.';
COMMENT ON COLUMN analytics.subscriptions.mrr_amount IS 'Monthly Recurring Revenue value in USD generated by subscription.';
COMMENT ON COLUMN analytics.subscriptions.arr_amount IS 'Annualized Recurring Revenue value in USD (mrr_amount * 12).';
COMMENT ON COLUMN analytics.subscriptions.is_trial IS 'Boolean flag indicating if subscription is a free trial.';
COMMENT ON COLUMN analytics.subscriptions.upgrade_flag IS 'Boolean flag indicating if contract represents an expansion upgrade.';
COMMENT ON COLUMN analytics.subscriptions.downgrade_flag IS 'Boolean flag indicating if contract represents a contraction downgrade.';
COMMENT ON COLUMN analytics.subscriptions.churn_flag IS 'Boolean flag indicating if contract ended in cancellation.';
COMMENT ON COLUMN analytics.subscriptions.billing_frequency IS 'Billing cycle cadence (e.g., monthly, annual).';
COMMENT ON COLUMN analytics.subscriptions.auto_renew_flag IS 'Boolean flag indicating if subscription contract auto-renews at term end.';

--------------------------------------------------------------------------------
-- 5. TABLE: feature_usage (Product Usage Telemetry)
--------------------------------------------------------------------------------
CREATE TABLE analytics.feature_usage (
    usage_id            VARCHAR(50)     NOT NULL,
    subscription_id     VARCHAR(50)     NOT NULL,
    usage_date          DATE            NOT NULL,
    feature_name        VARCHAR(100)    NOT NULL,
    usage_count         INT             NOT NULL DEFAULT 0,
    usage_duration_secs INT             NOT NULL DEFAULT 0,
    error_count         INT             NOT NULL DEFAULT 0,
    is_beta_feature     BOOLEAN         NOT NULL DEFAULT FALSE
);

COMMENT ON TABLE analytics.feature_usage IS 
'Daily aggregated product telemetry tracking feature interactions, session durations, and error occurrences per subscription.';

COMMENT ON COLUMN analytics.feature_usage.usage_id IS 'Unique primary key identifier for usage telemetry record (e.g., U-1c6c24).';
COMMENT ON COLUMN analytics.feature_usage.subscription_id IS 'Foreign key referencing subscriptions table.';
COMMENT ON COLUMN analytics.feature_usage.usage_date IS 'Calendar date usage activity occurred.';
COMMENT ON COLUMN analytics.feature_usage.feature_name IS 'Identifier/name of platform feature used (e.g., feature_20, feature_5).';
COMMENT ON COLUMN analytics.feature_usage.usage_count IS 'Total interaction count for feature on usage_date.';
COMMENT ON COLUMN analytics.feature_usage.usage_duration_secs IS 'Cumulative feature active engagement duration in seconds.';
COMMENT ON COLUMN analytics.feature_usage.error_count IS 'Number of error events triggered during feature engagement.';
COMMENT ON COLUMN analytics.feature_usage.is_beta_feature IS 'Boolean flag indicating if feature is in beta evaluation.';

--------------------------------------------------------------------------------
-- 6. TABLE: support_tickets (Customer Support Operations)
--------------------------------------------------------------------------------
CREATE TABLE analytics.support_tickets (
    ticket_id                   VARCHAR(50)     NOT NULL,
    account_id                  VARCHAR(50)     NOT NULL,
    submitted_at                TIMESTAMP       NOT NULL,
    closed_at                   TIMESTAMP,
    resolution_time_hours       NUMERIC(10,2),
    priority                    VARCHAR(20)     NOT NULL,
    first_response_time_minutes INT,
    satisfaction_score          NUMERIC(3,1),
    escalation_flag             BOOLEAN         NOT NULL DEFAULT FALSE
);

COMMENT ON TABLE analytics.support_tickets IS 
'Stores customer support tickets, SLA resolution metrics, priority levels, CSAT scores, and escalation flags.';

COMMENT ON COLUMN analytics.support_tickets.ticket_id IS 'Unique primary key identifier for support ticket (e.g., T-0024de).';
COMMENT ON COLUMN analytics.support_tickets.account_id IS 'Foreign key referencing accounts table.';
COMMENT ON COLUMN analytics.support_tickets.submitted_at IS 'Timestamp when ticket was created by customer.';
COMMENT ON COLUMN analytics.support_tickets.closed_at IS 'Timestamp when ticket was resolved and closed. NULL if open.';
COMMENT ON COLUMN analytics.support_tickets.resolution_time_hours IS 'Elapsed time in hours from submission to ticket closure.';
COMMENT ON COLUMN analytics.support_tickets.priority IS 'Ticket urgency priority level (e.g., low, medium, high, urgent).';
COMMENT ON COLUMN analytics.support_tickets.first_response_time_minutes IS 'Elapsed time in minutes to first support agent response.';
COMMENT ON COLUMN analytics.support_tickets.satisfaction_score IS 'Customer satisfaction rating score (1.0 to 5.0 rating scale).';
COMMENT ON COLUMN analytics.support_tickets.escalation_flag IS 'Boolean flag indicating if ticket was escalated to senior engineering/support.';

--------------------------------------------------------------------------------
-- 7. TABLE: churn_events (Subscription Cancellation Events)
--------------------------------------------------------------------------------
CREATE TABLE analytics.churn_events (
    churn_event_id          VARCHAR(50)     NOT NULL,
    account_id              VARCHAR(50)     NOT NULL,
    churn_date              DATE            NOT NULL,
    reason_code             VARCHAR(50)     NOT NULL,
    refund_amount_usd       NUMERIC(12,2)   NOT NULL DEFAULT 0.00,
    preceding_upgrade_flag  BOOLEAN         NOT NULL DEFAULT FALSE,
    preceding_downgrade_flag BOOLEAN        NOT NULL DEFAULT FALSE,
    is_reactivation         BOOLEAN         NOT NULL DEFAULT FALSE,
    feedback_text           TEXT
);

COMMENT ON TABLE analytics.churn_events IS 
'Granular churn event log tracking customer cancellations, primary root cause reason codes, refunds, and exit feedback.';

COMMENT ON COLUMN analytics.churn_events.churn_event_id IS 'Unique primary key identifier for churn event record (e.g., C-816288).';
COMMENT ON COLUMN analytics.churn_events.account_id IS 'Foreign key referencing accounts table.';
COMMENT ON COLUMN analytics.churn_events.churn_date IS 'Effective cancellation date.';
COMMENT ON COLUMN analytics.churn_events.reason_code IS 'Primary categorised churn driver (e.g., pricing, support, budget, missing_features, competitor).';
COMMENT ON COLUMN analytics.churn_events.refund_amount_usd IS 'Monetary refund issued upon cancellation in USD.';
COMMENT ON COLUMN analytics.churn_events.preceding_upgrade_flag IS 'Boolean flag indicating if account upgraded prior to churn.';
COMMENT ON COLUMN analytics.churn_events.preceding_downgrade_flag IS 'Boolean flag indicating if account downgraded prior to churn.';
COMMENT ON COLUMN analytics.churn_events.is_reactivation IS 'Boolean flag indicating if cancellation was subsequently reactivated.';
COMMENT ON COLUMN analytics.churn_events.feedback_text IS 'Qualitative feedback comments captured during exit interview.';
