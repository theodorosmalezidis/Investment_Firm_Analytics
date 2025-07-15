WITH JoinedClients AS (
    SELECT
        YEAR(create_date) AS year_joined,
        CAST(COUNT(client_key) AS DECIMAL(18, 2)) AS total_client_joined
    FROM
        gold.dim_clients
    WHERE
        create_date IS NOT NULL
    GROUP BY
        YEAR(create_date)
),
RetainedClients AS (
    SELECT
        YEAR(create_date) AS year_joined,
        CAST(COUNT(client_key) AS DECIMAL(18, 2)) AS total_client_retained
    FROM
        gold.dim_clients
    WHERE
        create_date IS NOT NULL
          AND closure_date IS NULL
    GROUP BY
        YEAR(create_date)
),
RetentionRates AS (
    SELECT
        j.year_joined,
        j.total_client_joined,
        COALESCE(r.total_client_retained, 0) AS total_client_retained,
        CAST(ROUND((COALESCE(r.total_client_retained, 0) / j.total_client_joined) * 100, 2) AS DECIMAL(5, 2)) AS retention_rate
    FROM
        JoinedClients j
    LEFT JOIN
        RetainedClients r ON j.year_joined = r.year_joined
)
SELECT
    year_joined,
    total_client_joined,
    total_client_retained,
    retention_rate,
    CAST(ROUND(retention_rate - LAG(retention_rate) OVER (ORDER BY year_joined), 2) AS DECIMAL(5, 2)) AS yoy_retention_diff
FROM
    RetentionRates
ORDER BY
    year_joined;
