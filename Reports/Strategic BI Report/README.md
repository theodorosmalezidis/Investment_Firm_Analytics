
# B) Strategic BI Report

![visual](/visual_documentation/png/strategic_bi_report.png)


This report is structured into five specialized modules designed to assess the firm's growth trajectory and employee performance so far, to identify growth opportunities and quantify the risk concentration across the client portfolio.

## 1. Net Flows Performance Over Time

To provide a clear view of the organic growth of the firm, i calculated the quartely Net Flow , and the YoY change(%). Comparing each quarter against the equivalent period of the previous year, i isolated seasonality noise revealing the true growth of new capital. 


```sql
WITH QuarterlyNF AS -- cte to calculate quarterly Net Flows
					(
						SELECT 
							YEAR(transaction_date) AS fiscal_year,
							DATEPART(QUARTER, transaction_date) AS fiscal_quarter,
							CAST(SUM(invested_amount) - SUM(withdrawal_amount) AS DECIMAL(20, 2)) AS quarterly_nf
						FROM gold.fact_transactions
						WHERE transaction_date IS NOT NULL
						GROUP BY 
							YEAR(transaction_date),
							DATEPART(QUARTER, transaction_date)
					),
PrevQuarterlyNF AS -- cte to get previous year's same quarter Net Flows
					(
						SELECT *,
							LAG(quarterly_nf, 4) OVER(ORDER BY fiscal_year,fiscal_quarter) AS same_q_previous_y
						FROM
							QuarterlyNF
					)
SELECT
	fiscal_year,
	fiscal_quarter,
	quarterly_nf,
	same_q_previous_y,
	CAST(ROUND(((quarterly_nf/NULLIF(same_q_previous_y, 0))-1)*100, 2) AS DECIMAL (18,2)) AS yoy_perc -- added NULLIF to avoid division by zero, calculating YoY percentage change
FROM
	PrevQuarterlyNF
ORDER BY
		fiscal_year,
		fiscal_quarter;
```        

![visual](/visual_documentation/charts/net_flows_over_time.png)

*Bar chart visualizing Quartely Net Flow and YoY change(%).This visualization was created with Python after importing my SQL query results*

Key Findings (keep in mind data is current up to March 2025):


- **Aggressive start:** Strong start in the first year of the firm suggesting a successful "launch" or a major marketing campaign that quintupled the net flow in a single quarter(Q1 2020 ($11M) to Q2 2020 ($54.1M)).

- **Stabilization phase:** Looking at the YoY Change (%) line after 2021, the percentages hover from the 6.1 % to -12% range, signaling an early begining of stabilization phase with new capital in the range of 45M to 50M (instead of sustained growth phase) but with a slightly deceleration in growth of new capital.

- **Major red flag:** A significant decrease in first quarter of 2025 almost 27% YoY, signals a major red flag, and since this analysis isolates seasonality we have to ask where this decrease is coming from, is the firm losing some major institutional clients or there has been a spike in withdrawals?


## 2. Fees Performance Over Time

Here we swift the focus from Capital Volume to Revenue, in the previous query i analyzed the 'Stream' of capital flow now i am passing to the 'Monetization' of that capital. By calculating YoY Fee Change (%), i can determine if our revenue is driven by a few high-fee transactions or a consistent volume of smaller ones. I hope that this will help clarify  if the 2025 'Red Flag' is caused by either a total halt in client activity, a drastic reduction in number of active clients  or simply a shift toward lower-fee products.

```sql
WITH QuarterlyRevenue AS (
    SELECT 
        YEAR(transaction_date) AS fiscal_year,
        DATEPART(QUARTER, transaction_date) AS fiscal_quarter,
        CAST(SUM(fee_amount) AS DECIMAL(20, 2)) AS quarterly_revenue
    FROM gold.fact_transactions
    WHERE transaction_date IS NOT NULL
    GROUP BY 
        YEAR(transaction_date),
        DATEPART(QUARTER, transaction_date)
),
PrevQuarterlyRevenue AS(
	SELECT *,
		LAG(quarterly_revenue, 4) OVER(ORDER BY fiscal_year,fiscal_quarter) AS same_q_previous_y
	FROM
		QuarterlyRevenue
)
SELECT
	fiscal_year,
	fiscal_quarter,
	quarterly_revenue,
	same_q_previous_y,
	CAST(ROUND(((quarterly_revenue/NULLIF(same_q_previous_y, 0))-1)*100, 2) AS DECIMAL (18,2)) AS yoy_perc
FROM
	PrevQuarterlyRevenue
ORDER BY
		fiscal_year,
		fiscal_quarter;
```
![visual](/visual_documentation/charts/fees_over_time.png)

*Bar chart visualizing Quartely Revenue(fees) and YoY change(%).This visualization was created with Python after importing my SQL query results*

Key Findings:

Comparing the two charts, something stands out very clearly: **The firm’s revenue is a "Mirror Metric" of its capital volume.** 

That proves that the firm's monetization model is transaction-heavy. This is a problem for two reasons. First the firm isn't "making money while it sleeps" on the assets it already holds and second the risk of clients stop moving money (even if they don't leave), where the revenue vanishes. 

Here comes my recommentation of a **Recurring Revenue Model** through Assets Under Management (AUM) fees. that the firm has to establish and create a more predictable revenue stream of management fees.

This way the firm will create and add to the existing 'transaction fee' revenue stream a more predictable one of management fees.
     
## 3. Cumulative Client Retention Rate


My purpose here is to find the Retention Rate not in a cohort view but for the 
total cumulative base of clients. I want to measure loyalty-specifically, how many total clients 
remain with the company year-over-year for two reasons:

1. To determine if the significant decrease of capital flow and revenue in Q1 of 
2025 is a result of a big churn crisis(losing clients) or inactivity(clients are staying but not transacting).

2. Depending on the findings, to validate if a new stream of recurring 
revenue (management fees) can have an impact on the firm's financials or more drastic measures have to be taken to address client loss.

So i came up with this formula, (E-N)/S where:
E = total clients in the end of year
N = total new clients for that year
S= total clients in the start of the year.

```sql
-- I'll use a CTE to define the client metrics for each fiscal year
with YearlyCounting as
					(select
						 year(create_date) as fiscal_year,
						 -- calculate the total count of clients at the start of the year
						 (select
								count(client_key)
							from
								gold.dim_clients
							where
								create_date<DATEFROMPARTS(year(c.create_date), 1, 1)
									and (closure_date is null or closure_date>=DATEFROMPARTS(year(create_date), 1, 1))
						) as start_of_year_count,
						-- calculate all the new client acquisitions during the year
						 count(client_key) as new_clients_count,
						 -- calculate the total count of clients at the end of the year
						 (select
								count(client_key)
							from
								gold.dim_clients 
							where
								create_date<=DATEFROMPARTS(year(c.create_date), 12, 31)
									and (closure_date is null or closure_date>DATEFROMPARTS(year(create_date), 12, 31))
						) as end_of_year_count
					from
						gold.dim_clients c
					group by
						year(create_date)
				 )
select
	fiscal_year,
	start_of_year_count,
	new_clients_count,
	end_of_year_count,
	-- calculate the retention rate by the formula (E-N)*100/S
	-- This isolates existing client loyalty by removing the impact of new sign-ups.
	round(cast((end_of_year_count-new_clients_count)*100.0/nullif (start_of_year_count, 0) as decimal (5,2)), 2) as cumulative_retention_rate
from
	YearlyCounting
where
	start_of_year_count>0
order by
	fiscal_year
```

![visual](/visual_documentation/charts/cumulative_ret_rate.png)

*Bar chart visualizing Cumulative Client Retention Rate.This visualization was created with Python after importing my SQL query results*

Key findings: 

- Acquisition of new clients is steady and predictable (projecting ~2,000 new clients for 2025), meaning the company is healthy and growing and propably eliminating any "bad marketing" as a root cause for the revenue drop.

- Cumulative Retention Rate showing a very strong and loyal client base, showing a continious growth and currently at all tme high at 97,57%.

- Analysis reveals a clear "disconnection" between the growing client base and the decrease in capital flow and revenue especially in Q1 of 2025 indicating that the problem is the inactivity(clients are staying but not transacting) and that a new recurring revenue of Management Fee to monetize the nearly 10,000 loyal clients who are staying with the firm will be crucial to company's Total Sales.

     


## 4. Employee Performance & Efficiency 


As i stated, one of the stakeholders problems is that they couldn't quantify their employee’s productivity, efficiency and perfomance. So i constructed a 'tool' for that exact purpose. I created a temp table to evaluate the performance of employees in client management and their efficiency, by using four key metrics as benchmarks. These metrics are:
1.	Number of clients handled
2.	Average client duration (tenure with the company, loyalty)
3.	Average portfolio net flow per client(new capital capture)
4.	Total Net Flow (TNF, measures the advisor's total impact) 


 Each employee's metrics are compared against company-wide averages, so we can distinguish between advisors who are simply 'sitting on' old accounts and those who are actively driving Net New Assets. It allows leadership to identify 'High-Efficiency' managers who maintain long-term client loyalty (Tenure) while consistently capturing a higher-than-average share of the client's wallet (Net Flow).

 By storing these results as a temp table, allows any bi analyst to perform instant analysis—such as ranking top performers in any of the metrics included.



### Query Overview: 

- Step 1: Calculate Total Net Flow per Client. 

- Step 2: Aggregate everything at the Employee level FIRST.
         
- Step 3: Calculate Firm Averages as Bencmarks.

- Step 4: Final query where i join Employee Stats with Firm Bennchmarks

- Step 5: Create the temp table
  
```sql
-- Step 1: Calculate Total Net Flow per Client
with ClientNetFlow as 
					(select           
						client_key,
						sum(invested_amount) - sum(withdrawal_amount) as total_client_net_flow
					from
						gold.fact_transactions
					group by
						client_key
					),
-- Step 2: Aggregate everything at the Employee level FIRST
EmployeeMetrics as 
				(select
					e.employee_full_name,
					count(distinct c.client_key) as clientscount,
					cast(avg(datediff(day, c.create_date, coalesce(c.closure_date, getdate())) * 1.0) as decimal(18, 2)) as avg_days,        
					avg(p.total_client_net_flow) as avg_net_flow_per_client,
					sum(p.total_client_net_flow) as total_employee_net_flow
				from gold.dim_employees e
					left join gold.fact_employee_client f 
					on e.employee_key = f.employee_key
						left join gold.dim_clients c 
						on f.client_key = c.client_key
							left join ClientNetFlow p 
							on c.client_key = p.client_key
				where
					c.create_date IS NOT NULL
				group by
					e.employee_full_name
			    ),

-- Step 3: Calculate Firm Averages as Benchmarks
FirmMetrics as
				(select
					cast(avg(clientscount * 1.0) as decimal(18,2)) as avg_clientscount_overall,
					cast(avg(avg_days) as decimal(18,2)) as avg_days_overall,
					cast(avg(avg_net_flow_per_client) as decimal(18,2)) as avg_net_flow_overall,
					cast(avg(total_employee_net_flow) as decimal(18,2)) as avg_total_flow_overall
				from
					EmployeeMetrics
				)

-- Final Selection: Joining Employee Stats with Firm Benchmarks
SELECT
    e.employee_full_name,
    e.clientscount,
    f.avg_clientscount_overall,
    ROUND(e.avg_days, 2) AS avg_days,
    f.avg_days_overall,
    ROUND(e.avg_net_flow_per_client, 2) AS avg_net_flow_per_client,
    f.avg_net_flow_overall,
    ROUND(e.total_employee_net_flow, 2) AS total_net_flow,
    f.avg_total_flow_overall
into
	#FinalEmployeeTool -- 'select into' store it as temp table for instant bi analysis
from 
	EmployeeMetrics e
cross join
	FirmMetrics f
order by
	e.avg_days desc;
```


## 5. Client Portfolio Diversification & Risk Assessment

The last concern the firm had was the stability of their clients portfolios. And with the data available i thought that i could construct another tool suitable for this task. So based on the number of different products and the concetration of capital flow into them, as metrics,i created the following diversification and risk assesment tool. I also stored the reaults as temp table for future bi analysis available (an example for usefull analysis will follow). Based on results the managers should reasses the dangers in clients portofolios and aim for diversification or deconcetration leading to firm's stability.



### Query Overview: 

- Step 1: Calculate Net Flow at the Client-Product level

- Step 2: Aggregate Net Flow to Client Total 

- Step 3: Calculate Concentration Metrics (Diversification & Weight)

-Step 4 : FinaL Query and Risk Categorization

```sql
-- Step 1: Calculate Net Flow at the Client-Product level

with ClientPortfolio as 
						(select 
							c.client_key,
							c.client_full_name,
							c.branch,
							c.country,
							p.product_type,
							p.product_name,
							sum(t.invested_amount) - sum(t.withdrawal_amount) as net_flow_value
						from
							gold.fact_transactions t
								join gold.dim_products p on t.product_key = p.product_key
									join gold.dim_clients c on t.client_key = c.client_key
						where
							t.transaction_date is not null
							and (t.invested_amount > 0 or t.withdrawal_amount > 0)
							and c.closure_date is null -- Focus on active clients
						group by 
							c.client_key,
							c.client_full_name,
							c.branch,
							c.country,
							p.product_type,
							p.product_name
						having
							sum(t.invested_amount) - sum(t.withdrawal_amount) > 0 
						),
-- Step 2: Aggregate Net Flow to Client Total 
TotalPortfolio as 
				(select 
					client_key,
					sum(net_flow_value) as total_client_net_flow
				from
					ClientPortfolio
				group by
					client_key
				 ),
-- Step 3: Calculate Concentration Metrics (Diversification & Weight)
CalcMetrics as 
						(select 
							cp.client_key,
							cp.client_full_name,
							cp.branch,
							cp.country,
							count(distinct cp.product_name) as distinct_product_names,
							tp.total_client_net_flow,
							max(cp.net_flow_value) as top_product_value,-- metric 1
							cast(max(cp.net_flow_value) * 100.0 / nullif(tp.total_client_net_flow , 0) as decimal (10,2)) as top_pct -- metric 2 concetration on top product
						from
							ClientPortfolio cp
								join TotalPortfolio tp ON cp.client_key = tp.client_key
						group by 
							cp.client_key,
							cp.client_full_name,
							cp.branch,
							cp.country,
							tp.total_client_net_flow
						)
--Step 4 : FinaL Query and Risk Categorization
SELECT 
    client_key,
    client_full_name,
    branch,
    country,
    distinct_product_names,
    round(total_client_net_flow, 2) AS total_flow_value,
    top_pct as max_asset_concentration_pct, 
	case
		when distinct_product_names <= 5 or top_pct >= 50 
            then 'Very High Risk'
		when distinct_product_names between 5 and 10 and top_pct >= 50 
            then 'High Risk'
		 when distinct_product_names >10 and top_pct > 30 
            then 'Moderate Risk'
		when distinct_product_names > 10 and top_pct < 30 
            then 'Low Risk'
		else 'Very Low Risk'
		end as concentration_risk
into
	#ConcetrationRiskTool -- 'select into' store it as temp table for instant bi analysis
from
	CalcMetrics
order by 
    max_asset_concentration_pct desc,
    total_flow_value desc;
```

With this tool, stored as temp table, you can evaluate each client's portfolio individually, or you can aggregate results by branch or clients' country of residence for broader insights. For example:

```sql
SELECT
    branch,
    COUNT(CASE WHEN concentration_risk = 'Very High Risk' THEN 1 END) AS very_high_risk_clients,
    COUNT(CASE WHEN concentration_risk = 'High Risk' THEN 1 END) AS high_risk_clients,
    COUNT(CASE WHEN concentration_risk = 'Moderate Risk' THEN 1 END) AS moderate_risk_clients,
	COUNT(CASE WHEN concentration_risk = 'Low Risk' THEN 1 END) AS low_risk_clients,
    COUNT(CASE WHEN concentration_risk = 'Very Low Risk' THEN 1 END) AS very_low_risk_clients
FROM
	#ConcetrationRiskTool
WHERE
	branch IS NOT NULL
GROUP BY
	branch
ORDER BY
	branch;
```

Resullts:
| Branch      | Very High Risk Clients | High Risk Clients | Moderate Risk Clients | Low Risk Clients | Very Low Risk Clients |
|-------------|------------------------|-------------------|-----------------------|------------------|-----------------------|
| Amsterdam   | 57                     | 0                 | 248                   | 422              | 0                     |
| Berlin      | 49                     | 0                 | 238                   | 366              | 2                     |
| Bern        | 61                     | 0                 | 248                   | 414              | 2                     |
| Canberra    | 57                     | 0                 | 241                   | 419              | 3                     |
| London      | 72                     | 0                 | 229                   | 379              | 5                     |
| n/a         | 11                     | 0                 | 32                    | 43               | 0                     |
| Ottawa      | 37                     | 0                 | 289                   | 377              | 4                     |
| Paris       | 47                     | 0                 | 270                   | 393              | 3                     |
| Seoul       | 68                     | 0                 | 245                   | 351              | 3                     |
| Singapore   | 52                     | 0                 | 247                   | 386              | 2                     |
| Stockholm   | 57                     | 0                 | 229                   | 416              | 2                     |
| Tokyo       | 49                     | 0                 | 217                   | 402              | 0                     |
| Washington  | 56                     | 0                 | 255                   | 406              | 2                     |



![visual](/visual_documentation/charts/portfolio_risk_dist.png)

*Bar chart visualizing client risk distribution across branches. This visualization was created with Python after importing my SQL query results*
  

From the results of the risk distribution across branches some key points that stand out:

1. The "High Risk" Gap: The data shows zero clients in the "High Risk" category across all branches. This indicates that clients either fail the diversification threshold and land in Very High Risk, or they possess enough products to jump directly into Moderate or Low Risk tiers.

2. London's Exposure: London is the most vulnerable branch in the network, carrying the highest volume of 72 "Very High Risk" clients. This is followed closely by Seoul with 68 clients. These locations should be prioritized for immediate portfolio rebalancing.

3. Minimal "Very Low Risk" Representation: The "Very Low Risk" segment represents the smallest portion of the total population, with many branches like Amsterdam and Tokyo showing 0 clients, and others showing only between 2 and 5.