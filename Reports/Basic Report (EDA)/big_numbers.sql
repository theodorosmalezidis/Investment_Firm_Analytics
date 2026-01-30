/*   Summarizes key metrics, providing a quick overview of business performance.
*/



SELECT metric_name, metric_value
FROM (
	SELECT 'Total AUM' AS metric_name, SUM(invested_amount) - SUM(withdrawal_amount) AS metric_value, 1 AS order_column
    	FROM gold.fact_transactions --Assets Under Management in USD
	UNION ALL
   	SELECT 'Total Fees' AS metric_name, SUM(fee_amount ) AS metric_value, 2 AS order_column
    	FROM gold.fact_transactions --Total Fees Collected in USD
   	UNION ALL
	SELECT 'Total Invested Amount' AS metric_name, SUM(invested_amount) AS metric_value, 3 AS order_column
    	FROM gold.fact_transactions --in USD
   	UNION ALL
    	SELECT 'Total Withdrawn Amount' AS metric_name, SUM(withdrawal_amount) AS metric_value, 4 AS order_column
   	FROM gold.fact_transactions --in USD
    	UNION ALL
    	SELECT 'Total Transactions Count' AS metric_name, COUNT(DISTINCT transaction_id) AS metric_value, 5 AS order_column
    	FROM gold.fact_transactions
    	UNION ALL
	SELECT 'Total Investments Count' AS metric_name, COUNT(DISTINCT transaction_id) AS metric_value, 6 AS order_column
    	FROM gold.fact_transactions WHERE invested_amount != 0 
	UNION ALL
	SELECT 'Total Withdrawals Count' AS metric_name, COUNT(DISTINCT transaction_id) AS metric_value, 7 AS order_column
    	FROM gold.fact_transactions WHERE invested_amount = 0 
	UNION ALL
	SELECT 'Total Active Clients Count' AS metric_name, COUNT(client_key) AS metric_value, 8 AS order_column
    	FROM gold.dim_clients WHERE closure_date IS NULL -- Clients with Active Portfolios
	UNION ALL
	SELECT 'Total Inactive Clients Count' AS metric_name, COUNT(client_key) AS metric_value, 9 AS order_column
    	FROM gold.dim_clients WHERE  closure_date IS NOT NULL -- Clients with Inactive Portfolios
	UNION ALL
    	SELECT 'Total Hired Employees Count' AS metric_name, COUNT(employee_key) AS metric_value, 10 AS order_column
    	FROM gold.dim_employees
    	UNION ALL
	SELECT 'Total Active Employees Count' AS metric_name, COUNT(employee_key) AS metric_value, 11 AS order_column
    	FROM gold.dim_employees WHERE exit_date IS NULL -- Still Employed
    	UNION ALL
	SELECT 'Total Former Employees Count' AS metric_name, COUNT(employee_key) AS metric_value, 12 AS order_column
    	FROM gold.dim_employees WHERE exit_date IS NOT NULL --No longer Employed
   	UNION ALL
   	SELECT 'Total Holdings Count' AS metric_name, COUNT(product_name) AS metric_value, 13 AS order_column
    	FROM gold.dim_products --Holdings Under Management
) AS report
ORDER BY order_column