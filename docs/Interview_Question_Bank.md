# Interview Question Bank — B2B SaaS Analytics Platform

## SQL (15+ questions)

1. **Question**: Explain the difference between INNER JOIN and LEFT JOIN.
   - **Expected Answer Points**: INNER returns matching rows; LEFT returns all from left, matches from right.
   - **Project Context**: Used LEFT JOIN to connect `accounts` to `support_tickets` to ensure accounts without tickets are still included.

2. **Question**: What is a CTE and why use it?
   - **Expected Answer Points**: Temporary named result set; improves readability; allows recursive queries.
   - **Project Context**: Used CTEs in the `mrr_analysis.sql` to isolate active subscriptions before aggregating MRR.

3. **Question**: Explain ROW_NUMBER vs RANK.
   - **Expected Answer Points**: ROW_NUMBER gives sequential int; RANK gives same rank for ties, skipping next.
   - **Project Context**: Used ROW_NUMBER partitioned by `account_id` ordered by `date` to find the most recent support ticket.

4. **Question**: How do LAG and LEAD functions work?
   - **Expected Answer Points**: Access previous/next row data without self-join.
   - **Project Context**: Used LAG to compare MRR changes month-over-month for accounts.

5. **Question**: When to use a subquery vs a CTE?
   - **Expected Answer Points**: CTEs are more readable and reusable; subqueries can be inline in SELECT/WHERE.
   - **Project Context**: Refactored subqueries in the churn analysis script into CTEs for better stakeholder readability.

6. **Question**: Explain EXISTS vs IN.
   - **Expected Answer Points**: EXISTS returns boolean on subquery; IN checks against a list; EXISTS is often faster.
   - **Project Context**: Used EXISTS to efficiently filter accounts that have at least one churn event.

7. **Question**: What is the difference between WHERE and HAVING?
   - **Expected Answer Points**: WHERE filters rows before aggregation; HAVING filters after GROUP BY.
   - **Project Context**: Used HAVING `COUNT(ticket_id) > 5` to find high-support accounts.

8. **Question**: How do you handle date truncation in SQL?
   - **Expected Answer Points**: DATE_TRUNC or specific DB functions to group by month/year.
   - **Project Context**: Used DATE_TRUNC('month', created_date) for the cohort analysis base.

9. **Question**: Explain the use of CASE WHEN.
   - **Expected Answer Points**: IF/THEN logic in SQL; creates conditional columns.
   - **Project Context**: Used to define RFM segments logically in SQL before Python modeling.

10. **Question**: Name 5 aggregate functions.
    - **Expected Answer Points**: SUM, COUNT, AVG, MIN, MAX.
    - **Project Context**: Calculated Average MRR/Account ($22,677.49) using AVG.

11. **Question**: What does NTILE do?
    - **Expected Answer Points**: Divides ordered dataset into a number of buckets.
    - **Project Context**: Used NTILE(5) for Recency, Frequency, Monetary scoring.

12. **Question**: How do you calculate a running total?
    - **Expected Answer Points**: SUM() OVER (ORDER BY col).
    - **Project Context**: Calculated cumulative marketing conversions (total 142,798).

13. **Question**: How do you calculate a moving average?
    - **Expected Answer Points**: AVG() OVER (ORDER BY col ROWS BETWEEN X PRECEDING AND CURRENT ROW).
    - **Project Context**: Analyzed 3-month rolling CSAT averages.

14. **Question**: What is a CROSS JOIN?
    - **Expected Answer Points**: Cartesian product of two tables.
    - **Project Context**: Generated a date spine to ensure continuous timeline reporting.

15. **Question**: How to optimize a slow query?
    - **Expected Answer Points**: Indexes, avoid SELECT *, use EXPLAIN, minimize subqueries.
    - **Project Context**: Analyzed execution plans for the `feature_usage` table (25k rows).


## Python/Pandas (10+ questions)

1. **Question**: How do you handle missing values in Pandas?
   - **Expected Answer Points**: dropna(), fillna(), imputation.
   - **Project Context**: Handled missing CSAT scores in Python notebooks by leaving them null to avoid skewing the 4.0 average.

2. **Question**: merge() vs join() in Pandas.
   - **Expected Answer Points**: merge is on columns (like SQL join); join is on indices.
   - **Project Context**: Used merge() to combine accounts and subscriptions DataFrames.

3. **Question**: How does groupby work?
   - **Expected Answer Points**: Split, apply, combine.
   - **Project Context**: `df.groupby('industry').agg({'mrr':'sum'})` to find revenue by industry.

4. **Question**: What is a pivot_table in Pandas?
   - **Expected Answer Points**: Reshapes data based on column values, aggregates data.
   - **Project Context**: Created a retention matrix for the cohort analysis notebook.

5. **Question**: How do you parse dates in Pandas?
   - **Expected Answer Points**: pd.to_datetime().
   - **Project Context**: Converted `start_date` and `end_date` in the 5,000 row subscriptions table.

6. **Question**: Explain boolean indexing.
   - **Expected Answer Points**: Filtering df using conditions `df[df['col'] > 0]`.
   - **Project Context**: Filtered active customers (390) out of the total 500.

7. **Question**: When to use apply() vs vectorization?
   - **Expected Answer Points**: apply applies a func to rows/cols; vectorization is C-level fast.
   - **Project Context**: Used vectorized conditions for calculating Escalation Rate (4.8%).

8. **Question**: Matplotlib vs Seaborn?
   - **Expected Answer Points**: Seaborn is high-level, built on Matplotlib, better defaults for stats.
   - **Project Context**: Used Seaborn heatmaps for the correlation matrix in Notebook 12.

9. **Question**: How to optimize pandas memory usage?
   - **Expected Answer Points**: Downcast numeric types, use categorical types.
   - **Project Context**: Converted `plan_type` and `industry` to categorical types.

10. **Question**: How to read specific sheets in Excel?
    - **Expected Answer Points**: pd.read_excel(sheet_name='X').
    - **Project Context**: Used CSVs `pd.read_csv` for the 6 core tables.


## Statistics (10+ questions)

1. **Question**: What is a p-value?
   - **Expected Answer Points**: Probability of observing the data given the null hypothesis is true.
   - **Project Context**: In Notebook 12, found ALL p > 0.05, indicating no statistically significant associations between usage and churn.

2. **Question**: What does 'Correlation does not imply causation' mean here?
   - **Expected Answer Points**: Two variables moving together doesn't mean one causes the other.
   - **Project Context**: Even if an association was found (it wasn't), we would use 'observed association', never causation.

3. **Question**: What is a Mann-Whitney U test?
   - **Expected Answer Points**: Non-parametric test comparing two independent groups.
   - **Project Context**: Used to compare CSAT scores between churned and active customers.

4. **Question**: When to use a Chi-Square test?
   - **Expected Answer Points**: Testing relationships between categorical variables.
   - **Project Context**: Tested industry vs churn status (p > 0.05).

5. **Question**: What is a Type I vs Type II error?
   - **Expected Answer Points**: Type I: False positive. Type II: False negative.
   - **Project Context**: Discussed risks of false positives in identifying 'At Risk' customers (114 customers).

6. **Question**: What is the significance level (alpha)?
   - **Expected Answer Points**: Threshold for rejecting null hypothesis (often 0.05).
   - **Project Context**: Used standard alpha = 0.05; no tests cleared this threshold.

7. **Question**: What are Confidence Intervals?
   - **Expected Answer Points**: Range of values likely containing population parameter.
   - **Project Context**: Calculated CIs for the average MRR of $22,677.49.

8. **Question**: Non-parametric vs parametric tests?
   - **Expected Answer Points**: Parametric assumes normal distribution; non-parametric does not.
   - **Project Context**: Feature usage data was highly skewed, necessitating non-parametric tests.

9. **Question**: What is effect size?
   - **Expected Answer Points**: Quantifies the magnitude of a difference.
   - **Project Context**: Calculated Cohen's d, noting extremely small effect sizes confirming the p-values.

10. **Question**: What is the null hypothesis in your churn test?
    - **Expected Answer Points**: No difference in feature usage between churned and active users.
    - **Project Context**: We failed to reject the null hypothesis across all 25,000 usage records.


## Power BI (15+ questions)

1. **Question**: Explain Star Schema.
   - **Expected Answer Points**: Fact table in center, dimension tables radiating out.
   - **Project Context**: Implemented a star-schema-oriented data model for the 6 tables.

2. **Question**: Difference between Calculated Column and Measure.
   - **Expected Answer Points**: Columns computed row-by-row on load; Measures computed on-the-fly based on context.
   - **Project Context**: Used measures for Total MRR ($11.3M) and Active ARR ($121.9M).

3. **Question**: What is Power Query M?
   - **Expected Answer Points**: Data transformation language.
   - **Project Context**: Used M to clean support tickets and parse the 40 marketing campaigns.

4. **Question**: What are slicers?
   - **Expected Answer Points**: Visual filters on the canvas.
   - **Project Context**: Created slicers for Date, Industry, and Plan Type across all 6 pages.

5. **Question**: Explain drill-through.
   - **Expected Answer Points**: Navigating from a summary visual to a detailed page.
   - **Project Context**: Built the hidden 'Customer 360 Drill-through' page.

6. **Question**: How do relationships work?
   - **Expected Answer Points**: 1:N, 1:1, N:N; active vs inactive.
   - **Project Context**: Standard 1:N from Accounts to Subscriptions.

7. **Question**: What is cross-filtering?
   - **Expected Answer Points**: Direction of filter flow (single vs both).
   - **Project Context**: Solved fact-to-fact filtering using bidirectional cross-filtering strategically.

8. **Question**: Why use a Date Table?
   - **Expected Answer Points**: Essential for time intelligence DAX functions.
   - **Project Context**: Created a continuous date table spanning the subscription periods.

9. **Question**: When to use a matrix visual?
   - **Expected Answer Points**: Displaying hierarchical data or pivoting.
   - **Project Context**: Used for the cohort analysis 'observed cumulative churn' matrix.

10. **Question**: What is conditional formatting?
    - **Expected Answer Points**: Changing colors/icons based on data values.
    - **Project Context**: Formatted CSAT (3.98) red if below 3.5.

11. **Question**: How to handle N:N relationships?
    - **Expected Answer Points**: Bridge tables.
    - **Project Context**: Used accounts as a dimension between feature_usage and support_tickets.

12. **Question**: What is Row Level Security?
    - **Expected Answer Points**: Restricting data access based on user roles.
    - **Project Context**: Theoretical application for account managers.

13. **Question**: Explain tooltips in PBI.
    - **Expected Answer Points**: Hover info; can be custom report pages.
    - **Project Context**: Added custom tooltips to the RFM scatter plot.

14. **Question**: What are bookmarks used for?
    - **Expected Answer Points**: Saving report states, creating navigation buttons.
    - **Project Context**: Used for clearing filters on the Executive Overview.

15. **Question**: How to optimize PBI performance?
    - **Expected Answer Points**: Performance analyzer, reduce visual count, optimize DAX.
    - **Project Context**: Optimized the CROSSFILTER function for churn calculations.


## DAX (10+ questions)

1. **Question**: Explain CALCULATE.
   - **Expected Answer Points**: Evaluates expression in a modified filter context.
   - **Project Context**: Used to calculate Active MRR by filtering status = 'Active'.

2. **Question**: What does FILTER do?
   - **Expected Answer Points**: Returns a table that has been filtered.
   - **Project Context**: `FILTER(Accounts, Accounts[Churned] = True)`

3. **Question**: Explain the ALL function.
   - **Expected Answer Points**: Removes filters from a table or column.
   - **Project Context**: Used to calculate % of Total MRR.

4. **Question**: What is CROSSFILTER?
   - **Expected Answer Points**: Modifies cross-filtering direction in a CALCULATE.
   - **Project Context**: Critical fix for the churn MRR duplication issue to force filtering.

5. **Question**: Difference between SUM and SUMX.
   - **Expected Answer Points**: SUM aggregates column; SUMX is an iterator evaluating row-by-row.
   - **Project Context**: Used SUMX to calculate interval-based historical subscription logic.

6. **Question**: COUNTROWS vs DISTINCTCOUNT.
   - **Expected Answer Points**: Rows vs unique values.
   - **Project Context**: `DISTINCTCOUNT(Account_ID)` to find the 390 Active Customers.

7. **Question**: Why use DIVIDE over '/'?
   - **Expected Answer Points**: Handles divide by zero gracefully.
   - **Project Context**: Used to calculate CTR (6.31%) safely.

8. **Question**: Explain Context Transition.
   - **Expected Answer Points**: Row context transforming into filter context (via CALCULATE).
   - **Project Context**: Important for calculating allocated MRR per ticket.

9. **Question**: What is Row Context vs Filter Context?
   - **Expected Answer Points**: Row context iterates rows; Filter context applies filters.
   - **Project Context**: Managing context was key for the interval-based subscription DAX.

10. **Question**: Name a time intelligence function.
    - **Expected Answer Points**: TOTALYTD, DATEADD.
    - **Project Context**: Used to calculate Month-over-Month MRR growth.


## Data Modeling (10+ questions)

1. **Question**: Star schema vs Snowflake schema.
   - **Expected Answer Points**: Snowflake normalizes dimensions; Star keeps them denormalized.
   - **Project Context**: Opted for star-schema-oriented design for simpler DAX and better PBI performance.

2. **Question**: Fact vs Dimension table.
   - **Expected Answer Points**: Facts are metrics/events; Dimensions are context/entities.
   - **Project Context**: `subscriptions` is fact; `accounts` is dimension.

3. **Question**: What is 'grain'?
   - **Expected Answer Points**: The level of detail in a fact table row.
   - **Project Context**: The grain of `support_tickets` is one row per individual ticket.

4. **Question**: What is cardinality?
   - **Expected Answer Points**: Uniqueness of values in a column.
   - **Project Context**: 1:1 vs 1:N cardinality in PBI relationships.

5. **Question**: How do you resolve many-to-many?
   - **Expected Answer Points**: Bridge table.
   - **Project Context**: Accounts acts as the central dimension linking marketing and usage.

6. **Question**: What are Slowly Changing Dimensions (SCD)?
   - **Expected Answer Points**: Methods to track changes over time (Type 1, 2, 3).
   - **Project Context**: Used interval-based historical subscription logic instead of SCD Type 2.

7. **Question**: Why is a date dimension critical?
   - **Expected Answer Points**: Uniform time filtering across disparate facts.
   - **Project Context**: Allows filtering both support tickets and marketing campaigns by the same month.

8. **Question**: What is a bridge table?
   - **Expected Answer Points**: Table resolving M:N.
   - **Project Context**: Conceptually handled by the accounts table.

9. **Question**: What is a degenerate dimension?
   - **Expected Answer Points**: Dimension key in fact table without a corresponding dim table.
   - **Project Context**: `ticket_id` in the support table.

10. **Question**: Normalization vs Denormalization.
    - **Expected Answer Points**: Minimizing redundancy vs optimizing read performance.
    - **Project Context**: Denormalized some account details for easier reporting.


## Business/Analytics (15+ questions)

1. **Question**: How do you define MRR and ARR?
   - **Expected Answer Points**: Monthly/Annual Recurring Revenue.
   - **Project Context**: Calculated Total Active ARR as $121,915,296.

2. **Question**: How did you calculate churn rate?
   - **Expected Answer Points**: Churned customers / Total customers.
   - **Project Context**: 110 / 500 = Observed Churn Rate of 22.0%.

3. **Question**: What is a cohort analysis?
   - **Expected Answer Points**: Tracking groups of users over time based on shared characteristics.
   - **Project Context**: Calculated 'observed cumulative churn' since the dataset lacks a monthly ledger.

4. **Question**: Explain RFM Segmentation.
   - **Expected Answer Points**: Recency, Frequency, Monetary value grouping.
   - **Project Context**: Used as descriptive customer segmentation (Champions: 81), NOT a predictive model.

5. **Question**: What is Cost per Conversion?
   - **Expected Answer Points**: Total spend / Conversions.
   - **Project Context**: Calculated strictly as $11.01 (Never claimed as Customer Acquisition Cost/CAC).

6. **Question**: What is Escalation Rate?
   - **Expected Answer Points**: % of tickets escalated.
   - **Project Context**: 4.75% in Power BI (4.8% rounded in Python).

7. **Question**: What is CTR?
   - **Expected Answer Points**: Click-through rate (Clicks / Impressions).
   - **Project Context**: Total campaigns yielded a 6.31% CTR.

8. **Question**: KPI vs Metric?
   - **Expected Answer Points**: KPIs are tied to strategic goals; metrics are just numbers.
   - **Project Context**: Active MRR is a KPI; Total Support Tickets (2,000) is a metric.

9. **Question**: Why don't you use the term CAC here?
   - **Expected Answer Points**: Lacks full marketing/sales expense data.
   - **Project Context**: We strictly use 'Cost per Conversion' to maintain data integrity.

10. **Question**: Why don't you calculate CLV?
    - **Expected Answer Points**: Requires longer historical data and margin info.
    - **Project Context**: Data doesn't support accurate LTV claims.

11. **Question**: How is average CSAT calculated?
    - **Expected Answer Points**: Sum of scores / count of responses.
    - **Project Context**: 3.98 exact in Power BI.

12. **Question**: What does 'descriptive vs predictive' mean for RFM?
    - **Expected Answer Points**: Descriptive explains current state; predictive models future behavior.
    - **Project Context**: Categorized 114 At Risk customers based on past data, didn't use ML to predict.

13. **Question**: How do you present insignificant findings?
    - **Expected Answer Points**: Honestly, stating 'no observed association'.
    - **Project Context**: Explained that feature usage didn't drive churn (p>0.05).

14. **Question**: What is retention?
    - **Expected Answer Points**: Inverse of churn; keeping customers.
    - **Project Context**: Analyzed via the observed cumulative churn matrix.

15. **Question**: How do you communicate data effectively?
    - **Expected Answer Points**: Know the audience, use clear visuals, provide actionable insights.
    - **Project Context**: Used the Executive Overview page for high-level KPIs.


## Project-Specific (20+ questions)

1. **Question**: Walk me through your data pipeline for this project.
   - **Expected Answer Points**: Raw data -> SQL cleaning/exploration -> Python stats -> PBI modeling -> Dashboards.
   - **Project Context**: Handled 6 tables and 33,140 rows.

2. **Question**: How did you handle the churn MRR duplication issue?
   - **Expected Answer Points**: Adjusting relationship filtering.
   - **Project Context**: Used the CROSSFILTER DAX function to enforce proper filtering.

3. **Question**: Why didn't your statistical tests show significant results?
   - **Expected Answer Points**: Data distribution; true lack of correlation in the dataset.
   - **Project Context**: ALL p > 0.05. We use "observed association", no causal claims.

4. **Question**: How did you solve the fact-to-fact filtering problem in Power BI?
   - **Expected Answer Points**: Data model redesign or bidirectional filters.
   - **Project Context**: Passed filters through the Accounts dimension table.

5. **Question**: What is your star schema design?
   - **Expected Answer Points**: Central dims, surrounding facts.
   - **Project Context**: 'star-schema-oriented data model', not a 'perfect star schema'.

6. **Question**: How do you calculate MRR for historical trends?
   - **Expected Answer Points**: Evaluating active status at points in time.
   - **Project Context**: Used interval-based historical subscription logic.

7. **Question**: What are the limitations of your cohort analysis?
   - **Expected Answer Points**: Lacks snapshot data.
   - **Project Context**: Dataset does NOT have a monthly snapshot ledger, so we use 'observed cumulative churn'.

8. **Question**: Why don't you use CAC?
   - **Expected Answer Points**: Integrity to data constraints.
   - **Project Context**: Use "Cost per Conversion (CPA)" ($11.01) instead.

9. **Question**: How did you implement the Customer 360 drill-through?
   - **Expected Answer Points**: Set up drill-through fields on a hidden page.
   - **Project Context**: Allows clicking a specific account to see their support, usage, and MRR.

10. **Question**: What would you do differently?
    - **Expected Answer Points**: Gather snapshot data, collect more qualitative churn reasons.
    - **Project Context**: Acknowledging the limitation of not having a monthly ledger.

11. **Question**: How would you extend this project?
    - **Expected Answer Points**: Predictive ML models, sentiment analysis on tickets.
    - **Project Context**: Would require new data sources.

12. **Question**: Why use Python alongside Power BI?
    - **Expected Answer Points**: Python for rigorous stats (SciPy), PBI for interactive BI.
    - **Project Context**: Verified the p > 0.05 explicitly in Pandas/SciPy before building the dashboard.

13. **Question**: How were RFM segments defined?
    - **Expected Answer Points**: Quantile bucketing.
    - **Project Context**: Divided into Champions, At Risk, Lost Cause, Loyal, Needs Attention, Recent.

14. **Question**: How did you validate the Total MRR KPI?
    - **Expected Answer Points**: Cross-checked SQL aggregates vs PBI card visuals.
    - **Project Context**: Verified $11,338,747 (all) and $10,159,608 (active).

15. **Question**: What is the most important dashboard page and why?
    - **Expected Answer Points**: Executive Overview.
    - **Project Context**: Anchors the 390 Active customers and $121.9M ARR.

16. **Question**: How did you handle the 600 churn events for 110 customers?
    - **Expected Answer Points**: Deduping or counting unique.
    - **Project Context**: Multiple reasons per customer; counted 110 unique churned customers.

17. **Question**: Did support tickets drive churn?
    - **Expected Answer Points**: No statistical proof.
    - **Project Context**: Tests on the 2,000 tickets showed p > 0.05.

18. **Question**: How did you approach data type conversion?
    - **Expected Answer Points**: Ensuring compatibility between SQL, Python, PBI.
    - **Project Context**: Standardized date formats.

19. **Question**: What was the greatest technical challenge?
    - **Expected Answer Points**: DAX context or data modeling.
    - **Project Context**: Implementing the interval-based subscription logic in DAX.

20. **Question**: Why is 'Average MRR/Account' an important metric here?
    - **Expected Answer Points**: Indicates the enterprise/B2B scale.
    - **Project Context**: At $22,677.49, these are high-value B2B SaaS clients, making retention critical.
