
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
     