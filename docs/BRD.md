# Business Requirement Document (BRD)

# Project Title

**B2B SaaS Customer Cohort & Retention Analytics Platform**

---

# Version Information

| Item | Details |
|------|---------|
| Version | 1.0 |
| Status | Draft |
| Project Type | Data Analytics Portfolio Project |
| Domain | Software as a Service (SaaS) |
| Author | Shaikh Raheem |
| Last Updated | August 2026 |

---

# 1. Business Overview

A mid-sized Business-to-Business (B2B) Software-as-a-Service (SaaS) company has experienced increasing customer churn during the first six months after customer onboarding. Although the company has successfully acquired new customers through multiple marketing channels, management lacks visibility into customer retention, feature adoption, subscription behavior, and support performance.

The leadership team requires an end-to-end analytics solution to identify customer behavior patterns, understand the primary drivers of churn, measure product engagement, and provide actionable recommendations to improve customer retention and maximize recurring revenue.

This project aims to transform raw operational data into meaningful business insights through SQL, Python, and Power BI.

---

# 2. Problem Statement

The company currently faces several business challenges:

- Increasing customer churn
- Low visibility into customer engagement
- Limited understanding of feature adoption
- Lack of customer segmentation
- Inefficient reporting process
- No centralized executive dashboard
- Difficulty measuring customer lifetime value
- Limited insight into marketing effectiveness

These challenges prevent management from making informed strategic decisions regarding customer retention and revenue growth.

---

# 3. Business Objectives

The primary objectives of this project are:

- Analyze customer acquisition and subscription trends.
- Measure customer retention and churn rates.
- Perform customer cohort analysis.
- Identify high-value customer segments using RFM analysis.
- Analyze product feature adoption.
- Evaluate support ticket performance.
- Measure Monthly Recurring Revenue (MRR) and Annual Recurring Revenue (ARR).
- Calculate Customer Lifetime Value (LTV).
- Analyze marketing campaign effectiveness.
- Build interactive executive dashboards.
- Generate actionable business recommendations.

---

# 4. Business Goals

The organization expects this project to help:

- Reduce customer churn.
- Increase customer retention.
- Improve customer engagement.
- Increase product adoption.
- Improve customer support efficiency.
- Optimize marketing investments.
- Increase recurring revenue.
- Improve executive decision-making.

---

# 5. Stakeholders

| Stakeholder | Responsibility |
|-------------|----------------|
| CEO | Business strategy and growth |
| COO | Operational performance |
| Product Manager | Feature adoption and product improvement |
| Customer Success Manager | Customer retention |
| Marketing Manager | Customer acquisition and campaign performance |
| Finance Team | Revenue tracking |
| Data Analyst | Data analysis and reporting |
| Executive Leadership | Strategic decision making |

---

# 6. Scope

## In Scope

- Customer analytics
- Subscription analytics
- Revenue analytics
- Feature usage analytics
- Support analytics
- Churn analysis
- Cohort analysis
- RFM segmentation
- Marketing campaign analysis
- Power BI dashboard development
- SQL reporting
- Python exploratory data analysis (EDA)

---

## Out of Scope

- Machine Learning model deployment
- Real-time streaming analytics
- Customer recommendation engine
- Production ETL pipelines
- Cloud deployment
- Mobile application development

---

# 7. Data Sources

The project uses a synthetic multi-table SaaS dataset containing operational customer data.

Primary datasets include:

- Accounts
- Subscriptions
- Feature Usage
- Support Tickets
- Churn Events

Additional dataset to be created:

- Marketing Campaigns

---

# 8. Expected Deliverables

The project will deliver:

- PostgreSQL relational database
- Data dictionary
- Entity Relationship Diagram (ERD)
- SQL scripts
- Python EDA notebooks
- Power BI dashboard
- Business insights report
- Executive summary report
- GitHub repository
- Project documentation

---

# 9. Key Business Questions

The project aims to answer questions such as:

### Customer Analytics

- How many active customers does the company have?
- Which industries contribute the highest revenue?
- Which countries have the highest customer base?

### Revenue Analytics

- What is the Monthly Recurring Revenue (MRR)?
- What is the Annual Recurring Revenue (ARR)?
- Which subscription plans generate the highest revenue?

### Customer Retention

- What is the overall churn rate?
- Which customer segments churn the most?
- Which cohort has the highest retention?

### Product Analytics

- Which product features are used the most?
- Which beta features have the highest adoption?

### Support Analytics

- Which customers create the most support tickets?
- What is the average ticket resolution time?
- Which support issues lead to churn?

### Marketing Analytics

- Which campaigns acquire the highest-value customers?
- Which channels produce the highest retention?
- Which campaigns provide the highest ROI?

---

# 10. Success Criteria

The project will be considered successful if it:

- Produces reliable analytical insights.
- Demonstrates advanced SQL techniques.
- Includes comprehensive exploratory data analysis.
- Provides interactive Power BI dashboards.
- Presents actionable business recommendations.
- Follows industry-standard documentation.
- Can be showcased as a professional portfolio project.

---

# 11. Assumptions

- The dataset accurately represents SaaS business operations.
- Customer data relationships are valid.
- Revenue values are correctly recorded.
- Feature usage represents customer engagement.
- Marketing campaign data will be synthetically generated.

---

# 12. Constraints

- Dataset is synthetic.
- Marketing campaign data is not included and will be created.
- Analysis is based on historical data only.
- No real-time data ingestion.

---

# 13. Risks

| Risk | Mitigation |
|------|------------|
| Missing values | Data cleaning |
| Data inconsistencies | Validation rules |
| Synthetic data limitations | Clearly documented assumptions |
| Schema changes | Version-controlled SQL scripts |

---

# 14. Technology Stack

| Category | Technology |
|----------|------------|
| Database | PostgreSQL |
| Query Language | SQL |
| Programming Language | Python |
| Libraries | Pandas, NumPy, Matplotlib, Seaborn |
| Visualization | Power BI |
| Notebook | Jupyter Notebook |
| Version Control | Git & GitHub |
| Documentation | Markdown |

---

# 15. Project Timeline

| Phase | Description |
|--------|-------------|
| Phase 1 | Business Understanding & Planning |
| Phase 2 | Database Design |
| Phase 3 | Data Cleaning & Preparation |
| Phase 4 | SQL Analytics |
| Phase 5 | Python EDA |
| Phase 6 | Statistical Analysis |
| Phase 7 | Power BI Dashboard |
| Phase 8 | Business Insights |
| Phase 9 | Documentation |
| Phase 10 | Interview Preparation |

---

# 16. Expected Business Outcome

Upon completion, this project will provide management with a comprehensive analytical platform capable of monitoring customer behavior, subscription performance, product adoption, marketing effectiveness, and customer retention. The insights generated will support data-driven decision-making, improve customer satisfaction, optimize recurring revenue, and enhance long-term business growth.