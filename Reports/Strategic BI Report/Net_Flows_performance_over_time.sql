/* Year-over-Year (YoY) Change(%) in  Quartely Net Flows */



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

