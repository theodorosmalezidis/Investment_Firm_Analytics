 /*Segmentation & Distribution Analysis. Try to identify patterns in regional performance, product popularity and performance and long-term trends.
*/



-- 1. Branch Analysis



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
   				, sum(invested_amount-withdrawal_amount) as Net_Flows_per_client
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
   , sum(c.Net_Flows_per_client) as total_Net_Flows
   , cast((count(distinct b.client_key)*100.0)/sum(count(distinct b.client_key)) over() as decimal(10,2)) as perc_of_total_clients
   , cast((sum(c.transanctions_per_client)*100.0)/sum(sum(c.transanctions_per_client)) over() as decimal(10,2)) as perc_of_total_transactions
   , cast((sum(c.total_fee_per_client)*100.0)/sum(sum(c.total_fee_per_client)) over() as decimal(10,2)) as perc_of_total_fees
   , cast((sum(c.Net_Flows_per_client)*100.0)/sum(sum(c.Net_Flows_per_client)) over() as decimal(10,2)) as perc_of_total_Net_Flows
from
   clients_per_branch b
   	left join
   		client_totals c
   			on b.client_key=c.client_key 
group by
   branch
order by
   total_Net_Flows desc




-- 2.Product Type Analysis 

--create a cte to aggregate by product
with product_type_totals as
							(
							select
								p.product_type,
								p.product_key,
								isnull(sum(t.invested_amount)-sum(t.withdrawal_amount), 0) as product_Net_Flows,--in USD
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
	sum(product_Net_Flows) as total_aum,--in USD
	sum(product_fees) as total_fees,--in USD
	cast(sum(product_transactions)*100.0/sum(sum(product_transactions)) over() as decimal(10,2)) as perc_of_total_transactions,--window function helps find perc of each product type s nr. of transactions in firm s total
	cast(sum(product_Net_Flows)*100.0/sum(sum(product_Net_Flows)) over() as decimal(10,2)) as perc_of_total_Net_Flows,--window function helps find perc of each product type s total AUM in firm s total
	cast(sum(product_fees)*100.0/sum(sum(product_fees)) over() as decimal(10,2)) as perc_of_total_fees--window function helps find perc of each product type s total fees in firm s total
from		
	product_type_totals
group by
	product_type
order by
	total_aum desc;


-- 3. Transactions Analysis

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


--4. Monthly Trends 

select 
	  datename(year, transaction_date) as year
    , datename(month, transaction_date) as month
    , count(transaction_key) AS monthly_transactions
	, sum(invested_amount)-sum(withdrawal_amount) as monthly_Net_Flows
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
	, MONTH(transaction_date)



