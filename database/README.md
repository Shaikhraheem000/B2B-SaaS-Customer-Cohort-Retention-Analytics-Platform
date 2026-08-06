# PostgreSQL Database Architecture & Administration
## B2B SaaS Customer Cohort & Retention Analytics Platform

---

## 1. Overview & Architecture

This repository contains the production-grade PostgreSQL database design for **b2b_saas_analytics**. The architecture is structured under a dedicated schema (`analytics`) and follows strict Relational Database Management System (RDBMS) best practices, ANSI SQL standards, and PostgreSQL administration guidelines.

The database models a real-world B2B Software-as-a-Service (SaaS) business lifecycle, tracking accounts, marketing acquisition channels, subscriptions, product usage telemetry, customer support tickets, and churn event dynamics.

---

## 2. Directory Structure

```text
database/
├── README.md           # Database architecture documentation & setup guide
├── schema.sql          # Database initialization, schema creation & search path
├── tables.sql          # DDL table creation with PostgreSQL data types & comments
├── constraints.sql     # PK, FK, CHECK constraints, and domain validation rules
├── indexes.sql         # B-tree performance indexing for high-frequency queries
├── views.sql           # Business intelligence analytical reporting views
└── validation.sql      # Data quality audit, integrity & constraint validation queries
```

---

## 3. Database Specification

* **Database Name**: `b2b_saas_analytics`
* **Schema Name**: `analytics`
* **Target Engine**: PostgreSQL 13+
* **Encoding**: UTF-8
* **Naming Standard**: Lowercase `snake_case` for all identifiers (tables, columns, constraints, indexes, views).

---

## 4. Entity-Relationship (ER) Schema Overview

```text
  [ marketing_campaigns ]
             │ (1:N)
             ▼
        [ accounts ] ◄──────────────────────────────┐
        │        │                                  │
  (1:N) │        │ (1:N)                            │ (1:N)
        ▼        ▼                                  │
[ subscriptions ]  [ support_tickets ]      [ churn_events ]
        │
  (1:N) │
        ▼
[ feature_usage ]
```

### Table Definitions & Summary

| Table Name | Entity Description | Primary Key | Key Foreign Keys |
| :--- | :--- | :--- | :--- |
| **`marketing_campaigns`** | Acquisition campaign spend, impressions & conversion tracking. | `campaign_id` | - |
| **`accounts`** | Master customer accounts profile & acquisition metadata. | `account_id` | `campaign_id` |
| **`subscriptions`** | Contract billing records, plan tiers, MRR/ARR, & renewals. | `subscription_id` | `account_id` |
| **`feature_usage`** | Daily product telemetry, feature clicks, & error logs. | `usage_id` | `subscription_id` |
| **`support_tickets`** | Customer support interactions, SLA resolution time, & CSAT. | `ticket_id` | `account_id` |
| **`churn_events`** | Account cancellation events, reasons, & refund transactions. | `churn_event_id` | `account_id` |

---

## 5. Execution Order & Setup Instructions

To deploy the complete database structure in PostgreSQL, run the SQL scripts in the following exact sequential order:

```bash
# Step 1: Connect to PostgreSQL server and initialize database & schema
psql -U postgres -d postgres -f database/schema.sql

# Step 2: Create base tables and table/column comments
psql -U postgres -d b2b_saas_analytics -f database/tables.sql

# Step 3: Apply primary keys, foreign keys, and CHECK constraints
psql -U postgres -d b2b_saas_analytics -f database/constraints.sql

# Step 4: Create performance indexes for joins and aggregations
psql -U postgres -d b2b_saas_analytics -f database/indexes.sql

# Step 5: Build reporting analytical views
psql -U postgres -d b2b_saas_analytics -f database/views.sql

# Step 6: Execute data quality audit & integrity verification suite
psql -U postgres -d b2b_saas_analytics -f database/validation.sql
```

Alternatively, you can run all scripts in a single transaction block via psql:

```sql
\i database/schema.sql
\i database/tables.sql
\i database/constraints.sql
\i database/indexes.sql
\i database/views.sql
\i database/validation.sql
```

---

## 6. Analytical Views & Business Value

The database includes pre-built analytical views in `views.sql` designed for fast executive reporting and BI dashboard integration:

* **`vw_active_customers`**: Real-time roster of active accounts with current plan tier, total seat allocation, MRR, and acquisition campaign metadata.
* **`vw_monthly_revenue`**: Monthly recurring revenue (MRR/ARR) aggregation, average revenue per account (ARPA), and trial conversions.
* **`vw_customer_revenue`**: Account-level lifetime financial value, cumulative MRR contribution, and current subscription status.
* **`vw_churn_summary`**: Categorized breakdown of cancellations by churn reason code, financial refund amounts, and plan tier churn distribution.
* **`vw_support_summary`**: Customer support performance metrics including average resolution time (hours), CSAT satisfaction scores, and escalation rates.
* **`vw_feature_adoption`**: Aggregated product telemetry tracking feature usage counts, total engagement duration, and error rates across subscription plans.

---

## 7. Data Quality & Validation Framework

The `validation.sql` suite provides automated checks to detect and report data anomalies:
1. **Primary Key Uniqueness Audit**: Ensures no duplicate identifiers exist.
2. **Foreign Key Referential Integrity**: Identifies orphan records in child tables.
3. **Data Completeness Verification**: Checks for missing required values.
4. **Financial Range Sanity**: Guarantees non-negative MRR, ARR, budgets, and refunds.
5. **Categorical Enumeration Audit**: Validates allowed values for plan tiers, billing frequencies, and support priorities.
6. **Chronological Consistency**: Verifies subscription and ticket end dates follow start dates.
