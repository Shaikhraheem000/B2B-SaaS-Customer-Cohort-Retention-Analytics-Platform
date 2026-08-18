# Portfolio Project Summary

## Project Title
**B2B SaaS Customer Cohort & Retention Analytics Platform**

## One-line Description
End-to-end data analytics platform analyzing customer retention, revenue performance, and churn drivers for a B2B SaaS company — spanning SQL, Python, statistical testing, and an interactive Power BI dashboard.

---

## Business Problem
A B2B SaaS company is losing customers within the first 6 months but lacks the analytical infrastructure to understand *why*. Leadership needs visibility into churn patterns, revenue concentration risks, product adoption gaps, and marketing efficiency to make data-driven retention and acquisition decisions.

---

## Tools & Technologies
| Category | Tools |
|----------|-------|
| Data Analysis | Python (Pandas, NumPy, SciPy) |
| Visualization | Matplotlib, Seaborn, Power BI |
| Database | PostgreSQL |
| BI & Reporting | Power BI, DAX, Power Query |
| Version Control | Git, GitHub |

---

## Key Analytics Performed
- **Customer Segmentation:** RFM (Recency, Frequency, Monetary) descriptive segmentation identifying Champions, At Risk, and Lost accounts
- **Revenue Analysis:** MRR/ARR decomposition by plan tier, industry, and customer segment
- **Churn Analysis:** Root cause analysis across 5 churn reason codes with MRR impact quantification
- **Cohort Analysis:** Observed cumulative churn rates by signup cohort
- **Statistical Testing:** Mann-Whitney U and Chi-Square hypothesis tests validating churn associations
- **Marketing Efficiency:** Cost per Conversion analysis across channels and campaign types
- **SQL Analytics:** 200+ queries across 9 progressive SQL files (basic → advanced window functions → RFM)

---

## Dashboard
7-page interactive Power BI dashboard:
1. Executive Overview — KPI scorecards, risk hitlist, MRR trends
2. Revenue Analytics — MRR decomposition, Top 20 customers
3. Customer Retention — Churn reasons, lost MRR, event log
4. Product & Support — Feature adoption, support escalation
5. Marketing Analytics — CPA by channel, campaign performance
6. Segmentation & RFM — RFM scatter matrix, customer directory
7. Customer 360 — Drill-through individual account profiles

---

## Key Findings
- **22% observed churn rate** across 500 customers (110 churned)
- **$11.3M total MRR** with Enterprise segment contributing the largest share
- **114 "At Risk" accounts** identified through RFM segmentation (highest segment count)
- **$11.01 average Cost per Conversion** across 40 marketing campaigns
- **4.75% support escalation rate** with 3.98 average CSAT
- **No statistically significant churn predictors** found (all p > 0.05) — a legitimate finding that underscores the complexity of churn behavior in this dataset

---

## Business Impact
This platform enables:
- **Customer Success teams** to prioritize outreach using the RFM "At Risk" segment and the Executive Overview risk hitlist
- **Finance teams** to monitor MRR concentration risk and churned revenue impact
- **Product teams** to identify feature adoption gaps correlated with support burden
- **Marketing teams** to optimize channel spend based on Cost per Conversion efficiency
- **Executives** to make data-informed retention and acquisition investment decisions

---

## What This Project Demonstrates
- End-to-end data pipeline design (raw → clean → database → analytics → dashboard)
- Professional star-schema data modeling in Power BI
- Advanced DAX authoring (CROSSFILTER, interval-based historical subscription logic, iterator functions)
- SQL proficiency across 200+ analytical queries including window functions, CTEs, and RFM quintile scoring
- Statistical rigor — honest reporting of non-significant results rather than fabricating claims
- Business communication — translating data findings into actionable executive recommendations
- Data quality discipline — 100% validation health score, documented limitations, and analytical reconciliation

---

*Author: Shaikh Raheem*
