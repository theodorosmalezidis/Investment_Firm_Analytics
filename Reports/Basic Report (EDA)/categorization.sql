 /*Segments data by key dimensions to analyze contributions and distributions across the business.
*/



-- 1. Client Analysis


SELECT
	branch,
	COUNT (client_key) AS total_clients_count
FROM
	gold.dim_clients
GROUP BY
	branch
ORDER BY
	total_clients_count DESC;

SELECT
	country,
	COUNT (client_key) AS total_clients_count
FROM
	gold.dim_clients
GROUP BY
	country
ORDER BY
	total_clients_count DESC;

SELECT
	client_gender,
	COUNT (client_key) AS total_clients_count
FROM
	gold.dim_clients
GROUP BY
	client_gender
ORDER BY
	total_clients_count DESC;

SELECT
	client_marital_status,
	COUNT (client_key) AS total_clients_count
FROM
	gold.dim_clients
GROUP BY
	client_marital_status
ORDER BY
	total_clients_count DESC;





-- 2.Product Analysis (Holdings)

SELECT
	product_type,
	COUNT (product_key) AS total_products_count
FROM
	gold.dim_products
GROUP BY
	product_type
ORDER BY
	total_products_count DESC;



-- 3. AUM Analysis

SELECT
	product_type,
	SUM(invested_amount) - SUM(withdrawal_amount) AS total_aum
FROM
	gold.dim_products p
LEFT JOIN gold.fact_transactions t
ON p.product_key=t.product_key
GROUP BY
	product_type
ORDER BY
	total_aum DESC

SELECT
	branch,
	SUM(invested_amount) - SUM(withdrawal_amount) AS total_aum
FROM
	gold.dim_clients c
LEFT JOIN gold.fact_transactions t
ON c.client_key=t.client_key
GROUP BY
	branch
ORDER BY
	total_aum DESC;

SELECT
	country,
	SUM(invested_amount) - SUM(withdrawal_amount) AS total_aum
FROM
	gold.dim_clients c
LEFT JOIN gold.fact_transactions t
ON c.client_key=t.client_key
GROUP BY
	country
ORDER BY
	total_aum DESC;

--4. Employee Analysis

SELECT
	branch,
	COUNT (employee_id) AS total_employees_count
FROM
	gold.dim_employees
GROUP BY
	branch
ORDER BY
	total_employees_count DESC;

SELECT
	department,
	COUNT (employee_key) AS total_employees
FROM
	gold.dim_employees
GROUP BY
	department
ORDER BY
	total_employees DESC;
	
SELECT
	position,
	COUNT (employee_key) AS total_employees
FROM
	gold.dim_employees
GROUP BY
	position
ORDER BY
	total_employees DESC;

SELECT
	employee_gender,
	COUNT (employee_key) AS total_employees_count
FROM
	gold.dim_employees
GROUP BY
	employee_gender
ORDER BY
	total_employees_count DESC;

SELECT
	employee_marital_status,
	COUNT (employee_key) AS total_employees_count
FROM
	gold.dim_employees
GROUP BY
	employee_marital_status
ORDER BY
	total_employees_count DESC;

