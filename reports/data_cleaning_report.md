# Data Cleaning & Validation Report

## 1. Overview
Data cleaning performed on 6 datasets. All files verified and exported to `data/cleaned/`.

## 2. Quality Metrics
- **accounts**: 500 rows validated.
- **subscriptions**: 5000 rows validated.
- **feature_usage**: 25000 rows validated.
- **support_tickets**: 2000 rows validated.
- **churn_events**: 600 rows validated.
- **marketing_campaigns**: 40 rows validated.

## 3. Transformations Applied
- Missing values imputed appropriately (e.g. 2099 end dates for active subs)
- Datetime conversions enforced
- Business logic constraints validated (MRR >= 0)
- Categorical formatting standardized
