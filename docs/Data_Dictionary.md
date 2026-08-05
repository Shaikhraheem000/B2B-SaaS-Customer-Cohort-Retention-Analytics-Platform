# Data Dictionary

# Project Title

**B2B SaaS Customer Cohort & Retention Analytics Platform**

---

# Document Information

| Item | Details |
|------|---------|
| Version | 1.0 |
| Status | Draft |
| Project Type | Data Analytics Portfolio Project |
| Domain | B2B Software as a Service (SaaS) |
| Author | Shaikh Raheem |
| Last Updated | August 2026 |

---

# Purpose

This document provides a detailed description of every table and column used in the project. It serves as the central reference for database design, SQL analysis, Python EDA, and Power BI dashboard development.

---

# Database Overview

| Table Name | Description |
|------------|-------------|
| accounts | Customer account information |
| subscriptions | Subscription and billing information |
| feature_usage | Product feature usage events |
| support_tickets | Customer support interactions |
| churn_events | Customer churn records |
| marketing_campaigns* | Marketing campaign information (to be created) |

> **Note:** `marketing_campaigns` is not part of the original dataset and will be added during the project.

---

# 1. accounts

## Description

Stores customer account information and company-level details.

**Primary Key:** `account_id`

| Column | Data Type | Description | Example |
|---------|-----------|-------------|---------|
| account_id | VARCHAR | Unique customer account identifier | ACC0001 |
| account_name | VARCHAR | Company name | TechNova Ltd |
| industry | VARCHAR | Customer industry | EdTech |
| country | VARCHAR | Customer country (ISO-2) | IN |
| signup_date | DATE | Account registration date | 2024-01-15 |
| referral_source | VARCHAR | Customer acquisition source | Organic |
| plan_tier | VARCHAR | Initial subscription plan | Pro |
| seats | INTEGER | Licensed user seats | 25 |
| is_trial | BOOLEAN | Trial account indicator | TRUE |
| churn_flag | BOOLEAN | Indicates whether the account has churned | FALSE |

---

# 2. subscriptions

## Description

Contains subscription history and recurring revenue information.

**Primary Key:** `subscription_id`

**Foreign Key:** `account_id → accounts.account_id`

| Column | Data Type | Description | Example |
|---------|-----------|-------------|---------|
| subscription_id | VARCHAR | Unique subscription identifier | SUB0105 |
| account_id | VARCHAR | Customer account | ACC0001 |
| start_date | DATE | Subscription start date | 2024-02-01 |
| end_date | DATE | Subscription end date | NULL |
| plan_tier | VARCHAR | Active subscription plan | Enterprise |
| seats | INTEGER | Number of licensed seats | 100 |
| mrr_amount | DECIMAL | Monthly Recurring Revenue | 1500.00 |
| arr_amount | DECIMAL | Annual Recurring Revenue | 18000.00 |
| is_trial | BOOLEAN | Trial subscription | FALSE |
| upgrade_flag | BOOLEAN | Indicates upgrade | TRUE |
| downgrade_flag | BOOLEAN | Indicates downgrade | FALSE |
| churn_flag | BOOLEAN | Subscription ended | FALSE |
| billing_frequency | VARCHAR | Monthly or Annual | Monthly |
| auto_renew_flag | BOOLEAN | Auto renewal enabled | TRUE |

---

# 3. feature_usage

## Description

Captures customer interaction with SaaS product features.

**Primary Key:** `usage_id`

**Foreign Key:** `subscription_id → subscriptions.subscription_id`

| Column | Data Type | Description | Example |
|---------|-----------|-------------|---------|
| usage_id | VARCHAR | Unique usage event ID | USE00045 |
| subscription_id | VARCHAR | Subscription identifier | SUB0105 |
| usage_date | DATE | Date of usage | 2024-05-10 |
| feature_name | VARCHAR | Product feature name | Dashboard |
| usage_count | INTEGER | Number of times feature used | 12 |
| usage_duration_secs | INTEGER | Total usage duration | 540 |
| error_count | INTEGER | Errors encountered | 1 |
| is_beta_feature | BOOLEAN | Beta feature indicator | FALSE |

---

# 4. support_tickets

## Description

Stores customer support ticket information.

**Primary Key:** `ticket_id`

**Foreign Key:** `account_id → accounts.account_id`

| Column | Data Type | Description | Example |
|---------|-----------|-------------|---------|
| ticket_id | VARCHAR | Unique ticket ID | TKT1054 |
| account_id | VARCHAR | Customer account | ACC0001 |
| submitted_at | TIMESTAMP | Ticket creation time | 2024-06-01 09:30 |
| closed_at | TIMESTAMP | Ticket resolution time | 2024-06-01 14:10 |
| resolution_time_hours | DECIMAL | Resolution duration | 4.7 |
| priority | VARCHAR | Ticket priority | High |
| first_response_time_minutes | INTEGER | Initial response time | 15 |
| satisfaction_score | INTEGER | Customer rating (1–5) | 5 |
| escalation_flag | BOOLEAN | Escalated ticket | FALSE |

---

# 5. churn_events

## Description

Contains customer churn records.

**Primary Key:** `churn_event_id`

**Foreign Key:** `account_id → accounts.account_id`

| Column | Data Type | Description | Example |
|---------|-----------|-------------|---------|
| churn_event_id | VARCHAR | Unique churn event | CHR020 |
| account_id | VARCHAR | Customer account | ACC0001 |
| churn_date | DATE | Date customer churned | 2024-08-01 |
| reason_code | VARCHAR | Churn reason | Pricing |
| refund_amount_usd | DECIMAL | Refund issued | 150.00 |
| preceding_upgrade_flag | BOOLEAN | Upgraded before churn | FALSE |
| preceding_downgrade_flag | BOOLEAN | Downgraded before churn | TRUE |
| is_reactivation | BOOLEAN | Previously reactivated | FALSE |
| feedback_text | TEXT | Customer feedback | "Too expensive" |

---

# 6. marketing_campaigns (Project Extension)

## Description

Stores marketing campaign information for customer acquisition analysis.

**Primary Key:** `campaign_id`

| Column | Data Type | Description | Example |
|---------|-----------|-------------|---------|
| campaign_id | INTEGER | Campaign identifier | 101 |
| campaign_name | VARCHAR | Campaign name | Summer Launch |
| channel | VARCHAR | Marketing channel | Google Ads |
| campaign_type | VARCHAR | Campaign type | Search |
| start_date | DATE | Campaign start date | 2024-01-01 |
| end_date | DATE | Campaign end date | 2024-03-31 |
| budget_usd | DECIMAL | Campaign budget | 12000 |
| impressions | INTEGER | Ad impressions | 250000 |
| clicks | INTEGER | Ad clicks | 12000 |
| conversions | INTEGER | Customers acquired | 320 |

---

# Entity Relationships

| Parent Table | Child Table | Relationship |
|--------------|-------------|--------------|
| accounts | subscriptions | One-to-Many |
| accounts | support_tickets | One-to-Many |
| accounts | churn_events | One-to-Many |
| subscriptions | feature_usage | One-to-Many |
| marketing_campaigns | accounts* | One-to-Many (planned extension) |

---

# Data Quality Considerations

During data preparation, the following checks will be performed:

- Missing value detection
- Duplicate record identification
- Invalid date validation
- Foreign key integrity checks
- Data type validation
- Null value handling
- Revenue consistency checks
- Outlier detection
- Subscription lifecycle validation

---

# Business Metrics Supported

The dataset supports the calculation of:

## Customer Metrics

- Total Customers
- Active Customers
- Trial Customers
- Customer Growth Rate

## Revenue Metrics

- Monthly Recurring Revenue (MRR)
- Annual Recurring Revenue (ARR)
- Average Revenue Per User (ARPU)
- Customer Lifetime Value (LTV)

## Subscription Metrics

- Upgrade Rate
- Downgrade Rate
- Renewal Rate

## Product Metrics

- Feature Adoption Rate
- Beta Feature Usage
- Average Usage Duration

## Support Metrics

- Average Resolution Time
- Customer Satisfaction Score
- Escalation Rate

## Retention Metrics

- Churn Rate
- Retention Rate
- Cohort Retention
- RFM Segmentation

## Marketing Metrics (Project Extension)

- Customer Acquisition Cost (CAC)
- Return on Ad Spend (ROAS)
- Cost Per Acquisition (CPA)
- Campaign Conversion Rate

---

# Document Version History

| Version | Date | Changes |
|----------|------|----------|
| 1.0 | August 2026 | Initial data dictionary created |