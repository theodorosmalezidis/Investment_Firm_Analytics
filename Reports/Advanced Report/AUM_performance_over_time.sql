/*a. Quarterly AUM and Cumulative Growth with QoQ % Change*/



With QuarterlyAUM AS(
	SELECT
		YEAR(transaction_date) AS fiscal_year,
		DATEPART(QUARTER, transaction_date) AS fiscal_quarter,
		SUM(CAST(invested_amount AS DECIMAL (18, 2))) - SUM(CAST(withdrawal_amount AS DECIMAL (18, 2))) AS quarterly_aum
	FROM
		gold.fact_transactions
	WHERE
		transaction_date IS NOT NULL
	GROUP BY
		YEAR(transaction_date) ,
		DATEPART(QUARTER, transaction_date)
),
CulumativeAUM AS(
	SELECT
		fiscal_year,
		fiscal_quarter,
		quarterly_aum,
		SUM(quarterly_aum) OVER(ORDER BY fiscal_year,fiscal_quarter) AS culumative_aum
	FROM
		QuarterlyAUM
),
PrevCulumativeAUM AS(
	SELECT *,
		LAG(culumative_aum) OVER(ORDER BY fiscal_year,fiscal_quarter) AS prev_culumative_aum
	FROM
		CulumativeAUM
)
SELECT
	fiscal_year,
	fiscal_quarter,
	quarterly_aum,
	culumative_aum,
	prev_culumative_aum,
	CAST(ROUND(((culumative_aum/prev_culumative_aum)-1)*100, 2) AS DECIMAL (18,2)) AS qoq_perc
FROM
	PrevCulumativeAUM
ORDER BY
		fiscal_year,
		fiscal_quarter;



/*b. Standalone Quarterly AUM with QoQ % Change*/

WITH QuarterlyAUM AS (
    SELECT 
        YEAR(transaction_date) AS fiscal_year,
        DATEPART(QUARTER, transaction_date) AS fiscal_quarter,
        SUM(CAST(invested_amount AS DECIMAL(20, 2))) - SUM(CAST(withdrawal_amount AS DECIMAL(20, 2))) AS quarterly_aum
    FROM gold.fact_transactions
    WHERE transaction_date IS NOT NULL
    GROUP BY 
        YEAR(transaction_date),
        DATEPART(QUARTER, transaction_date)
),
PrevQuarterlyAUM AS(
	SELECT *,
		LAG(quarterly_aum) OVER(ORDER BY fiscal_year,fiscal_quarter) AS prev_quarterly_aum
	FROM
		QuarterlyAUM
)
SELECT
	fiscal_year,
	fiscal_quarter,
	quarterly_aum,
	prev_quarterly_aum,
	CAST(ROUND(((quarterly_aum/prev_quarterly_aum)-1)*100, 2) AS DECIMAL (18,2)) AS qoq_perc
FROM
	PrevQuarterlyAUM
ORDER BY
		fiscal_year,
		fiscal_quarter








