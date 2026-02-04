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