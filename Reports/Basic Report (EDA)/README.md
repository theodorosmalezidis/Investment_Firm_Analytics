# Basic Report (EDA)

![visual](/visual_documentation/png/basic_report.png)

There are three sections in basic report:

## **1. Big Numbers:** Summarizes key metrics, providing a quick overview of business performance.


```sql
SELECT metric_name, metric_value
FROM (
    SELECT 'Total AUM' AS metric_name, SUM(invested_amount) - SUM(withdrawal_amount) AS metric_value, 1 AS order_column
        FROM gold.fact_transactions --Assets Under Management in USD
    UNION ALL
    SELECT 'Total Invested Amount' AS metric_name, SUM(invested_amount) AS metric_value, 2 AS order_column
        FROM gold.fact_transactions --in USD
    UNION ALL
        SELECT 'Total Withdrawn Amount' AS metric_name, SUM(withdrawal_amount) AS metric_value, 3 AS order_column
    FROM gold.fact_transactions --in USD
        UNION ALL
        SELECT 'Total Transactions Count' AS metric_name, COUNT(DISTINCT transaction_id) AS metric_value, 4 AS order_column
        FROM gold.fact_transactions
        UNION ALL
    SELECT 'Total Investments Count' AS metric_name, COUNT(DISTINCT transaction_id) AS metric_value, 5 AS order_column
        FROM gold.fact_transactions WHERE invested_amount != 0 
    UNION ALL
    SELECT 'Total Withdrawals Count' AS metric_name, COUNT(DISTINCT transaction_id) AS metric_value, 6 AS order_column
        FROM gold.fact_transactions WHERE invested_amount = 0 
    UNION ALL
    SELECT 'Total Active Clients Count' AS metric_name, COUNT(client_key) AS metric_value, 10 AS order_column
        FROM gold.dim_clients WHERE closure_date IS NULL -- Clients with Active Portfolios
    UNION ALL
    SELECT 'Total Inactive Clients Count' AS metric_name, COUNT(client_key) AS metric_value, 11 AS order_column
        FROM gold.dim_clients WHERE  closure_date IS NOT NULL -- Clients with Inactive Portfolios
    UNION ALL
        SELECT 'Total Hired Employees Count' AS metric_name, COUNT(employee_key) AS metric_value, 12 AS order_column
        FROM gold.dim_employees
        UNION ALL
    SELECT 'Total Active Employees Count' AS metric_name, COUNT(employee_key) AS metric_value, 13 AS order_column
        FROM gold.dim_employees WHERE exit_date IS NULL -- Still Employed
        UNION ALL
    SELECT 'Total Former Employees Count' AS metric_name, COUNT(employee_key) AS metric_value, 14 AS order_column
        FROM gold.dim_employees WHERE exit_date IS NOT NULL --No longer Employed
    UNION ALL
    SELECT 'Total Holdings Count' AS metric_name, COUNT(product_name) AS metric_value, 15 AS order_column
        FROM gold.dim_products --Holdings Under Management
) AS report
ORDER BY order_column
```

Results

### Key Metrics Summary

| Metric Name                     | Metric Value     |
|--------------------------------|------------------|
| Total AUM                      | 971,799,739      |
| Total Invested Amount          | 1,452,987,114    |
| Total Withdrawn Amount         | 481,187,375      |
| Total Transactions Count       | 299,042          |
| Total Investments Count        | 223,207          |
| Total Withdrawals Count        | 75,836           |
| Total Active Clients Count     | 8,494            |
| Total Inactive Clients Count   | 1,506            |
| Total Hired Employees Count    | 300              |
| Total Active Employees Count   | 282              |
| Total Former Employees Count   | 18               |
| Total Holdings Count           | 523              |

## **2. Categorization:** Segments data by key dimensions to analyze contributions and distributions across the business.

**a) Client Analysis**

These queries categorize and count clients across different dimensions to help understand customer distribution.

By Branch: Number of clients managed per branch.

By Country: Geographic distribution of the client base.

By Gender: Gender-based segmentation of clients.

By Marital Status: Analysis of client marital demographics.

💡 Useful for assessing geographic concentration, diversity, and service spread.

For example:
 ```sql
        SELECT
    branch,
    COUNT (client_key) AS total_clients_count
FROM
    gold.dim_clients
GROUP BY
    branch
ORDER BY
    total_clients_count DESC;
```
![visual](/visual_documentation/charts/total_clients_per_branch.png)

*Bar chart visualizing total clients per branch.This table visualization was created with Python after importing my SQL query results*

**b) Product Analysis (Holdings)**

Analyzes the count of financial products held by clients, segmented by product type:

By Product Type: Shows how many unique products (e.g., stocks, bonds, ETFs) exist under each category.

💡 Highlights the product mix and can support decisions about offering more diversified or targeted financial products.

```sql
SELECT
    product_type,
    COUNT (product_key) AS total_products_count
FROM
    gold.dim_products
GROUP BY
    product_type
ORDER BY
    total_products_count DESC;
```
![visual](/visual_documentation/charts/product_count_by_type.png)

*Bar chart visualizing total products by type.This table visualization was created with Python after importing my SQL query results*

**c) AUM (Assets Under Management) Analysis**

This section calculates net AUM by subtracting total withdrawals from total investments, allowing you to understand how assets are distributed across various business dimensions:

By Product Type: Displays total net AUM held in each type of financial product (e.g., stocks, bonds, ETFs).

By Branch: Highlights the total AUM managed by each branch, useful for understanding asset distribution.

By Country: Breaks down AUM by client country to see how asset holdings are spread geographically.

For example:
```sql

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
    total_aum DESC;
```
![visual](/visual_documentation/charts/aum_by_product_type.png)

*Bar chart visualizing total AUM by product type.This table visualization was created with Python after importing my SQL query results*

**d) Employee Analysis**

Provides a breakdown of employees across different organizational dimensions:

By Branch: Employee count per branch.

By Department: Breakdown by operational function (e.g., Sales, Support).

By Position: Insights into workforce structure and role distribution.

By Gender: Gender-based segmentation of employees.

By Marital Status: Demographic insight for HR and policy-making.

💡 Supports workforce planning, HR diversity assessments, and departmental resource allocation.

For example:
 ```sql
SELECT
	position,
	COUNT (employee_key) AS total_employees
FROM
	gold.dim_employees
GROUP BY
	position
ORDER BY
	total_employees DESC;
```
![visual](/visual_documentation/charts/employee_positions.png)


*Bar chart visualizing total employees per position.This table visualization was created with Python after importing my SQL query results*


## **3. Rankings:** Top and worst performers across key areas highlighting leaders and trends.

**a) Holdings**

Provides top and worst perfoming holdings across diferrent dimansions:

By total Investment Value.

By total AUM.

💡 Shows high and low performing assets and areas needing improvement.

For example:
```sql
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
```

![visual](/visual_documentation/charts/top_10_holdings_by_AUM.png)


*Bar chart visualizing top 10 holdings by total AUM.This table visualization was created with Python after importing my SQL query results*

**b) Clients**

Provides top and worst perfoming clients across diferrent dimansions:

By total AUM.

By total Investments Placed.

For example:
```sql
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
```

![visual](/visual_documentation/charts/top_10_clients_by_investment_count.png)


*Bar chart visualizing top 10 clients by total No. of investment orders.This table visualization was created with Python after importing my SQL query results*

**b) Employees**

Provides top and worst perfoming employees across diferrent dimansions:

By total Portfolio managed.

By total Holdings analyzed.

For example:
```sql
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
```

![visual](/visual_documentation/charts/top_10_employees_by_active_portfolios.png)


*Bar chart visualizing top 10 employees by total No. of Portfolio managed.This table visualization was created with Python after importing my SQL query results*

