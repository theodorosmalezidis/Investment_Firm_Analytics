
# B) Advanced Report 

![visual](/visual_documentation/png/advanced_report.png)


This report is structured into five key sections , each of which I analyzed to provide comprehensive insights.

## 1. AUM Performance Over Time

Here i calculate:

a) Year-over-Year (YoY) Change in AUM

b) Quarter-over-Quarter (QoQ) Change in AUM

c) Year-over-Year (YoY) % Change in Cumulative AUM

d) Quarter-over-Quarter (QoQ) % Change in Cumulative AUM

- **Purpose:** Tracks how the total Assets Under Management (AUM) grow or shrink over the years and quarters, giving a good sense of the firm’s financial progress.

- **Insight:** Shows how AUM is changing by comparing it to previous years and quarters. Both the actual changes and the percentage differences help spot whether growth is speeding up, slowing down, or staying steady.

- **Value:** Helps firms see the bigger picture and make smart decisions—like adjusting strategies or fine-tuning investment options—to keep AUM growing in the right direction.

I wiil showcase two of them.

### (YoY) Change in AUM:

```sql
WITH YearlyAUM AS (
    SELECT 
        YEAR(transaction_date) AS fiscal_year,
        SUM(CAST(invested_amount AS DECIMAL(20, 2))) - SUM(CAST(withdrawal_amount AS DECIMAL(20, 2))) AS yearly_aum
    FROM gold.fact_transactions
    WHERE transaction_date IS NOT NULL
    GROUP BY 
        YEAR(transaction_date)
),
PrevYearlyAUM AS(
	SELECT *,
		LAG(yearly_aum) OVER(ORDER BY fiscal_year) AS prev_yearly_aum
	FROM
		YearlyAUM
)
SELECT
	fiscal_year,
	yearly_aum,
	prev_yearly_aum,
	CAST(ROUND(((yearly_aum/prev_yearly_aum)-1)*100, 2) AS DECIMAL (18,2)) AS yoy_perc
FROM
	PrevYearlyAUM
ORDER BY
		fiscal_year;
```        

![visual](/visual_documentation/charts/yearly_aum_and_yoy_changes.png)

*Bar chart visualizing YoY AUM change.This visualization was created with Python after importing my SQL query results*

Key Findings (keep in mind data is current up to March 2025):


- Yearly AUM peaked in 2021  at $204.7M  but has shown a declining trend in subsequent years, with 2024  recording $177.3M.

- The largest YoY decline in a full year occurred between 2022 and 2023 , with a drop of -5.53%.

- For 2025 , the AUM is reported as $31.0M , but this reflects only the first three months of the year (up to March 2025). Therefore, the -82.50% YoY change  is not valid for comparison with full-year data from prior years.

- Despite early growth (+18.22% in 2021), the overall trend indicates consistent annual declines from 2022 onward, signaling potential challenges in maintaining or growing assets.
     
### (QoQ) % Change in Cumulative AUM

```sql
With QuarterlyAUM AS(
	SELECT
		YEAR(transaction_date) AS fiscal_year,
		DATEPART(QUARTER, transaction_date) AS fiscal_quarter,
		SUM(CAST(invested_amount AS DECIMAL (18, 2))) - SUM(CAST(withdrawal_amount AS DECIMAL (18, 2))) AS quarterly_aum
	FROM
		gold.fact_transactions
	WHERE
		transaction_date IS NOT NULL
	GROUP BY
		YEAR(transaction_date) ,
		DATEPART(QUARTER, transaction_date)
),
CulumativeAUM AS(
	SELECT
		fiscal_year,
		fiscal_quarter,
		quarterly_aum,
		SUM(quarterly_aum) OVER(ORDER BY fiscal_year,fiscal_quarter) AS culumative_aum
	FROM
		QuarterlyAUM
),
PrevCulumativeAUM AS(
	SELECT *,
		LAG(culumative_aum) OVER(ORDER BY fiscal_year,fiscal_quarter) AS prev_culumative_aum
	FROM
		CulumativeAUM
)
SELECT
	fiscal_year,
	fiscal_quarter,
	quarterly_aum,
	culumative_aum,
	prev_culumative_aum,
	CAST(ROUND(((culumative_aum/prev_culumative_aum)-1)*100, 2) AS DECIMAL (18,2)) AS qoq_perc
FROM
	PrevCulumativeAUM
ORDER BY
		fiscal_year,
		fiscal_quarter;
```
![visual](/visual_documentation/charts/quarterly_aum_and_qoq_changes.png)

*Bar chart visualizing QoQ Cumulative AUM change.This visualization was created with Python after importing my SQL query results*

Key Findings:

- Strong Initial Growth in 2020 : The first quarter of 2020 started with a relatively low AUM of $10.98M , but the cumulative AUM grew significantly by 492.75% QoQ  in Q2 2020, driven by a substantial quarterly AUM of $54.10M.

- Consistent Quarterly Growth Until 2021 : From Q2 2020 to Q4 2021, the cumulative AUM showed consistent growth, albeit at a declining QoQ percentage rate (from 492.75%  in Q2 2020 to 16.64%  in Q4 2021).

- Gradual Decline in Growth Rates : Starting from Q1 2022, the QoQ growth rates steadily decreased, ranging from 12.92%  in Q1 2022 to 3.31%  in Q1 2025, indicating slowing momentum in asset accumulation.

- Partial-Year Data for 2025 : The Q1 2025 data reflects only the first quarter of the year and shows a QoQ growth rate of 3.31% , which is the lowest recorded growth rate in the dataset. However, this is not directly comparable to previous full quarters due to the partial-year nature of the data.

- Peak Quarterly AUM : The highest quarterly AUM was recorded in Q2 2020  at $54.10M , contributing to the sharp initial growth.
     
## 2. Annual Client Retention Rate

- **Purpose:** The retention rate when is high indicates low churn (few clients leaving), while a low retention rate indicates high churn (many clients leaving).

- **Insight:** Identifies trends in client loyalty and retention effectiveness across different onboarding years, revealing patterns in long-term client engagement.

- **Value:** Supports strategic planning by uncovering retention strengths or weaknesses, helping the firm improve client experience and improving customer loyalty.

First I find the count of total clients who joined each year in the JoinedClients CTE and then those who remained active in the RetainedClients CTE, using a LEFT JOIN to align the two CTE s by year and calculate the retention rate as the percentage of retained clients relative to total clients joined, with the results ordered chronologically by year.

```sql
WITH JoinedClients AS (
	SELECT
		YEAR(create_date) AS year_joined,
		CAST(COUNT(client_key) AS DECIMAL (18, 2)) AS total_client_joined
	FROM
		gold.dim_clients
	WHERE
		create_date IS NOT NULL
	GROUP BY
		YEAR(create_date)
),
RetainedCients AS (
	SELECT
		YEAR(create_date) AS year_joined,
		CAST(COALESCE(COUNT(client_key), 0) AS DECIMAL (18, 2))  AS total_client_retained
	FROM
		gold.dim_clients
	WHERE
		create_date IS NOT NULL AND closure_date IS NULL
	GROUP BY
		YEAR(create_date)
)
SELECT
	j.year_joined,
	total_client_joined,
	total_client_retained,
	CAST(ROUND((COALESCE(r.total_client_retained, 0)/j.total_client_joined) * 100, 2) AS DECIMAL (18, 2)) AS retention_rate
FROM
	JoinedClients j
		LEFT JOIN RetainedCients r
	ON j.year_joined=r.year_joined
ORDER BY
	year_joined
```

![visual](/visual_documentation/charts/combined_retention_and_difference_chart.png)

*Bar chart visualizing annual client retention rate.This visualization was created with Python after importing my SQL query results*

For reference: 

Excellent Retention (90%–100%)

Good Retention (80%–89.99%)

Moderate Retention (70%–79.99%)

Fair Retention (60%–69.99%)

Poor Retention (Below 60%)

Key Findings : 

- Retention rates have remained stable, averaging 85%.
- The largest drop occurred between 2021 and 2022 (-1.11%).
- All years fall into the "Good Retention" category.
     
## 3. Client Portfolio Diversification & Risk Assessment

This query was designed as a Client Portfolio Diversification & Risk Assessment Tool.

- **Purpose:** This tool evaluates client portfolio diversification and risk concentration by analyzing product variety, portfolio value distribution, and risk exposure. It helps identify high-risk portfolios and areas for improvement in diversification strategies.
- **Insight:** It reveals how concentrated clients' portfolios are in specific products, highlighting potential risks. This enables targeted adjustments to improve portfolio diversification and reduce exposure.
- **Value:** Supports effective risk management by providing insights into portfolio concentration, helping optimize client portfolios and ensuring long-term stability.

### Query Overview: 

- ClientPortfolio CTE: I calculate each active client's net investment (invested minus withdrawn) grouped by product and client.

- TotalPortfolio CTE: I compute each client's total portfolio value by summing their net investments.

- DiversificationMetrics CTE: I measure the number of distinct product types and names, identify the top product's concentration as a percentage of the total portfolio, and classify the client into a risk category based on their diversification and concentration level.

- Final SELECT: I present each client's key diversification metrics, total portfolio value, top product concentration %, and assigned risk category, sorted by concentration and portfolio size.

```sql
WITH ClientPortfolio AS (
    SELECT 
        c.client_key,
        c.client_full_name,
        c.branch,
        c.country,
        p.product_type,
        p.product_name,
        SUM(t.invested_amount) - SUM(t.withdrawal_amount) AS net_portfolio_value
    FROM gold.fact_transactions t
    JOIN gold.dim_products p ON t.product_key = p.product_key
    JOIN gold.dim_clients c ON t.client_key = c.client_key
    WHERE t.transaction_date IS NOT NULL
        AND (t.invested_amount > 0 OR t.withdrawal_amount > 0)
        AND c.closure_date IS NULL -- Focus on active clients
    GROUP BY 
        c.client_key,
        c.client_full_name,
        c.branch,
        c.country,
        p.product_type,
        p.product_name
    HAVING SUM(t.invested_amount) - SUM(t.withdrawal_amount) > 0 
),
TotalPortfolio AS (
    SELECT 
        client_key,
        SUM(net_portfolio_value) AS total_client_portfolio
    FROM ClientPortfolio
    GROUP BY client_key
),
DiversificationMetrics AS (
    SELECT 
        cp.client_key,
        cp.client_full_name,
        cp.branch,
        cp.country,
        COUNT(DISTINCT cp.product_type) AS distinct_product_types,
        COUNT(DISTINCT cp.product_name) AS distinct_product_names,
        tp.total_client_portfolio,
        MAX(cp.net_portfolio_value) AS top_product_value,
        CAST(MAX(net_portfolio_value) AS DECIMAL(18,2)) / 
		NULLIF(CAST(total_client_portfolio AS DECIMAL(18,2)), 0) * 100 AS top_product_concentration_percent,
        CASE 
            WHEN COUNT(DISTINCT cp.product_type) = 1 
            THEN 'Very High Risk'
            WHEN COUNT(DISTINCT cp.product_type) = 2 
               AND CAST(MAX(net_portfolio_value) AS DECIMAL(18,2)) / 
			NULLIF(CAST(total_client_portfolio AS DECIMAL(18,2)), 0) * 100 >= 50
            THEN 'High Risk'
			WHEN COUNT(DISTINCT cp.product_type) = 2 
               AND CAST(MAX(net_portfolio_value) AS DECIMAL(18,2)) / 
			NULLIF(CAST(total_client_portfolio AS DECIMAL(18,2)), 0) * 100 < 50
            THEN 'Moderate Risk'
			WHEN COUNT(DISTINCT cp.product_type) = 3 
                AND CAST(MAX(net_portfolio_value) AS DECIMAL(18,2)) / 
			NULLIF(CAST(total_client_portfolio AS DECIMAL(18,2)), 0) * 100 >= 50 
            THEN 'Low Risk'
            ELSE 'Very Low Risk'
        END AS concentration_risk
    FROM ClientPortfolio cp
    JOIN TotalPortfolio tp ON cp.client_key = tp.client_key
    GROUP BY 
        cp.client_key,
        cp.client_full_name,
        cp.branch,
        cp.country,
        tp.total_client_portfolio
)
SELECT 
    client_key,
    client_full_name,
    branch,
    country,
    distinct_product_types,
    distinct_product_names,
    ROUND(total_client_portfolio, 2) AS total_portfolio_value,
    cast(ROUND(top_product_concentration_percent, 2) as decimal (18, 2)) AS top_product_concentration_percent,
    concentration_risk
FROM
	DiversificationMetrics
ORDER BY 
    top_product_concentration_percent DESC,
    total_portfolio_value DESC;
```

With this tool, you can evaluate each client's portfolio individually, or you can aggregate results by branch or clients' country of residence for broader insights. For example:

```sql
WITH ClientPortfolio AS (
    SELECT 
        c.client_key,
        c.client_full_name,
        c.branch,
        c.country,
        p.product_type,
        p.product_name,
        SUM(t.invested_amount) - SUM(t.withdrawal_amount) AS net_portfolio_value
    FROM gold.fact_transactions t
    LEFT JOIN gold.dim_products p ON t.product_key = p.product_key
    LEFT JOIN gold.dim_clients c ON t.client_key = c.client_key
    WHERE t.transaction_date IS NOT NULL
        AND (t.invested_amount > 0 OR t.withdrawal_amount > 0)
        AND c.closure_date IS NULL -- Focus on active clients
    GROUP BY 
        c.client_key,
        c.client_full_name,
        c.branch,
        c.country,
        p.product_type,
        p.product_name
    HAVING SUM(t.invested_amount) - SUM(t.withdrawal_amount) > 0 
),
TotalPortfolio AS (
    SELECT 
        client_key,
        SUM(net_portfolio_value) AS total_client_portfolio
    FROM
		ClientPortfolio
    GROUP BY
		client_key
),
DiversificationMetrics AS (
    SELECT 
        cp.client_key,
        cp.client_full_name,
        cp.branch,
        cp.country,
        COUNT(DISTINCT cp.product_type) AS distinct_product_types,
        COUNT(DISTINCT cp.product_name) AS distinct_product_names,
        tp.total_client_portfolio,
        MAX(cp.net_portfolio_value) AS top_product_value,
        CAST(MAX(net_portfolio_value) AS DECIMAL(18,2)) / 
		NULLIF(CAST(total_client_portfolio AS DECIMAL(18,2)), 0) * 100 AS top_product_concentration_percent,
        CASE 
            WHEN COUNT(DISTINCT cp.product_type) = 1 
            THEN 'Very High Risk'
            WHEN COUNT(DISTINCT cp.product_type) = 2 
               AND CAST(MAX(net_portfolio_value) AS DECIMAL(18,2)) / 
			NULLIF(CAST(total_client_portfolio AS DECIMAL(18,2)), 0) * 100 >= 50
            THEN 'High Risk'
			WHEN COUNT(DISTINCT cp.product_type) = 2 
               AND CAST(MAX(net_portfolio_value) AS DECIMAL(18,2)) / 
			NULLIF(CAST(total_client_portfolio AS DECIMAL(18,2)), 0) * 100 < 50
            THEN 'Moderate Risk'
			WHEN COUNT(DISTINCT cp.product_type) = 3 
                AND CAST(MAX(net_portfolio_value) AS DECIMAL(18,2)) / 
			NULLIF(CAST(total_client_portfolio AS DECIMAL(18,2)), 0) * 100 >= 50 
            THEN 'Low Risk'
            ELSE 'Very Low Risk'
        END AS concentration_risk
    FROM
		ClientPortfolio cp
		LEFT JOIN TotalPortfolio tp ON cp.client_key = tp.client_key
    GROUP BY 
        cp.client_key,
        cp.client_full_name,
        cp.branch,
        cp.country,
        tp.total_client_portfolio
),final as(
SELECT 
    client_key,
    client_full_name,
    branch,
    country,
    distinct_product_types,  
    distinct_product_names,
    ROUND(total_client_portfolio, 2) AS total_portfolio_value,
    CAST(ROUND(top_product_concentration_percent, 2) as decimal (18, 2)) AS top_product_concentration_percent,
    concentration_risk
FROM
	DiversificationMetrics
)
SELECT
    branch,
    COUNT(CASE WHEN concentration_risk = 'Very High Risk' THEN 1 END) AS very_high_risk_clients,
    COUNT(CASE WHEN concentration_risk = 'High Risk' THEN 1 END) AS high_risk_clients,
    COUNT(CASE WHEN concentration_risk = 'Moderate Risk' THEN 1 END) AS moderate_risk_clients,
	COUNT(CASE WHEN concentration_risk = 'Low Risk' THEN 1 END) AS low_risk_clients,
    COUNT(CASE WHEN concentration_risk = 'Very Low Risk' THEN 1 END) AS very_low_risk_clients
FROM
	final
WHERE
	branch IS NOT NULL
GROUP BY
	branch
ORDER BY
	branch;
```

Resullts:
| Branch      | Very High Risk Clients | High Risk Clients | Moderate Risk Clients | Low Risk Clients | Very Low Risk Clients |
|-------------|------------------------|-------------------|-----------------------|------------------|-----------------------|
| Amsterdam   | 34                     | 22                | 233                   | 30               | 408                   |
| Berlin      | 34                     | 25                | 219                   | 20               | 357                   |
| Bern        | 38                     | 30                | 262                   | 29               | 366                   |
| Canberra    | 35                     | 26                | 255                   | 29               | 375                   |
| London      | 37                     | 35                | 221                   | 29               | 363                   |
| n/a         | 5                      | 5                 | 29                    | 5                | 42                    |
| Ottawa      | 39                     | 15                | 235                   | 21               | 397                   |
| Paris       | 47                     | 17                | 254                   | 23               | 372                   |
| Seoul       | 37                     | 35                | 224                   | 28               | 343                   |
| Singapore   | 34                     | 27                | 243                   | 19               | 364                   |
| Stockholm   | 32                     | 22                | 236                   | 33               | 381                   |
| Tokyo       | 37                     | 22                | 226                   | 24               | 359                   |
| Washington  | 47                     | 24                | 248                   | 26               | 374                   |



![visual](/visual_documentation/charts/client_risk_distribution_with_numbers.png)

*Bar chart visualizing client risk distribution across branches. This visualization was created with Python after importing my SQL query results*


## 4. Employee Efficiency in Client Management

- **Purpose:** This query serves as a tool to evaluate and support the performance of employees in client management by using four key metrics as benchmarks. These metrics include:
1.	Number of clients handled
2.	Average client duration (tenure with the company)
3.	Average portfolio net value per client
4.	Total assets under management (AUM)

- **Insights:**  Each employee's metrics are compared against company-wide averages,allowing for easy identification of top performers.

- **Value:** Data-driven workforce development by uncovering employee strengths and areas for growth in client engagement and portfolio oversight.

### Query Overview: 

- ClientNetPortfolio CTE : Calculates the net portfolio value for each client. 

- OverallAverages CTE : Calculates organization-wide benchmarks by averaging key metrics across all employees using a subquery to first compute the average benchmark per employee.
         
-Final SELECT : Retrieves individual employee performance metrics and compares them against the overall benchmarks. 
  
```sql
WITH ClientNetPortfolio AS (
		   SELECT	        
				client_key,
		        SUM(invested_amount) - SUM(withdrawal_amount) AS portfolio_net_value
		    FROM gold.fact_transactions
		    GROUP BY client_key
		),
		OverallAverages AS (
		    SELECT
		        CAST(ROUND(AVG(client_count * 1.0), 2) AS DECIMAL (18, 2))  AS avg_clientscount_overall,
		        CAST(ROUND(AVG(avg_days * 1.0), 2) AS DECIMAL (18, 2)) AS avg_days_overall,
		        CAST(ROUND(AVG(avg_portfolio_net_value * 1.0), 2) AS DECIMAL (18, 2)) AS avg_net_value_overall,
				CAST(ROUND(AVG(total_aum * 1.0), 2) AS DECIMAL (18, 2)) AS avg_total_aum

		    FROM (
		        SELECT
		            f.employee_key,
		            COUNT(DISTINCT f.client_key) AS client_count,
		            AVG(DATEDIFF(DAY, c.create_date, COALESCE(c.closure_date, GETDATE()))) AS avg_days,
		            AVG(p.portfolio_net_value) AS avg_portfolio_net_value,
					SUM(portfolio_net_value) AS total_aum
		        FROM gold.fact_employee_client f
		        LEFT JOIN gold.dim_clients c ON f.client_key = c.client_key
		        LEFT JOIN ClientNetPortfolio p ON c.client_key = p.client_key
		        WHERE c.create_date IS NOT NULL
		        GROUP BY f.employee_key
		    ) AS per_employee
		)
		SELECT
		    e.employee_full_name,
		    COUNT(DISTINCT c.client_key) AS clientscount,
			a.avg_clientscount_overall,
		    AVG(DATEDIFF(DAY, c.create_date, COALESCE(c.closure_date, GETDATE()))) AS avg_days,
			 a.avg_days_overall,
		    AVG(p.portfolio_net_value) AS avg_portfolio_net_value,
			 a.avg_net_value_overall,
		    SUM(portfolio_net_value) as total_aum,
			 a.avg_total_aum
		    -- These are the reference benchmarks
FROM gold.dim_employees e
		LEFT JOIN gold.fact_employee_client f ON e.employee_key = f.employee_key
		LEFT JOIN gold.dim_clients c ON f.client_key = c.client_key
		LEFT JOIN ClientNetPortfolio p ON c.client_key = p.client_key
		CROSS JOIN OverallAverages a  -- This brings the overall averages into each row
WHERE 
	c.create_date IS NOT NULL
GROUP BY 
	e.employee_full_name, a.avg_clientscount_overall, a.avg_days_overall, a.avg_net_value_overall,a.avg_total_aum
ORDER BY 
	avg_days DESC;
```

To identify top performers (employees whose averages exceed company-wide averages across all key metrics):

```sql
WITH ClientNetPortfolio AS (
		   SELECT	        
				client_key,
		        SUM(invested_amount) - SUM(withdrawal_amount) AS portfolio_net_value
		    FROM gold.fact_transactions
		    GROUP BY client_key
		),
		OverallAverages AS (
		    SELECT
		        CAST(ROUND(AVG(client_count * 1.0), 2) AS DECIMAL (18, 2))  AS avg_clientscount_overall,
		        CAST(ROUND(AVG(avg_days * 1.0), 2) AS DECIMAL (18, 2)) AS avg_days_overall,
		        CAST(ROUND(AVG(avg_portfolio_net_value * 1.0), 2) AS DECIMAL (18, 2)) AS avg_net_value_overall,
				CAST(ROUND(AVG(total_aum * 1.0), 2) AS DECIMAL (18, 2)) AS avg_total_aum

		    FROM (
		        SELECT
		            f.employee_key,
		            COUNT(DISTINCT f.client_key) AS client_count,
		            AVG(DATEDIFF(DAY, c.create_date, COALESCE(c.closure_date, GETDATE()))) AS avg_days,
		            AVG(p.portfolio_net_value) AS avg_portfolio_net_value,
					SUM(portfolio_net_value) AS total_aum
		        FROM gold.fact_employee_client f
		        LEFT JOIN gold.dim_clients c ON f.client_key = c.client_key
		        LEFT JOIN ClientNetPortfolio p ON c.client_key = p.client_key
		        WHERE c.create_date IS NOT NULL
		        GROUP BY f.employee_key
		    ) AS per_employee
		),Final AS(
		SELECT
		    e.employee_full_name,
		    COUNT(DISTINCT c.client_key) AS clientscount,
			a.avg_clientscount_overall,
		    AVG(DATEDIFF(DAY, c.create_date, COALESCE(c.closure_date, GETDATE()))) AS avg_days,
			 a.avg_days_overall,
		    AVG(p.portfolio_net_value) AS avg_portfolio_net_value,
			 a.avg_net_value_overall,
		    SUM(portfolio_net_value) as total_aum,
			 a.avg_total_aum
		    -- These are the reference benchmarks
FROM gold.dim_employees e
		LEFT JOIN gold.fact_employee_client f ON e.employee_key = f.employee_key
		LEFT JOIN gold.dim_clients c ON f.client_key = c.client_key
		LEFT JOIN ClientNetPortfolio p ON c.client_key = p.client_key
		CROSS JOIN OverallAverages a  -- This brings the overall averages into each row
WHERE 
	c.create_date IS NOT NULL
GROUP BY 
	e.employee_full_name, a.avg_clientscount_overall, a.avg_days_overall, a.avg_net_value_overall,a.avg_total_aum
)
SELECT
	employee_full_name,
	clientscount,
	avg_clientscount_overall,
	avg_days,
	avg_days_overall,
	avg_portfolio_net_value,
	avg_net_value_overall,
	total_aum,
	avg_total_aum
From 
	Final
WHERE
	clientscount>avg_clientscount_overall AND avg_days>avg_days_overall AND avg_portfolio_net_value>avg_net_value_overall AND total_aum>avg_total_aum;
```




