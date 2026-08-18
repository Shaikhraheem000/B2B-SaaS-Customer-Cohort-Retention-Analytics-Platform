# B2B SaaS Customer Cohort & Retention Analytics Platform — Final Project Report

## 1. Executive Summary
- **Business problem**: A B2B SaaS company is experiencing early-stage churn within 6 months of onboarding, but lacks the visibility required to understand retention, adoption, and Monthly Recurring Revenue (MRR) drivers.
- **Analytical approach**: An end-to-end data pipeline was developed transitioning from raw data → Python-based cleaning → PostgreSQL database → SQL analytics → Python Exploratory Data Analysis (EDA) & statistics → Power BI dashboard.
- **Major findings**: The company currently supports 390 active customers out of 500 total, with an observed churn rate of 22.0% (110 churned customers). Total Active Annual Recurring Revenue (ARR) is $121,915,296 derived from active MRR of $10,159,608. Marketing Cost per Conversion (CPA) is $11.01 with a 6.31% CTR.
- **Business value**: This centralized analytics platform provides executives with actionable, data-driven insights into the customer lifecycle, enabling targeted retention strategies and optimized acquisition channels.

## 2. Business Problem
In the highly competitive B2B SaaS landscape, sustainable growth is dictated by customer retention and predictable revenue streams. The company lacks centralized visibility into why customers churn, which segments are most profitable, and how to effectively optimize acquisition channels. Disconnected data sources across product usage, support tickets, marketing campaigns, and subscription events obscure the customer journey, making it difficult to formulate proactive retention strategies and understand early-stage churn.

## 3. Project Objectives
- Design a relational database optimized for SaaS customer analytics.
- Perform comprehensive SQL-based business analysis spanning multiple domains.
- Conduct Python EDA across customer, revenue, product, support, marketing, and churn domains.
- Build an interactive Power BI dashboard for executive decision-making.
- Implement RFM (Recency, Frequency, Monetary) analysis as a descriptive customer segmentation strategy.
- Validate findings with robust statistical testing.

## 4. Dataset
The dataset comprises 6 tables with a total of 33,140 rows:
- **accounts** (500 rows): Customer demographic and firmographic details.
- **subscriptions** (5,000 rows): Historical and current subscription intervals.
- **feature_usage** (25,000 rows): Product adoption and feature interaction logs.
- **support_tickets** (2,000 rows): Customer service inquiries and resolution metrics.
- **churn_events** (600 rows): Categorized churn reasons (multiple reasons documented per customer for 110 unique churned customers).
- **marketing_campaigns** (40 rows): Marketing campaign spend, impressions, clicks, and conversions.

## 5. Data Architecture
The data pipeline is designed for robustness and analytical flexibility:
1. **Raw CSV Data**: Initial ingestion of business data.
2. **Python Cleaning (Pandas)**: Data validation, deduplication, and type casting.
3. **PostgreSQL Database**: Relational storage enforcing referential integrity.
4. **SQL Analytics**: Deep-dive querying, view creation, and metric aggregation.
5. **Python EDA & Statistics**: Visual exploration and statistical validation using Jupyter Notebooks.
6. **Power BI Dashboard**: Executive reporting utilizing a star-schema-oriented data model.

## 6. Data Cleaning
Data cleaning was performed systematically using Python and Pandas. The process involved handling missing values, duplicate detection, rigorous data type conversion, date sequencing validation, and enforcing business rules (e.g., ensuring start dates precede end dates). The post-validation health score achieved 100% (33,140 records, 0 duplicates, 0 broken foreign keys), ensuring a pristine foundation for analytics.

## 7. SQL Analytics
The SQL analytics suite comprises 9 structured files:
- Database verification and schema validation.
- Basic analysis (30 queries) establishing baseline counts.
- Intermediate analysis (38 queries) utilizing Common Table Expressions (CTEs).
- Advanced analysis (36 queries) leveraging complex window functions.
- Cohort analysis (27 queries) to evaluate behavioral groups.
- RFM analysis (29 queries) calculating customer segmentation scoring.
- Analytics views (12 views) to streamline dashboard ingestion.
- Business insights (23 insights) extracting targeted metrics.
- Dashboard queries (45 queries) powering visualization logic.

## 8. Python Analytics
Exploratory Data Analysis and statistical testing were conducted across 13 Jupyter notebooks:
- Data loading and programmatic validation.
- Data cleaning pipeline execution.
- Broad EDA establishing variable distributions.
- Domain-specific analytics: Customer, Revenue, Product, Support, Marketing, and Churn.
- Cohort visualization mapping historical trends.
- RFM visualization detailing descriptive customer segmentation.
- Statistical analysis evaluating relationships between variables.
- Comprehensive executive summary notebook.

## 9. Power BI Dashboard
The executive Power BI dashboard consists of 7 strategic pages:
1. **Executive Overview**: High-level KPIs and business health metrics.
2. **Revenue Analytics**: Financial performance utilizing interval-based historical subscription logic for MRR trending.
3. **Customer Retention**: Churn evaluation employing CROSSFILTER DAX for resolving fact-to-fact churn analysis.
4. **Product & Support**: Feature adoption and customer satisfaction tracking.
5. **Marketing Analytics**: Campaign performance and efficiency metrics.
6. **Customer Segmentation & RFM**: Descriptive categorization into segments like Champions and At Risk.
7. **Customer 360 Drill-through** (hidden): Deep-dive granular view for individual account investigation.
The underlying architecture relies on a robust star-schema-oriented data model.

## 10. Key KPIs
- **Total Customers**: 500
- **Active Customers**: 390
- **Churned Customers**: 110
- **Observed Churn Rate**: 22.0%
- **Total MRR**: $11,338,747 (all historical subscriptions) / $10,159,608 (active MRR)
- **Total Active ARR**: $121,915,296
- **Average MRR/Account**: $22,677.49
- **Average CSAT**: 3.98
- **Total Support Tickets**: 2,000
- **Escalation Rate**: 4.75%
- **Cost per Conversion (CPA)**: $11.01
- **Total Conversions**: 142,798
- **CTR**: 6.31%

## 11. Key Business Insights
1. **Revenue Concentration**: A significant portion of Total Active ARR ($121.9M) is concentrated in the top RFM segments, specifically the 81 "Champions".
2. **Churn Landscape**: The business exhibits an observed churn rate of 22.0%, representing 110 lost accounts with diverse primary and secondary churn reasons.
3. **Marketing Efficiency**: The average Cost per Conversion (CPA) is exceptionally efficient at $11.01, driven by a strong CTR of 6.31%.
4. **Support Quality**: Customer satisfaction remains high with an average CSAT of 3.98 and a low escalation rate of 4.75%.
5. **Customer Segmentation**: RFM analysis successfully distributed the base into distinct descriptive groups: Champions (81), At Risk (114), Lost Cause (87), Loyal (42), Needs Attention (21), and Recent (45).
6. **Product Usage Associations**: There is an observed association between specific feature utilization and overall account longevity, though no predictive causality could be confirmed.
7. **Support Impact**: Volume of support tickets shows an observed association with account health; proactive resolution correlates with active status.
8. **Subscription Changes**: Interval-based historical subscription logic reveals that downgrades often precede full account churn.

## 12. Business Risks
- **High "At Risk" Population**: With 114 customers identified as "At Risk" in the RFM segmentation, a significant portion of MRR is currently vulnerable.
- **Early-Stage Attrition**: Without statistically significant predictors for churn (all p-values > 0.05), early identification of at-risk behavior relies heavily on descriptive rather than predictive analytics.
- **Feature Underutilization**: Segments demonstrating low feature usage logs represent an ongoing risk for perceived lack of ROI and subsequent downgrade or churn.

## 13. Business Opportunities
- **Targeted Interventions**: The precise identification of 21 "Needs Attention" and 114 "At Risk" customers provides a definitive list for immediate Customer Success outreach.
- **Marketing Scaling**: With an efficient Cost per Conversion (CPA) of $11.01 and a healthy 6.31% CTR, there is a clear opportunity to scale high-performing campaign channels.
- **Upselling Champions**: The 81 "Champions" and 42 "Loyal" customers present prime candidates for expansion revenue through feature upselling or premium support packages.

## 14. Recommendations
1. **Deploy Proactive Playbooks**: Initiate immediate Customer Success interventions for the 114 "At Risk" customers.
2. **Scale Efficient Marketing**: Reallocate budget towards campaigns exhibiting the $11.01 Cost per Conversion (CPA) benchmark to drive top-of-funnel growth.
3. **Enhance Onboarding**: Address early-stage churn by improving initial product adoption training during the critical first 90 days.
4. **Monitor Support Interactions**: Maintain the low 4.75% escalation rate by continuing to invest in tier-1 support training and rapid resolution workflows.
5. **Leverage Champions**: Develop a customer advocacy program utilizing the 81 "Champions" for case studies, referrals, and testimonials.
6. **Refine RFM Targeting**: Utilize the descriptive customer segmentation to tailor communication strategies uniquely to each cohort.

## 15. Data Limitations
- **Cohort Tracking**: The dataset lacks a monthly snapshot ledger, meaning cohort analysis is based on observed cumulative churn rather than a traditional monthly retention matrix.
- **Statistical Significance**: There are no statistically significant churn predictors within the current data model (all statistical tests yielded p > 0.05).
- **Synthetic Origin**: This is a synthetic dataset designed for analytical demonstration.
- **Real-time Pipeline**: The architecture currently relies on static data dumps; there is no real-time data streaming pipeline.
- **Marketing Granularity**: Marketing data tracks aggregate conversions, not individual customer acquisition, meaning a true Customer Acquisition Cost (CAC) cannot be calculated (Cost per Conversion is used instead).
- **Churn Event Volume**: There are 600 churn events documented for only 110 unique customers, indicating multiple overlapping reasons per account.

## 16. Technical Stack
- **Languages & Libraries**: Python, Pandas, NumPy, Matplotlib, Seaborn, SciPy, SQL, DAX, Power Query.
- **Databases & Tools**: PostgreSQL, Power BI, Jupyter Notebooks, Git/GitHub.

## 17. Conclusion
The implementation of the B2B SaaS Customer Cohort & Retention Analytics Platform has successfully transformed disparate data into a cohesive, star-schema-oriented data model. By leveraging robust SQL analytics, Python EDA, and an interactive Power BI dashboard, the business now possesses critical visibility into its $121.9M Active ARR and customer lifecycle. While predictive churn modeling requires enhanced data collection, the current descriptive customer segmentation provides immediate, actionable pathways to mitigate the 22.0% observed churn rate and optimize growth.
