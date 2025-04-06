/*Top and worst performers across key areas highlighting leaders and trends.
*/




-- HOLDINGS

-- Top 10 holdings by total investment value(excluding withdrawals).
SELECT *
FROM(
SELECT
	ROW_NUMBER() OVER(ORDER BY SUM(invested_amount) DESC) AS holdings_ranking,
	p.product_name,
	p.product_type,
	SUM(invested_amount) AS total_investment_value
FROM
	gold.dim_products p
LEFT JOIN gold.fact_transactions f
ON p.product_key=f.product_key
GROUP BY
	p.product_name,
	p.product_type) r
WHERE
	holdings_ranking <= 10
ORDER BY
	holdings_ranking;

--10 least invested holdings by total investment value(excluding withdrawals).
SELECT *
FROM(
SELECT
	ROW_NUMBER() OVER(ORDER BY SUM(invested_amount)) AS holdings_ranking,
	p.product_name,
	p.product_type,
	SUM(invested_amount) AS total_investment_value
FROM
	gold.dim_products p
LEFT JOIN gold.fact_transactions f
ON p.product_key=f.product_key
GROUP BY
	p.product_name,
	p.product_type) r
WHERE
	holdings_ranking <= 10
ORDER BY
	holdings_ranking;

-- Top 10 holdings by total AUM(including withdrawals).
SELECT *
FROM(
SELECT
	ROW_NUMBER() OVER(ORDER BY SUM(invested_amount)-SUM(withdrawal_amount) DESC) AS holdings_ranking,
	p.product_name,
	p.product_type,
	SUM(invested_amount)-SUM(withdrawal_amount) AS total_AUM
FROM
	gold.dim_products p
LEFT JOIN gold.fact_transactions f
ON p.product_key=f.product_key
GROUP BY
	p.product_name,
	p.product_type) r
WHERE
	holdings_ranking <= 10
ORDER BY
	holdings_ranking;

--Holdings with the 10 Lowest AUM (Including Withdrawals).
SELECT *
FROM(
SELECT
	ROW_NUMBER() OVER(ORDER BY SUM(invested_amount)-SUM(withdrawal_amount)) AS holdings_ranking,
	p.product_name,
	p.product_type,
	SUM(invested_amount)-SUM(withdrawal_amount) AS total_AUM
FROM
	gold.dim_products p
LEFT JOIN gold.fact_transactions f
ON p.product_key=f.product_key
GROUP BY
	p.product_name,
	p.product_type) r
WHERE
	holdings_ranking <= 10
ORDER BY
	holdings_ranking;

-- CLIENTS

--Top 10 Clients by AUM.
SELECT *
FROM(
SELECT
	ROW_NUMBER() OVER(ORDER BY SUM(invested_amount)-SUM(withdrawal_amount) DESC) AS clients_ranking,
	c.client_full_name,
	SUM(invested_amount)-SUM(withdrawal_amount) AS AUM
FROM
	gold.dim_clients c
LEFT JOIN gold.fact_transactions t
ON c.client_key=t.client_key
GROUP BY
	c.client_full_name) r
WHERE
	clients_ranking <= 10
ORDER BY
	clients_ranking;

--Clients with the 10 lowest AUM.
SELECT *
FROM(
SELECT
	ROW_NUMBER() OVER(ORDER BY SUM(invested_amount)-SUM(withdrawal_amount)) AS clients_ranking,
	c.client_full_name,
	SUM(invested_amount)-SUM(withdrawal_amount) AS AUM
FROM
	gold.dim_clients c
LEFT JOIN gold.fact_transactions t
ON c.client_key=t.client_key
GROUP BY
	c.client_full_name
HAVING
	SUM(invested_amount)-SUM(withdrawal_amount) IS NOT NULL
	AND SUM(invested_amount)-SUM(withdrawal_amount)>0) r
WHERE
	clients_ranking <= 10
ORDER BY
	clients_ranking;

-- Top 10 Clients by No. of Investments Placed.
SELECT *
FROM(
SELECT
	ROW_NUMBER() OVER(ORDER BY Count(invested_amount) DESC) AS clients_ranking,
	c.client_full_name,
	COUNT(invested_amount) AS investments_count
FROM
	gold.dim_clients c
LEFT JOIN gold.fact_transactions t
ON c.client_key=t.client_key
GROUP BY
	c.client_full_name) r
WHERE
	clients_ranking <= 10
ORDER BY
	clients_ranking;

--10 Clients with the lowest number of investments.
SELECT *
FROM(
SELECT
	ROW_NUMBER() OVER(ORDER BY Count(invested_amount)) AS clients_ranking,
	c.client_full_name,
	COUNT(invested_amount) AS investments_count
FROM
	gold.dim_clients c
LEFT JOIN gold.fact_transactions t
ON c.client_key=t.client_key
GROUP BY
	c.client_full_name
HAVING
	COUNT(invested_amount)>0) r
WHERE
	clients_ranking <= 10
ORDER BY
	clients_ranking;

-- EMPLOYEES

--Top 10 employees by number of active portfolios managed
SELECT *
FROM(
SELECT
	ROW_NUMBER() OVER(ORDER BY COUNT (c.client_key) DESC) AS employees_ranking,
	e.employee_full_name,
	COUNT (c.client_key) AS active_portfolios
FROM
	gold.dim_employees e
LEFT JOIN gold.fact_employee_client f
ON e.employee_key=f.employee_key
LEFT JOIN gold.dim_clients c
ON f.client_key=c.client_key
WHERE
	c.create_date IS NOT NULL
GROUP BY
	e.employee_full_name) r
WHERE
	employees_ranking <= 10
ORDER BY
	employees_ranking;

--Last 10 employees in active portfolio management by count.
SELECT *
FROM(
SELECT
	ROW_NUMBER() OVER(ORDER BY COUNT (c.client_key)) AS employees_ranking,
	e.employee_full_name,
	COUNT (c.client_key) AS active_portfolios
FROM
	gold.dim_employees e
LEFT JOIN gold.fact_employee_client f
ON e.employee_key=f.employee_key
LEFT JOIN gold.dim_clients c
ON f.client_key=c.client_key
WHERE
	c.create_date IS NOT NULL
GROUP BY
	e.employee_full_name) r
WHERE
	employees_ranking <= 10
ORDER BY
	employees_ranking;

--Top 10 employees by number of investment holdings analyzed.
SELECT *
FROM(
SELECT
	ROW_NUMBER() OVER(ORDER BY COUNT (p.product_key) DESC) AS employees_ranking,
	e.employee_full_name,
	COUNT (p.product_key) AS holdings_analyzed
FROM
	gold.dim_employees e
LEFT JOIN gold.fact_employee_product f
ON e.employee_key=f.employee_key
LEFT JOIN gold.dim_products p
ON f.product_key=p.product_key
GROUP BY
	e.employee_full_name) r
WHERE
	employees_ranking <= 10
ORDER BY
	employees_ranking;

--Last 10 employees by number of investment holdings analyzed count.
SELECT *
FROM(
SELECT
	ROW_NUMBER() OVER(ORDER BY COUNT (p.product_key)) AS employees_ranking,
	e.employee_full_name,
	COUNT (p.product_key) AS holdings_analyzed
FROM
	gold.dim_employees e
LEFT JOIN gold.fact_employee_product f
ON e.employee_key=f.employee_key
LEFT JOIN gold.dim_products p
ON f.product_key=p.product_key
GROUP BY
	e.employee_full_name
HAVING
	COUNT(p.product_key)>0) r
WHERE
	employees_ranking <= 10
ORDER BY
	employees_ranking;



