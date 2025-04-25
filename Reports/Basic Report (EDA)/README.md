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