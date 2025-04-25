
# B) Advanced Report 

![visual](/visual_documentation/png/advanced_report.png)


This report is structured into five key sections , each of which I analyzed to provide comprehensive insights.

## 1. Annual Client Retention Rate

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
     