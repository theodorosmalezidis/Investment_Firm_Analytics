/*a. Employee Benchmarking Tool*/

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