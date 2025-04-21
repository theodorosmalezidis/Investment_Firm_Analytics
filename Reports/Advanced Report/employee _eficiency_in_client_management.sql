/*a. Employee Benchmarking Tool*/

WITH ClientNetPortfolio AS (
	SELECT	        
		client_key,
		SUM(invested_amount) - SUM(withdrawal_amount) AS portfolio_net_value
	FROM
		gold.fact_transactions
	GROUP BY 
		client_key
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
		WHERE
			c.create_date IS NOT NULL
		GROUP BY
			f.employee_key
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
FROM
	gold.dim_employees e
	LEFT JOIN gold.fact_employee_client f ON e.employee_key = f.employee_key
	LEFT JOIN gold.dim_clients c ON f.client_key = c.client_key
	LEFT JOIN ClientNetPortfolio p ON c.client_key = p.client_key
	CROSS JOIN OverallAverages a
WHERE 
	c.create_date IS NOT NULL
GROUP BY 
	e.employee_full_name,
	a.avg_clientscount_overall,
	a.avg_days_overall, a.avg_net_value_overall,
	a.avg_total_aum
ORDER BY 
	avg_days DESC;


/*b.	Top Performers */

WITH ClientNetPortfolio AS (
	SELECT	        
		client_key,
		SUM(invested_amount) - SUM(withdrawal_amount) AS portfolio_net_value
	FROM
		gold.fact_transactions
	GROUP BY 
		client_key
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
		WHERE
			c.create_date IS NOT NULL
		GROUP BY
			f.employee_key
		) AS per_employee
), Final AS (
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
	FROM
		gold.dim_employees e
		LEFT JOIN gold.fact_employee_client f ON e.employee_key = f.employee_key
		LEFT JOIN gold.dim_clients c ON f.client_key = c.client_key
		LEFT JOIN ClientNetPortfolio p ON c.client_key = p.client_key
		CROSS JOIN OverallAverages a
	WHERE 
		c.create_date IS NOT NULL
	GROUP BY 
		e.employee_full_name,
		a.avg_clientscount_overall,
		a.avg_days_overall, a.avg_net_value_overall,
		a.avg_total_aum
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
	clientscount>avg_clientscount_overall
	AND avg_days>avg_days_overall
	AND avg_portfolio_net_value>avg_net_value_overall
	AND total_aum>avg_total_aum;






