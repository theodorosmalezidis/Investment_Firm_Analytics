



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
