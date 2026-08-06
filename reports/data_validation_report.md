# Data Validation & Database Health Report
## B2B SaaS Customer Cohort & Retention Analytics Platform

---

## 1. Executive Audit Summary

This document presents the technical data quality audit and referential integrity report for the **b2b_saas_analytics** database following Phase 2 database preparation.

All datasets (`marketing_campaigns`, `accounts`, `subscriptions`, `feature_usage`, `support_tickets`, `churn_events`) have been generated, linked, and verified.

* **Database Health Score**: **100% (Pass)**
* **Total Records Ingested**: **33,140 rows**
* **Referential Integrity Score**: **100% (Zero orphaned records)**
* **Phase Status**: **Phase 2 Complete — Ready for Phase 3 SQL Analytics**

---

## 2. Ingestion Summary by Table

| Table Name | Entity Domain | Primary Key | Total Rows Ingested | File Source Path |
| :--- | :--- | :--- | :--- | :--- |
| **`marketing_campaigns`** | Acquisition Channels | `campaign_id` | **40** | `data/processed/marketing_campaigns.csv` |
| **`accounts`** | Customer Accounts | `account_id` | **500** | `data/processed/accounts.csv` |
| **`subscriptions`** | Subscription Contracts | `subscription_id` | **5,000** | `data/processed/subscriptions.csv` |
| **`feature_usage`** | Product Telemetry | `usage_id` | **25,000** | `data/processed/feature_usage.csv` |
| **`support_tickets`** | Support Operations | `ticket_id` | **2,000** | `data/processed/support_tickets.csv` |
| **`churn_events`** | Account Cancellations | `churn_event_id` | **600** | `data/processed/churn_events.csv` |
| **Total Database** | - | - | **33,140** | - |

---

## 3. Data Integrity & Validation Audit

### 3.1 Primary Key Uniqueness Audit
* **Method**: Executed `GROUP BY {primary_key} HAVING COUNT(*) > 1` on all 6 tables.
* **Findings**: **0 duplicate keys detected**. Primary keys across all entities maintain 100% uniqueness.

### 3.2 Foreign Key Referential Integrity Check
* **Method**: Executed `LEFT JOIN` queries between child and parent tables filtering for `parent.id IS NULL`.
  * `accounts.campaign_id` $\rightarrow$ `marketing_campaigns.campaign_id`: **0 broken FKs**
  * `subscriptions.account_id` $\rightarrow$ `accounts.account_id`: **0 broken FKs**
  * `feature_usage.subscription_id` $\rightarrow$ `subscriptions.subscription_id`: **0 broken FKs**
  * `support_tickets.account_id` $\rightarrow$ `accounts.account_id`: **0 broken FKs**
  * `churn_events.account_id` $\rightarrow$ `accounts.account_id`: **0 broken FKs**
* **Findings**: **100% referential integrity verified**. No orphaned child records exist.

### 3.3 Data Completeness & Missing Value Analysis
* **Mandatory Field Audit**: Checked for unexpected `NULL` values in mandatory fields (`account_name`, `signup_date`, `plan_tier`, `mrr_amount`, `usage_date`, `submitted_at`, `churn_date`).
* **Findings**: **0 missing values** on required attributes. Optional fields (e.g. `closed_at`, `end_date`, `satisfaction_score`, `feedback_text`) contain valid nulls corresponding to active status or pending ratings.

---

## 4. Financial Range & Domain Business Rule Checks

| Metric / Field Checked | Target Validation Rule | Violation Count | Status |
| :--- | :--- | :---: | :---: |
| **`subscriptions.mrr_amount`** | `mrr_amount >= 0` | **0** | PASS |
| **`marketing_campaigns.budget_usd`** | `budget_usd > 0` | **0** | PASS |
| **`churn_events.refund_amount_usd`** | `refund_amount_usd >= 0` | **0** | PASS |
| **`billing_frequency`** | `LOWER(billing_frequency) IN ('monthly', 'annual')` | **0** | PASS |
| **`priority`** | `LOWER(priority) IN ('low', 'medium', 'high', 'urgent')` | **0** | PASS |
| **`satisfaction_score`** | `satisfaction_score BETWEEN 1.0 AND 5.0` | **0** | PASS |

---

## 5. Marketing Campaign Assignment Validation

* **Total Accounts Analyzed**: 500
* **Accounts Linked to Campaign**: 500 (100.0% coverage)
* **Distinct Campaigns Referenced**: 40 distinct campaign IDs
* **Date Proximity Rule Validation**: Accounts are assigned to campaigns active during or prior to their `signup_date`.
* **Channel Distribution Overview**:
  * Google Ads & LinkedIn: ~35% of accounts
  * Referral & Partner Channels: ~25% of accounts
  * Organic Search, Email, Webinar & YouTube: ~40% of accounts

---

## 6. Overall Database Health Verdict

> [!IMPORTANT]
> **VERDICT: PASSED (READY FOR PHASE 3)**
> 
> The database schema, data pipelines, campaign extensions, and dataset integrity checks have met all enterprise quality criteria. The platform is ready for Phase 3 SQL Analytics execution and advanced cohort retention reporting.
