# Power BI Dashboard Guide — B2B SaaS Analytics Platform

## 1. Dashboard Objective
Provide executive-level visibility into customer health, revenue performance, churn risk, product adoption, marketing efficiency, and customer segmentation.

## 2. Data Model
The dashboard utilizes a star-schema-oriented data model connecting Dimension tables to Fact tables via 1-to-Many relationships with single-direction cross-filtering.

## 3. Dimension Tables
- **Dim_Account** (source: `accounts.csv`, PK: `account_id`) — includes derived Customer Segment column (Small/Mid-Market/Enterprise based on seats).
- **Dim_Calendar** (generated via Power Query M code) — Attributes: Year, Quarter, Month, MonthName, Year Month.
- **Dim_Campaign** (source: `marketing_campaigns.csv`, PK: `campaign_id`).

## 4. Fact Tables
- **Fact_Subscriptions** (FK: `account_id`) — `mrr_amount`, `arr_amount`, `start_date`, `end_date`.
- **Fact_FeatureUsage** (FK: `subscription_id`, enriched with `account_id` via merge) — `usage_count`, `usage_duration_secs`.
- **Fact_SupportTickets** (FK: `account_id`) — `resolution_time_hours`, `satisfaction_score`, `escalation_flag`.
- **Fact_ChurnEvents** (FK: `account_id`) — `reason_code`, `refund_amount_usd`, `churn_date`.

## 5. Relationships
| From Table | To Table | Join Column | Cardinality | Cross Filter Direction |
| --- | --- | --- | --- | --- |
| Dim_Account | Fact_Subscriptions | account_id | 1:* | Single |
| Dim_Account | Fact_SupportTickets | account_id | 1:* | Single |
| Dim_Account | Fact_ChurnEvents | account_id | 1:* | Single |
| Fact_Subscriptions | Fact_FeatureUsage | subscription_id | 1:* | Both |
| Dim_Calendar | Fact_SupportTickets | date | 1:* | Single |
| Dim_Calendar | Fact_FeatureUsage | date | 1:* | Single |
| Dim_Calendar | Fact_ChurnEvents | date | 1:* | Single |

*Note: The relationship between Fact_Subscriptions and Fact_FeatureUsage requires Both direction cross-filtering for feature usage filtering through the account dimension.*

## 6. Date Architecture
Dim_Calendar provides a unified date dimension. Subscription dates use interval-based historical subscription logic (filtering where the calendar date falls between `start_date` and `end_date`) rather than a direct date relationship.

## 7. DAX Measure Groups
Organized into folders for maintainability:
- **[01] Customer Metrics**: Total Customers (500), Active Customers (390), Churned Customers (110), Observed Churn Rate (22.0%).
- **[02] Revenue Metrics**: Total MRR ($11,338,747 all / $10,159,608 active), Total Active ARR ($121,915,296), Average MRR/Account ($22,677.49), Revenue at Risk.
- **[03] Product Metrics**: Average Features per Customer, Active Usage Days, Total Usage Events, Unique Accounts Using Feature.
- **[04] Support Metrics**: Average CSAT (3.98), Total Tickets (2,000), Escalation Rate (4.75%).
- **[05] Marketing Metrics**: Total Campaigns (40), Total Impressions, Total Conversions (142,798), CTR (6.31%), Cost per Conversion ($11.01).
- **[06] Retention Metrics**: Churned Customers, Churned MRR, Churned MRR by Reason (uses `CROSSFILTER`), Allocated Churned MRR by Reason.
- **[07] RFM Metrics**: Average Recency, Average Frequency, Average Monetary Value.
- **Historical Measures**: Historical MRR Trend, Historical Customer Trend (interval-based historical subscription logic).

## 8. Page 1 — Executive Overview
- **Objective**: Provide a high-level summary of business health, key KPIs, and revenue trends.
- **Visuals**:
  - KPI cards: Total Active ARR, Total MRR, Active Customers, Observed Churn Rate.
  - Dual-axis historical trend chart: Historical MRR and Customer counts over time.
  - Risk hitlist table: Top at-risk accounts with conditional formatting based on usage/support metrics.
  - MRR by segment donut chart: Revenue distribution across Small, Mid-Market, and Enterprise.
- **Key Measures**: Total MRR, Total Active ARR, Active Customers, Observed Churn Rate.
- **Design Decisions**: Focuses on high-level, interval-based historical subscription logic for accurate trending.

## 9. Page 2 — Revenue Analytics
- **Objective**: Deep dive into revenue concentration and performance by tier and industry.
- **Visuals**:
  - MRR by Plan Tier (bar chart).
  - MRR by Industry (bar chart).
  - MRR Concentration Over Time (stacked column chart by segment).
  - Top 20 Customers table: Account details and MRR contribution.
- **Key Measures**: Total MRR, Average MRR.
- **Design Decisions**: Stacked columns show both total growth and compositional shifts in revenue base.

## 10. Page 3 — Customer Retention
- **Objective**: Analyze churn characteristics and revenue attrition.
- **Visuals**:
  - KPI Cards: Churned Customers, Observed Churn Rate, Churned MRR.
  - Top Churn Reasons (bar chart): Uses `CROSSFILTER` DAX to handle multiple reasons per churned customer.
  - Churned MRR by Plan (donut chart).
  - Churned MRR by Segment (donut chart).
  - Detailed Churn Event Log (table): Itemized list of recent churn events.
- **Key Measures**: Churned Customers, Churned MRR by Reason, Allocated Churned MRR by Reason.
- **Design Decisions**: Leverages allocated MRR calculations to prevent double-counting revenue across multiple churn reason codes.

## 11. Page 4 — Product & Support
- **Objective**: Evaluate product adoption and support team performance.
- **Visuals**:
  - KPI Cards: Feature Adoption, Active Usage Days, Average CSAT, Escalation Rate.
  - Support Volume (stacked column chart): By escalation flag over time.
  - Tickets by Priority (donut chart).
  - Feature Adoption (table): Adoption rates and usage volume by feature.
- **Key Measures**: Average CSAT, Escalation Rate, Total Tickets.
- **Design Decisions**: Combines support and product usage to highlight the observed association between feature adoption and support needs.

## 12. Page 5 — Marketing Analytics
- **Objective**: Track marketing campaign efficiency and conversion metrics.
- **Visuals**:
  - KPI Cards: Total Campaigns, Total Impressions, Total Conversions, CTR, Cost per Conversion (CPA).
  - Conversions vs Clicks (combo chart): Volume metrics plotted together.
  - CPA by Campaign Type (bar chart): Efficiency comparison.
  - Campaign Ledger (table): Detailed campaign performance log.
- **Key Measures**: Cost per Conversion, CTR, Total Conversions.
- **Design Decisions**: Strictly utilizes Cost per Conversion (CPA) rather than CAC, as full attribution data is not present.

## 13. Page 6 — Customer Segmentation & RFM
- **Objective**: Provide descriptive customer segmentation using Recency, Frequency, and Monetary parameters.
- **Visuals**:
  - KPI Cards: Average Recency, Average Frequency, Average Monetary Value.
  - MRR by Customer Segment (column chart).
  - RFM scatter plot (bubble chart): Mapping accounts by engagement and value.
  - Customer Directory (table): Listing accounts, segments, and current MRR.
- **Key Measures**: RFM scores and segment classifications.
- **Design Decisions**: Uses descriptive customer segmentation rather than predictive modeling to classify accounts into groups like Champions, At Risk, Loyal, etc.

## 14. Customer 360 — Drill-through
- **Objective**: Provide a granular, account-level view accessible via drill-through from other pages.
- **Visuals**:
  - Account detail cards: Name, Segment, Plan, MRR.
  - Product Usage Trend (line chart): Activity over time for the specific account.
  - Support Ticket history (table): Log of all tickets associated with the account.
- **Key Measures**: Account-specific MRR, Usage counts.
- **Design Decisions**: Hidden from primary navigation; accessed contextually by right-clicking `account_name` in visual tables.

## 15. Slicers & Navigation
- **Synced Sidebar Slicers**: Year, Customer Segment, Plan Tier.
- **Marketing Page Additions**: Marketing Channel, Campaign Type.
- **Navigation**: Uniform page-to-page navigation buttons or sidebar menu for seamless transitions.

## 16. QA & Reconciliation
The dashboard has been reconciled against the Python-based data extraction and analysis scripts. Core KPIs match within acceptable rounding tolerances:

| Metric | Python Value | Power BI Value | Variance / Note |
| --- | --- | --- | --- |
| Total Customers | 500 | 500 | Match |
| Active Customers | 390 | 390 | Match |
| Churned Customers | 110 | 110 | Match |
| Observed Churn Rate | 22.0% | 22.0% | Match |
| Average CSAT | 4.0 (rounded) | 3.98 | Rounding variation |
| Escalation Rate | 4.8% (rounded) | 4.75% | Rounding variation |

## 17. Known Limitations
- **Interval-based Subscription Logic**: Calculating historical MRR and customer counts requires filtered `CALCULATE` measures rather than standard date dimension relationships.
- **Multiple Churn Events**: Churn events have multiple rows per customer (600 events across 110 unique customers). This is addressed with `CROSSFILTER` and allocated MRR measures to prevent revenue double-counting.
- **Cohort Analysis**: The dataset does NOT have a monthly snapshot ledger. Cohort analysis uses observed cumulative churn rather than a traditional monthly retention matrix.
- **Dashboard Screenshots**: May need refreshing after final DAX measure adjustments.
- **Marketing Metrics**: Marketing data supports Cost per Conversion (CPA), not Customer Acquisition Cost (CAC) or Life-Time Value (LTV).
- **Statistical Associations**: All relationships between variables are observed associations; association ≠ causation.
