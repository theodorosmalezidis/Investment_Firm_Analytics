WITH JoinedClients AS (
    SELECT
        YEAR(create_date) AS cohort_year,
        COUNT(client_key) AS total_joined
    FROM
        gold.dim_clients
    WHERE
        create_date IS NOT NULL
    GROUP BY
        YEAR(create_date)
),
RetainedNextYear AS (
    SELECT
        YEAR(create_date) AS cohort_year,
        COUNT(client_key) AS total_retained_next_year
    FROM
        gold.dim_clients
    WHERE
        create_date IS NOT NULL
        AND (
            closure_date IS NULL
            OR closure_date > DATEFROMPARTS(YEAR(create_date) + 1, 12, 31)
        )
    GROUP BY
        YEAR(create_date)
),
RetentionRates AS (
    SELECT
        j.cohort_year,
        j.total_joined,
        COALESCE(r.total_retained_next_year, 0) AS total_retained_next_year,
        CAST(
            ROUND(
                (COALESCE(r.total_retained_next_year, 0) * 100.0) / j.total_joined,
                2
            ) AS DECIMAL(5, 2)
        ) AS retention_rate
    FROM
        JoinedClients j
        LEFT JOIN RetainedNextYear r ON j.cohort_year = r.cohort_year
)
SELECT
    cohort_year,
    total_joined,
    total_retained_next_year,
    retention_rate,
    CAST(
        ROUND(
            retention_rate - LAG(retention_rate) OVER (ORDER BY cohort_year),
            2
        ) AS DECIMAL(5, 2)
    ) AS yoy_retention_diff
FROM
    RetentionRates
ORDER BY
    cohort_year;
