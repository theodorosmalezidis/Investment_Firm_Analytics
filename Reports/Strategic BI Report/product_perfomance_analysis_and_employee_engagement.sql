



WITH ProductsStats AS(
	SELECT
		p.product_name,
		COUNT(DISTINCT employee_key) AS analyze_count,
		SUM(invested_amount)-SUM(withdrawal_amount) AS product_AUM,
		COUNT(DISTINCT client_key) AS invested_clients
	FROM
		gold.fact_employee_product e
	LEFT JOIN gold.dim_products p 
		ON e.product_key=p.product_key
	LEFT JOIN gold.fact_transactions t 
		ON p.product_key=t.product_key
	GROUP BY
		p.product_name
),
ProductsAvgs AS (
	SELECT
		CAST(ROUND(AVG(analyze_count * 1.0), 2) AS DECIMAL (18, 2)) AS avg_analyze_count,
		CAST(ROUND(AVG(product_AUM * 1.0), 2) AS DECIMAL (18, 2)) AS avg_product_AUM
	FROM ProductsStats
)
SELECT
	ps.product_name,
	ps.analyze_count,
	pa.avg_analyze_count,
	ps.product_AUM,
	pa.avg_product_AUM,
	invested_clients,
	CASE
		WHEN ps.analyze_count>=10 THEN 'Overanalyzed'
		WHEN ps.analyze_count>=5 THEN 'Sufficient_Analyzed'
		ELSE 'Underanalyzed'
		END AS analyze_valuation,
	CASE
		WHEN ps.product_AUM>=16000000 THEN 'Strong_Asset_Growth'
		WHEN ps.product_AUM>=8000000 THEN 'Moderate_Asset_Growth'
		ELSE 'Low_Asset_Growth'
		END AS AUM_valuation
FROM
	ProductsStats ps
	CROSS JOIN ProductsAvgs pa
WHERE
	PS.product_name IS NOT NULL
ORDER BY
	ps.analyze_count DESC
