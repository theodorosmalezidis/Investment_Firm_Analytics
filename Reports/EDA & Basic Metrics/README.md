# EDA & BASIC METRICS

![visual](/visual_documentation/png/EDA_&_BASIC_METRICS.png)

There are three sections in this report:

## **1. Big Numbers:** Summarizes key metrics, providing a quick overview of business performance.


```sql
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
```

Results

### Key Metrics Summary

| Metric Name                     | Metric Value    |
|--------------------------------|------------------|
| Total AUM                      | 971799739        |
| Total Fees                     | 17759343.27      |                       
| Total Invested Amount          | 1452987114       |
| Total Withdrawn Amount         | 481187375        |
| Total Transactions Count       | 299042           |
| Total Investments Count        | 223207           |
| Total Withdrawals Count        | 75836            |
| Total Active Clients Count     | 8494             |
| Total Inactive Clients Count   | 1506             |
| Total Hired Employees Count    | 300              |
| Total Active Employees Count   | 282              |
| Total Former Employees Count   | 18               |
| Total Holdings Count           | 523              |

## **2. Segmentation & Distribution Analysis:** Try to identify patterns in regional performance, product popularity and performance, and long-term trends.

**a) Branch Analysis**

💡 This query analyzes the distribution of clients and the transaction volume across the branches of the firm while revealing regional perfomance and their contribution to the firm's total AUM and revenue.


 ```sql
 with clients_per_branch as 
					 (
					 select
						   e.branch
						 , c.client_key 
					from
						gold.fact_employee_client c
							 left join
								gold.dim_employees e
									on e.employee_key=c.employee_key
					),
client_totals as 
				(
				select
					  client_key
					, count(transaction_key) as transanctions_per_client
					, sum(fee_amount) as total_fee_per_client
					, sum(invested_amount-withdrawal_amount) as AUM_per_client
				from
					gold.fact_transactions
				group by
					client_key
				)
select
	  b.branch
	, count(distinct b.client_key) as branch_clients
	, sum(c.transanctions_per_client) as branch_transactions
	, sum(c.total_fee_per_client) as total_fees
	, sum(c.AUM_per_client) as total_AUM
	, cast((count(distinct b.client_key)*100.0)/sum(count(distinct b.client_key)) over() as decimal(10,2)) as perc_of_total_clients
	, cast((sum(c.transanctions_per_client)*100.0)/sum(sum(c.transanctions_per_client)) over() as decimal(10,2)) as perc_of_total_transactions
	, cast((sum(c.total_fee_per_client)*100.0)/sum(sum(c.total_fee_per_client)) over() as decimal(10,2)) as perc_of_total_fees
	, cast((sum(c.AUM_per_client)*100.0)/sum(sum(c.AUM_per_client)) over() as decimal(10,2)) as perc_of_total_AUM
from
	clients_per_branch b
		left join
			client_totals c
				on b.client_key=c.client_key 
group by
	branch
order by
    total_AUM desc
```


**Results**

| Branch | Clients | Transactions | Total Fees | Total AUM | % Clients | % Trans | % Fees | % AUM |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Berlin** | 1,134 | 33,704 | 1,986,901.58 | 110,642,778 | 11.34% | 11.28% | 11.23% | 11.42% |
| **Paris** | 1,147 | 34,432 | 2,007,322.42 | 107,682,037 | 11.47% | 11.52% | 11.35% | 11.12% |
| **Ottawa** | 1,083 | 32,600 | 1,925,058.68 | 105,053,944 | 10.83% | 10.91% | 10.88% | 10.84% |
| **Stockholm** | 967 | 28,319 | 1,724,048.76 | 95,892,745 | 9.67% | 9.47% | 9.74% | 9.90% |
| **Canberra** | 882 | 26,568 | 1,525,068.44 | 84,026,361 | 8.82% | 8.89% | 8.62% | 8.67% |
| **Bern** | 890 | 26,308 | 1,543,968.62 | 80,745,362 | 8.90% | 8.80% | 8.73% | 8.34% |
| **Singapore** | 835 | 24,915 | 1,478,772.49 | 79,967,504 | 8.35% | 8.34% | 8.36% | 8.25% |
| **Amsterdam** | 789 | 23,356 | 1,403,241.37 | 79,618,148 | 7.89% | 7.81% | 7.93% | 8.22% |
| **Seoul** | 783 | 23,220 | 1,392,709.83 | 76,505,891 | 7.83% | 7.77% | 7.87% | 7.90% |
| **Washington** | 556 | 16,526 | 962,497.61 | 54,448,561 | 5.56% | 5.53% | 5.44% | 5.62% |
| **London** | 474 | 14,308 | 853,042.96 | 46,367,711 | 4.74% | 4.79% | 4.82% | 4.79% |
| **Tokyo** | 432 | 12,870 | 776,187.24 | 41,577,947 | 4.32% | 4.31% | 4.39% | 4.29% |
| **n/a** | 28 | 1,764 | 113,255.50 | 6,204,318 | 0.28% | 0.59% | 0.64% | 0.64% |

**b) Product Type Analysis**

💡 Using first a cte to aggregate by product, then in main query i aggregate by product type to indentify the contribution of each type to firm' s total AUM, revenue and transactions. 

```sql
--create a cte to aggregate by product
with product_type_totals as
							(
							select
								p.product_type,
								p.product_key,
								isnull(sum(t.invested_amount)-sum(t.withdrawal_amount), 0) as product_AUM,
								isnull(sum(t.fee_amount), 0) as product_fees,
								count(t.transaction_key) as product_transactions
							from
								gold.dim_products p
									left join
										gold.fact_transactions t
											on 
												p.product_key=t.product_key
							group by
								p.product_type,
								p.product_key
							)
select														-- and the aggregate by product type in main query
	product_type,
	sum(product_transactions) as total_transactions,
	sum(product_AUM) as total_aum,--in USD
	sum(product_fees) as total_fees,--in USD
	cast(sum(product_transactions)*100.0/sum(sum(product_transactions)) over() as decimal(10,2)) as perc_of_total_transactions,--window function helps find perc of each product type s nr. of transactions in firm s total
	cast(sum(product_AUM)*100.0/sum(sum(product_AUM)) over() as decimal(10,2)) as perc_of_total_AUM,--window function helps find perc of each product type s total AUM in firm s total
	cast(sum(product_fees)*100.0/sum(sum(product_fees)) over() as decimal(10,2)) as perc_of_total_fees--window function helps find perc of each product type s total fees in firm s total
from		
	product_type_totals
group by
	product_type
order by
	total_aum desc;
```
**Results**

| Product Type | Transactions | Total AUM | Total Fees | % Trans | % AUM | % Fees |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **STOCK** | 259,200 | 838,678,216 | 16,677,155.00 | 86.69% | 86.56% | 93.91% |
| **ETF** | 23,172 | 77,370,512 | 754,510.65 | 7.75% | 7.99% | 4.25% |
| **BOND** | 16,640 | 52,809,234 | 327,677.62 | 5.56% | 5.45% | 1.85% |

**c) Transactions Analysis**

💡 This section analyzes typical behaviors through averages of invested and withdrawal amounts, extreme with the biggest single buys and sells moves, and the average fee the firm collects every time someone clicks "trade."
```sql
select
	count(transaction_key) as total_transactions,
	round(avg(invested_amount), 2) as avg_amount_per_invest,
    round(avg(withdrawal_amount), 2) as avg_amount_per_withdrawal,
    max(invested_amount) as mvit, --most valuable invested transaction
    min(NULLIF(invested_amount, 0)) as lvit, --least valuable invested transaction
	max(withdrawal_amount) as mvwt, --most valuable withdrawal transaction
    min(NULLIF(withdrawal_amount, 0)) as lvwt, --least valuable withdrawal transaction
	cast(avg(fee_amount) as decimal (10,2)) as avg_fee_per_transaction
from
	gold.fact_transactions;
```
**Results**

| Metric | Value |
| :--- | :--- |
| **Total Transactions** | 299,998 |
| **Avg. Amount per Invest** | 4,843.00 |
| **Avg. Amount per Withdrawal** | 1,603.00 |
| **Most Valuable Invested Transaction (mvit)** | 99,974.00 |
| **Least Valuable Invested Transaction (lvit)** | 100.00 |
| **Most Valuable Withdrawal (mvwt)** | 99,987.00 |
| **Least Valuable Withdrawal (lvwt)** | 100.00 |
| **Avg. Fee per Transaction** | 59.20 |


**d) Monthly Trends**

💡This is a time series analysis revealing the evolution of the firm from an early growth stage to a more mature status 
through monthly total transactions, AUM, revenue and averages invested and withdrawal amounts.

 ```sql
select 
	  datename(year, transaction_date) as year
    , datename(month, transaction_date) as month
    , count(transaction_key) AS monthly_transactions
	, sum(invested_amount)-sum(withdrawal_amount) as monthly_AUM
	, sum(fee_amount) as monthly_fees
	, cast(sum(invested_amount)/count(invested_amount ) as decimal (10,2)) as avg_invested_amount
	, cast(sum(withdrawal_amount)/count(withdrawal_amount ) as decimal (10,2)) as avg_withdrawal_amount
	, cast(sum(fee_amount)/count(fee_amount ) as decimal (10,2)) as avg_fee_amount_amount	
from
	gold.fact_transactions
group by
	  DATENAME(year, transaction_date)
	, DATENAME(month, transaction_date)
	, MONTH(transaction_date)
order by 
	  year
	, MONTH(transaction_date);
```


## **3. Rankings:** Top and worst performers across key areas highlighting leaders and trends.

**a) Holdings**

Provides top and worst perfoming holdings by total AUM.

💡 Shows high and low performing assets and areas needing improvement.


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


*Bar chart visualizing top 10 holdings by total AUM.This chart was created with Python after importing my SQL query results*

**b) Clients**

Provides top and worst perfoming clients by total transactions.

💡 Shows high and low performing clients to enhance client relationship management.


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


*Bar chart visualizing top 10 clients by total No. of investment orders.This chart was created with Python after importing my SQL query results*

**c) Employees**

Provides top and worst perfoming employees by total Portfolios managed.


💡 Shows high and low performing employees to support performance evaluations.

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


*Bar chart visualizing top 10 employees by total No. of Portfolios managed. This chart was created with Python after importing my SQL query results.*

