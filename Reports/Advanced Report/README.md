
# B) Advanced Report 

![visual](/visual_documentation/png/advanced_report.png)


This report is structured into five key sections , each of which I analyzed to provide comprehensive insights.

## 1. Annual Client Retention Rate

- **Purpose:** Measures the percentage of clients retained over time by comparing newly onboarded clients with those who remain active, grouped by year of acquisition.

- **Insight:** Identifies trends in client loyalty and retention effectiveness across different onboarding years, revealing patterns in long-term client engagement.

- **Value:** Supports strategic planning by uncovering retention strengths or weaknesses, helping the firm improve client experience, reduce churn, and allocate resources toward higher-retention segments.

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

![visual](/visual_documentation/charts/client_retention_rate_by_year.png)

*Bar chart visualizing annual client retention rate.This visualization was created with Python after importing my SQL query results*