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
