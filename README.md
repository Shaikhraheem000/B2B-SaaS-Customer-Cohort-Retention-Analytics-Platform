# B2B SaaS Customer Cohort & Retention Analytics Platform

An end-to-end data analytics project analyzing customer retention, revenue performance, churn drivers, product adoption, and marketing efficiency for a B2B SaaS company — from raw data through SQL analytics, Python EDA, statistical testing, and an interactive Power BI dashboard.

**Author:** Shaikh Raheem

---

## Business Problem

A B2B SaaS company is experiencing early-stage customer churn within the first 6 months of onboarding. Leadership lacks visibility into:
- Which customer segments drive the most revenue
- Why customers are churning and which reasons dominate
- How product feature adoption correlates with retention
- Whether marketing spend is efficiently converting leads
- Which accounts need immediate Customer Success intervention

This project builds a centralized analytics platform to answer these questions with data.

---

## Objectives

- Design a normalized PostgreSQL database for SaaS customer analytics
- Perform comprehensive SQL analysis (200+ queries across 9 analytical layers)
- Conduct Python EDA across 13 Jupyter notebooks covering all business domains
- Validate findings with statistical hypothesis testing
- Implement RFM (Recency, Frequency, Monetary) customer segmentation
- Build a 7-page interactive Power BI dashboard for executive decision-making

---

## Key Business Questions

- What is the overall customer churn rate, and how does it vary by plan tier, industry, and segment?
- Which churn reasons account for the most lost MRR?
- How does product feature adoption differ across customer segments?
- What is the Cost per Conversion across marketing channels?
- Which customers are "Champions" vs "At Risk" based on RFM scoring?

---

## Key Findings

| KPI | Value |
|-----|-------|
| Total Customers | 500 |
| Active Customers | 390 |
| Churned Customers | 110 |
| Observed Churn Rate | 22.0% |
| Total MRR | $11.3M |
| Total Active ARR | $121.9M |
| Average CSAT | 3.98 / 5.0 |
| Support Escalation Rate | 4.75% |
| Total Marketing Conversions | 142,798 |
| Cost per Conversion | $11.01 |
| RFM: Champions | 81 accounts |
| RFM: At Risk | 114 accounts |

> **Statistical Note:** Mann-Whitney U and Chi-Square tests found no statistically significant associations (p > 0.05) between any tested variable and churn in this dataset. All business insights use "observed association" language accordingly.

---

## Dashboard Preview

The Power BI dashboard contains 7 pages (6 main + 1 drill-through):

| Page | Description |
|------|-------------|
| 01. Executive Overview | KPI scorecards, historical MRR/customer trends, risk hitlist |
| 02. Revenue Analytics | MRR by plan tier, industry, and segment; Top 20 customers |
| 03. Customer Retention | Churn reasons, churned MRR by plan/segment, churn event log |
| 04. Product & Support | Feature adoption, support volume trends, ticket priority |
| 05. Marketing Analytics | Conversions vs clicks by channel, CPA by campaign type |
| 06. Segmentation & RFM | RFM scatter matrix, MRR by segment, customer directory |
| 07. Customer 360 | Drill-through detail page for individual account analysis |

> Screenshots are available in [`dashboards/Screenshots/`](dashboards/Screenshots/).

---

## Data Architecture

```
Raw CSV Data (6 files, 33,140 rows)
    │
    ▼
Python Data Cleaning (Pandas)
    │
    ▼
PostgreSQL Database (analytics schema, 6 tables)
    │
    ▼
SQL Analytics (9 files, 200+ queries)
    │
    ▼
Python EDA & Statistics (13 Jupyter notebooks)
    │
    ▼
Power BI Dashboard (7 pages, 30+ DAX measures)
```

---

## Data Model

Star-schema-oriented Power BI data model:

| Dimension Tables | Fact Tables |
|-----------------|-------------|
| `Dim_Account` (500 rows) | `Fact_Subscriptions` (5,000 rows) |
| `Dim_Calendar` (generated) | `Fact_FeatureUsage` (25,000 rows) |
| `Dim_Campaign` (40 rows) | `Fact_SupportTickets` (2,000 rows) |
| | `Fact_ChurnEvents` (600 rows) |

All relationships use 1-to-Many cardinality with single-direction cross-filtering from Dimension to Fact tables.

---

## SQL Analysis

9 progressive SQL files demonstrating:

| File | Queries | Techniques |
|------|---------|------------|
| `01_database_verification.sql` | Integrity suite | PK/FK validation, data quality checks |
| `02_basic_analysis.sql` | 30 | Foundational business queries |
| `03_intermediate_analysis.sql` | 38 | CTEs, subqueries, EXISTS, conditional aggregates |
| `04_advanced_analysis.sql` | 36 | Window functions, LAG/LEAD, running totals |
| `05_cohort_analysis.sql` | 27 | Cohort retention, NRR%, GRR% |
| `06_rfm_analysis.sql` | 29 | NTILE quintiles, 10 behavioral segments |
| `07_analytics_views.sql` | 12 | Semantic BI views |
| `08_business_insights.sql` | 23 | Executive findings & recommendations |
| `09_dashboard_queries.sql` | 45 | Power BI visual queries |

---

## Python Analysis

| Notebook | Domain |
|----------|--------|
| `01_data_loading.ipynb` | Data ingestion & profiling |
| `02_data_cleaning.ipynb` | 17-step cleaning workflow |
| `03_exploratory_data_analysis.ipynb` | Cross-domain EDA |
| `04_customer_analytics.ipynb` | Customer segmentation & distribution |
| `05_revenue_analytics.ipynb` | MRR/ARR analysis |
| `06_product_analytics.ipynb` | Feature adoption & usage |
| `07_support_analytics.ipynb` | Ticket analysis & CSAT |
| `08_marketing_analytics.ipynb` | Campaign performance & CPA |
| `09_churn_analytics.ipynb` | Churn drivers & patterns |
| `10_cohort_visualization.ipynb` | Observed cumulative cohort churn |
| `11_rfm_visualization.ipynb` | RFM descriptive segmentation |
| `12_statistical_analysis.ipynb` | Hypothesis testing (Mann-Whitney U, Chi-Square) |
| `13_executive_summary.ipynb` | KPI scorecard & business assessment |

---

## Technology Stack

| Category | Tools |
|----------|-------|
| **Language** | Python 3.x |
| **Data Manipulation** | Pandas, NumPy |
| **Visualization** | Matplotlib, Seaborn |
| **Statistics** | SciPy |
| **Database** | PostgreSQL |
| **BI & Dashboards** | Power BI, DAX, Power Query (M) |
| **Version Control** | Git, GitHub |
| **Environment** | Jupyter Notebooks |

---

## Repository Structure

```
B2B-SaaS-Customer-Cohort-Retention-Analytics-Platform/
│
├── data/
│   ├── raw/              # Original CSV files (6 tables)
│   ├── cleaned/          # Cleaned datasets
│   └── processed/        # Feature-engineered datasets
│
├── database/             # PostgreSQL DDL, constraints, views, validation
├── sql/                  # 9 analytical SQL files (200+ queries)
├── notebooks/            # 13 Jupyter notebooks
├── dashboards/           # Power BI .pbix file + screenshots
├── docs/                 # BRD, Data Dictionary, KPI definitions, ER diagram
├── reports/              # Validation report, final project report
├── figures/              # Portfolio-quality analytical figures
├── exports/              # Summary CSV exports
├── scripts/              # Data generation utilities
│
├── .gitignore
├── README.md
└── requirements.txt
```

---

## How to Run

### Prerequisites
- Python 3.8+
- PostgreSQL 13+ (for database layer)
- Power BI Desktop (for dashboard)

### Setup
```bash
# Clone the repository
git clone https://github.com/your-username/B2B-SaaS-Customer-Cohort-Retention-Analytics-Platform.git

# Install Python dependencies
pip install -r requirements.txt

# Run notebooks in order (01 → 13)
jupyter notebook notebooks/
```

### Database Setup
```bash
# Execute SQL files in order
psql -f database/schema.sql
psql -f database/tables.sql
psql -f database/constraints.sql
psql -f database/indexes.sql
psql -f database/import_data.sql
psql -f database/views.sql
psql -f database/validation.sql
```

### Power BI
Open `dashboards/B2b Saas Platform.pbix` in Power BI Desktop.

---

## Limitations

- **Synthetic Dataset:** Data is generated for portfolio demonstration purposes
- **No Monthly Snapshot Ledger:** Cohort analysis uses observed cumulative churn, not traditional monthly retention matrices
- **No Statistically Significant Churn Predictors:** All hypothesis tests returned p > 0.05
- **Marketing Attribution:** Dataset tracks campaign-level conversions, not individual customer acquisition cost (CAC)
- **No Real-Time Pipeline:** Static analytical workflow, not production ETL
- **Churn Events Grain:** 600 churn events for 110 customers (multiple reasons per customer) — addressed with allocated MRR measures

---

## Future Improvements

- Add monthly subscription snapshots to enable true cohort retention matrices and NRR%
- Implement predictive churn modeling (logistic regression, random forest)
- Build a real-time data pipeline with Apache Airflow or dbt
- Add customer health scoring using weighted engagement metrics
- Expand marketing data to support true CAC and LTV calculations
- Deploy dashboard to Power BI Service for web access

---

## Author

**Shaikh Raheem**
Data Analyst | SQL · Python · Power BI

---

*This project demonstrates end-to-end analytical capabilities from raw data through business insights, suitable for Senior Data Analyst and Business Intelligence Analyst positions.*
