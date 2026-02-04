/* Year-over-Year (YoY) Change(%) in Quarterly Fees (Revenue) */


--query follows same structure to quartely Net Flows and YoY(%) change calculation.
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