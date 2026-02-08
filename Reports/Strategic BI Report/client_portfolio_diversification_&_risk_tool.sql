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