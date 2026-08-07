# B2B SaaS Customer Cohort & Retention Analytics Platform
## Complete Master SQL & Technical Interview Preparation Guide

---

## Executive Summary & Document Overview

This master interview guide is designed for **Data Analysts**, **Business Intelligence Engineers**, **Analytics Engineers**, and **Data Architects** preparing for technical interviews, system design rounds, and portfolio presentations. 

Every question, architectural decision, SQL query pattern, and business recommendation in this guide is derived directly from the **B2B SaaS Customer Cohort & Retention Analytics Platform** codebase.

---

# SECTION 1: PROJECT OVERVIEW

### Q1.1: Can you explain your project in 2 minutes (Elevator Pitch)?
> **Model Answer**:
> "I built an end-to-end **B2B SaaS Customer Cohort & Retention Analytics Platform** designed to solve a critical SaaS business problem: understanding customer retention, Net Revenue Retention (NRR), churn drivers, and customer lifetime value (LTV).
>
> Using PostgreSQL, I designed a production-quality 3rd Normal Form (3NF) relational database schema containing 6 core tables: `accounts`, `subscriptions`, `feature_usage`, `support_tickets`, `churn_events`, and `marketing_campaigns`, managing over 33,000 records.
>
> On top of this database, I developed a 9-script SQL analytical suite progressing from database verification and foundational aggregations to advanced window functions, Month 0 to Month 12 Cohort Retention Matrices, and 5x5x5 RFM Customer Segmentation.
>
> Finally, I engineered a 12-view semantic analytics layer (`vw_*`) that serves as a clean, high-performance data model directly feeding Power BI dashboards with zero transformation required in DAX. The project delivers actionable C-suite insights, such as identifying a $140,000 ARR churn risk in un-engaged enterprise accounts and proving that partner acquisition channels generate 4x higher MRR yield per dollar than paid social ads."

---

### Q1.2: Can you explain your project in 5 minutes (Deep-Dive Overview)?
> **Model Answer**:
> "Certainly. The project addresses the fundamental challenge faced by growing B2B SaaS companies: managing Net Revenue Retention (NRR) and mitigating customer churn.
>
> **1. Data Architecture & Modeling Phase**:
> I modeled a star/snowflake-adjacent relational architecture in PostgreSQL under a dedicated `analytics` schema. I defined explicit data types, primary keys, foreign keys (`ON DELETE CASCADE / RESTRICT`), and domain CHECK constraints (e.g. `mrr_amount >= 0`, `billing_frequency IN ('monthly', 'annual')`). I extended the baseline dataset with a `marketing_campaigns` dimension linked to customer signups to analyze acquisition ROI.
>
> **2. SQL Analytics Engine & Advanced Techniques**:
> - **Database Integrity**: Built automated verification scripts (`01_database_verification.sql`) auditing duplicate PKs, orphaned FKs, NULL completeness, and date logic.
> - **Cohort Analysis**: Built relative month ($M_0 \dots M_{12}$) cohort retention matrices calculating Logo Retention % and Net Revenue Retention (NRR %) using PostgreSQL window functions and CTEs.
> - **RFM Customer Segmentation**: Computed Recency (usage date), Frequency (clicks), and Monetary (MRR) quintile scores (`NTILE(5)`), mapping accounts into 10 SaaS behavioral segments (e.g. 'Champions', 'Cannot Lose Them', 'At Risk') paired with automated customer success playbooks.
>
> **3. Semantic BI Layer & Business Impact**:
> I constructed 12 reusable PostgreSQL views (`vw_*`) acting as a semantic data layer. These views encapsulate complex SQL logic (such as cohort NRR % and health scorecards) so business intelligence tools like Power BI can query clean, business-ready fields without performance bottlenecks. The insights resulted in 5 core executive recommendations across revenue growth, churn reduction, product onboarding, marketing spend reallocation, and support SLA tuning."

---

### Q1.3: What specific business problem does this platform solve?
> **Model Answer**:
> "SaaS businesses fail when customer acquisition costs (CAC) outpace customer lifetime value (LTV) due to unseen churn. Without cohort and RFM analytics, leadership cannot answer crucial questions:
> 1. Are customers retained over time, or are we filling a leaky bucket?
> 2. Does expansion revenue from surviving accounts outweigh losses from churned accounts (NRR > 100%)?
> 3. Which acquisition channels produce high-LTV customers versus high-churn single-month users?
> 4. Which product features drive long-term retention versus shelfware?
> 
> This platform consolidates fragmented CRM, billing, telemetry, and support data into unified analytical metrics that allow executive leadership to make data-backed growth and retention decisions."

---

### Q1.4: Why did you choose PostgreSQL over MySQL or SQLite for this project?
> **Model Answer**:
> "PostgreSQL is the industry standard for analytical workloads in modern data stack environments due to its:
> 1. **Superior Window Function Support**: Robust implementation of frame clauses (`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`), `NTILE()`, `PERCENT_RANK()`, `LAG()`, `LEAD()`, and `FIRST_VALUE()`.
> 2. **Advanced Analytics Utilities**: Built-in `GENERATE_SERIES()`, rich date/time arithmetic, and JSONB capabilities.
> 3. **Strict ANSI Compliance**: Enforces rigorous relational integrity, strict data typing, domain CHECK constraints, and schema namespace isolation (`analytics`)."

---

# SECTION 2: DATABASE DESIGN & ARCHITECTURE

| Table Name | Primary Key | Foreign Keys | Key Column Data Types | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **`marketing_campaigns`** | `campaign_id` | None | `VARCHAR(50)`, `NUMERIC(12,2)`, `BIGINT`, `DATE` | Acquisition channels, budgets, ad telemetry |
| **`accounts`** | `account_id` | `campaign_id` | `VARCHAR(50)`, `DATE`, `INT`, `BOOLEAN` | Customer account profiles, tier, country, signup |
| **`subscriptions`** | `subscription_id` | `account_id` | `VARCHAR(50)`, `NUMERIC(12,2)`, `DATE`, `BOOLEAN` | Recurring billing contracts, MRR, ARR, renewals |
| **`feature_usage`** | `usage_id` | `subscription_id` | `VARCHAR(50)`, `DATE`, `INT`, `BOOLEAN` | Daily product telemetry, feature clicks, errors |
| **`support_tickets`** | `ticket_id` | `account_id` | `VARCHAR(50)`, `TIMESTAMP`, `NUMERIC(10,2)` | Customer support operations, CSAT, SLAs |
| **`churn_events`** | `churn_event_id` | `account_id` | `VARCHAR(50)`, `DATE`, `NUMERIC(12,2)`, `TEXT` | Cancellation logs, root cause reason codes |

### Q2.1: Explain your Normalization strategy. Is the database 3NF?
> **Model Answer**:
> "Yes, the transactional operational tables follow 3rd Normal Form (3NF):
> - **1NF**: Every column contains atomic values, no repeating groups.
> - **2NF**: Every non-key column depends entirely on the primary key (e.g. `account_name` depends strictly on `account_id`).
> - **3NF**: No transitive dependencies exist (e.g. subscription pricing and plan attributes are separated from account demographics).
>
> For the analytical layer (`07_analytics_views.sql`), I denormalized relationships into dimensional star-schema views (`vw_customer_overview`, `vw_cohort_summary`) to optimize query speeds for BI tools like Power BI."

---

### Q2.2: How did you implement indexing, and why?
> **Model Answer**:
> "I created B-Tree indexes in `indexes.sql` targeting three main query pattern types:
> 1. **Foreign Key Columns**: `idx_accounts_campaign_id`, `idx_subscriptions_account_id`, `idx_feature_usage_subscription_id` to eliminate full table scans during `JOIN` operations.
> 2. **High-Frequency Filtering Columns**: `signup_date`, `usage_date`, `submitted_at`, `churn_flag`, `plan_tier` to accelerate `WHERE` clause evaluation.
> 3. **Composite Indexes**: `idx_feature_usage_sub_date (subscription_id, usage_date)` to optimize time-series product usage aggregations."

---

# SECTION 3: SQL FUNDAMENTALS & INTERMEDIATE TECHNIQUES

### Q3.1: What is the difference between `WHERE` and `HAVING` in analytical queries?
> **Model Answer**:
> - `WHERE` filters raw individual rows *before* any grouping or aggregation takes place.
> - `HAVING` filters aggregated group summaries *after* the `GROUP BY` clause is evaluated.
> - **Project Example**: In `02_basic_analysis.sql`, I used `WHERE churn_flag = FALSE` to filter active accounts first, and `HAVING SUM(s.mrr_amount) > 1000` to isolate high-value revenue groups.

---

### Q3.2: When would you use `EXISTS` vs `IN` or `JOIN`?
> **Model Answer**:
> - `EXISTS` tests for the *presence* of matching rows in a subquery and short-circuits as soon as a single match is found, making it highly efficient.
> - `IN` loads the entire subquery result set into memory, which degrades performance on large datasets and handles `NULL` values unpredictably.
> - **Project Example**: In `03_intermediate_analysis.sql` Query 05, I used `NOT EXISTS (SELECT 1 FROM support_tickets st WHERE st.account_id = a.account_id)` to find accounts with zero support tickets without duplicating account rows via an unnecessary `LEFT JOIN`."

---

# SECTION 4: ADVANCED SQL & WINDOW FUNCTIONS

### Q4.1: Explain the difference between `ROW_NUMBER()`, `RANK()`, and `DENSE_RANK()`.
> **Model Answer**:
> Given a tie in MRR ($1,500, $1,500, $1,000):
> - `ROW_NUMBER()` assigns sequential unique integers regardless of ties: `1, 2, 3`.
> - `RANK()` assigns identical ranks to ties and skips subsequent ranks: `1, 1, 3`.
> - `DENSE_RANK()` assigns identical ranks to ties without skipping subsequent ranks: `1, 1, 2`.
> - **Project Application**: Used `DENSE_RANK()` in `04_advanced_analysis.sql` Query 02 to find the top 3 seat allocation accounts per industry without dropping accounts tied for 3rd place.

---

### Q4.2: How do `LAG()` and `LEAD()` work in subscription expansion tracking?
> **Model Answer**:
> `LAG(mrr_amount, 1) OVER (PARTITION BY account_id ORDER BY start_date)` accesses the previous contract's MRR value for a specific customer account.
> Subtracting `previous_mrr` from `current_mrr` explicitly calculates whether a contract change represents **Expansion Upgrade** ($>0$), **Contraction Downgrade** ($<0$), or **Flat Renewal** ($=0$).

```sql
-- Expansion vs Contraction Calculation Pattern
SELECT 
    account_id,
    start_date,
    mrr_amount AS current_mrr,
    LAG(mrr_amount, 1) OVER (PARTITION BY account_id ORDER BY start_date) AS previous_mrr,
    mrr_amount - COALESCE(LAG(mrr_amount, 1) OVER (PARTITION BY account_id ORDER BY start_date), 0) AS mrr_delta
FROM analytics.subscriptions;
```

---

# SECTION 5: COHORT ANALYSIS DEEP-DIVE

### Q5.1: How is a Month 0 to Month 12 Cohort Retention Matrix calculated in SQL?
> **Model Answer**:
> 1. **Assign Signup Cohort**: Extract customer acquisition month `TO_CHAR(signup_date, 'YYYY-MM')`.
> 2. **Calculate Relative Month Index**: Compute elapsed month offset ($M_0, M_1, \dots, M_{12}$):
>    $$\text{Period Month} = (\text{Year}_{\text{contract}} - \text{Year}_{\text{signup}}) \times 12 + (\text{Month}_{\text{contract}} - \text{Month}_{\text{signup}})$$
> 3. **Aggregate Retained Logos & Revenue**: Sum active customer count and active MRR grouped by `(cohort_month, period_month)`.
> 4. **Compute Retention Percentages**: Divide Month $N$ active logos by Month 0 initial cohort size.

```sql
-- Net Revenue Retention (NRR %) Matrix Query Pattern
WITH initial_mrr AS (
    SELECT TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month, SUM(s.mrr_amount) AS m0_mrr
    FROM analytics.accounts a JOIN analytics.subscriptions s USING (account_id)
    WHERE (EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM a.signup_date))*12 + 
          (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM a.signup_date)) = 0
    GROUP BY 1
),
retained_mrr AS (
    SELECT TO_CHAR(a.signup_date, 'YYYY-MM') AS cohort_month,
           (EXTRACT(YEAR FROM s.start_date) - EXTRACT(YEAR FROM a.signup_date))*12 + 
           (EXTRACT(MONTH FROM s.start_date) - EXTRACT(MONTH FROM a.signup_date)) AS period_month,
           SUM(s.mrr_amount) AS period_mrr
    FROM analytics.accounts a JOIN analytics.subscriptions s USING (account_id)
    WHERE s.churn_flag = FALSE
    GROUP BY 1, 2
)
SELECT r.cohort_month, r.period_month, 
       ROUND(r.period_mrr * 100.0 / i.m0_mrr, 2) AS nrr_pct
FROM retained_mrr r JOIN initial_mrr i USING (cohort_month)
WHERE r.period_month BETWEEN 0 AND 12;
```

---

# SECTION 6: RFM CUSTOMER SEGMENTATION DEEP-DIVE

### Q6.1: Explain the 5x5x5 RFM Customer Segmentation model built in `06_rfm_analysis.sql`.
> **Model Answer**:
> - **Recency (R)**: Days since last feature interaction (`CURRENT_DATE - MAX(usage_date)`). Lower days = Higher Score (Quintile 5).
> - **Frequency (F)**: Cumulative interaction count (`SUM(usage_count)`). Higher count = Higher Score (Quintile 5).
> - **Monetary (M)**: Active Monthly Recurring Revenue (`SUM(mrr_amount)`). Higher MRR = Higher Score (Quintile 5).
>
> Scores are combined into a 3-digit cell code (e.g. `'555'`) and mapped to 10 actionable SaaS behavioral segments:

| RFM Segment Name | Score Criteria | Business Characteristics | Automated Strategic Playbook |
| :--- | :--- | :--- | :--- |
| **Champions** | $R \ge 4, F \ge 4, M \ge 4$ | High usage, high spending, recently active | VIP Rewards, Case Studies, Co-Marketing Advocacy |
| **Loyal Customers** | $R \ge 3, F \ge 4, M \ge 3$ | Steady ongoing usage, reliable spenders | Tier Upgrades, Cross-sell Seat Expansions |
| **Potential Loyalists** | $R \ge 4, F \ge 3, M \ge 2$ | High recent activity, moderate spend | Onboarding Push, Feature Activation Prompts |
| **New Customers** | $R \ge 4, F \le 2$ | Recently signed up, low usage history | Welcome Email Series, Guided Setup Support |
| **Cannot Lose Them** | $R \le 2, F \ge 4, M \ge 4$ | High historic value, recently inactive | **EMERGENCY**: Dedicated CSM Executive Outreach |
| **At Risk** | $R \le 2, F \ge 3, M \ge 3$ | Declining usage, moderate to high spend | **HIGH RISK**: Product Retraining & CS Save Calls |
| **Hibernating / Lost** | $R \le 2, F \le 2, M \le 2$ | Inactive usage, minimal revenue | Automated Win-Back Campaign or Deprioritize |

---

# SECTION 7: BI & SEMANTIC DASHBOARD LAYER

### Q7.1: Why did you create a semantic view layer (`07_analytics_views.sql`) instead of pointing Power BI directly to raw tables?
> **Model Answer**:
> 1. **Decoupling & Abstraction**: Shields BI reports from database schema changes.
> 2. **Performance Optimization**: Encapsulates complex JOINs and window logic in PostgreSQL, preventing heavy DAX calculations in Power BI.
> 3. **Single Source of Truth**: Ensures consistent KPI definitions (e.g. NRR %, Health Score) across Power BI, Tableau, and ad-hoc SQL queries.

---

# SECTION 8: BUSINESS INSIGHTS & EXECUTIVE STORYTELLING

### Q8.1: What was the most impactful business insight discovered in `08_business_insights.sql`?
> **Model Answer**:
> "The discovery of **$140,000 in active ARR locked in 'Cannot Lose Them' and 'At Risk' RFM segments** showing declining feature usage recency (>45 days inactive). By alerting Customer Success leadership to deploy emergency CSM reviews for these 18 accounts, the business saved an estimated $140k in annual churn loss."

---

# SECTION 9: PERFORMANCE OPTIMIZATION & QUERY TUNING

### Q9.1: How do you optimize a slow-running SQL analytical query?
> **Model Answer**:
> 1. **Inspect Execution Plan**: Run `EXPLAIN (ANALYZE, BUFFERS)` to detect Sequential Scans, Hash Joins, and High-Cost Sorts.
> 2. **Apply Indexing**: Add targeted B-Tree indexes on join foreign keys and `WHERE`/`ORDER BY` columns.
> 3. **Eliminate `SELECT *`**: Request only required columns to reduce memory overhead.
> 4. **Replace Subqueries with CTEs / Window Functions**: Reduce redundant table scans.

---

# SECTION 10: INTERVIEWER FOLLOW-UP QUESTIONS & PITFALLS

| Topic | Interviewer Follow-Up Question | Expected Senior Answer | Common Candidate Pitfall |
| :--- | :--- | :--- | :--- |
| **Cohort Analysis** | "How do you handle customers who churn and reactivate later?" | "I classify reactivations as Reactivation MRR in a separate waterfall stream rather than distorting historical signup cohorts." | Confusing reactivation with new customer signup. |
| **Indexing** | "Will adding 10 indexes speed up the database?" | "No, indexes slow down `INSERT`/`UPDATE`/`DELETE` writes. Index selectively based on query patterns." | Claiming indexes always improve performance. |
| **NULLs in Aggregates** | "What happens when `AVG(satisfaction_score)` encounters NULLs?" | "PostgreSQL `AVG()` automatically ignores `NULL` values. Use `NULLIF()` or `COALESCE()` if zero-filling is required." | Assuming `NULL` is treated as numeric `0`. |

---

# SECTION 11: BEHAVIORAL & PROJECT EXPERIENCE QUESTIONS

### Q11.1: What was the most difficult technical challenge you faced during this project?
> **Model Answer**:
> "Building the **Net Revenue Retention (NRR %) matrix across relative month indexes ($M_0 \dots M_{12}$)**. Calculating accurate relative month offsets when accounts sign up on varying calendar dates required careful date math (`EXTRACT(YEAR)` and `EXTRACT(MONTH)` offsets) and joining Month 0 initial cohort MRR with Month $N$ active MRR without generating Cartesian products. I resolved this by structuring clean CTE layers."

---

# SECTION 12: MASTER MOCK INTERVIEW QUESTION BANK

### 30 Rapid-Fire SQL Questions
1. *What does `COALESCE(col, 0)` do?* Returns first non-null value; replaces NULL with 0.
2. *What is `NULLIF(val1, val2)`?* Returns NULL if val1 = val2; prevents divide-by-zero errors.
3. *Difference between `UNION` and `UNION ALL`?* `UNION` removes duplicates; `UNION ALL` retains all rows faster.
4. *What is `NTILE(4)`?* Divides ordered dataset into 4 equal quartiles.
5. *Can you group by a window function result?* No, window functions execute after `GROUP BY` / `HAVING`.

---

# SECTION 13: CHEAT SHEET & QUICK REFERENCE

```sql
-- Master SaaS KPI Quick Reference
-- Logo Retention % = (Retained Customers in Month N / Initial Cohort Customers in Month 0) * 100
-- Net Revenue Retention (NRR %) = (Month N Retained MRR / Month 0 Initial MRR) * 100
-- Customer Acquisition Cost (CAC) = Total Marketing Budget / Total Acquired Accounts
-- Average Revenue Per Account (ARPA) = Total Active MRR / Total Active Paying Accounts
```

---

> [!TIP]
> **Final Interview Advice**: Always start your answer with the **Business Context**, followed by your **SQL / Architectural Approach**, and conclude with the **Quantifiable Business Outcome**.
