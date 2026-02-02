/*A. Year-over-Year (YoY) Change in Assets Under Management (AUM)*/

WITH YearlyAUM AS (
    SELECT 
        YEAR(transaction_date) AS fiscal_year,
        SUM(CAST(invested_amount AS DECIMAL(20, 2))) - SUM(CAST(withdrawal_amount AS DECIMAL(20, 2))) AS yearly_aum
    FROM gold.fact_transactions
    WHERE transaction_date IS NOT NULL
    GROUP BY 
        YEAR(transaction_date)
),
PrevYearlyAUM AS(
	SELECT *,
		LAG(yearly_aum) OVER(ORDER BY fiscal_year) AS prev_yearly_aum
	FROM
		YearlyAUM
)
SELECT
	fiscal_year,
	yearly_aum,
	prev_yearly_aum,
	CAST(ROUND(((yearly_aum/prev_yearly_aum)-1)*100, 2) AS DECIMAL (18,2)) AS yoy_perc
FROM
	PrevYearlyAUM
ORDER BY
		fiscal_year;


/*B. Quarter-over-Quarter (QoQ) Change in Assets Under Management (AUM)*/

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
		fiscal_quarter;

/*C. Year-over-Year (YoY) % Change in Cumulative AUM*/
	
With YearlrlyAUM AS(
	SELECT
		YEAR(transaction_date) AS fiscal_year,
		SUM(CAST(invested_amount AS DECIMAL (18, 2))) - SUM(CAST(withdrawal_amount AS DECIMAL (18, 2))) AS yearly_aum
	FROM
		gold.fact_transactions
	WHERE
		transaction_date IS NOT NULL
	GROUP BY
		YEAR(transaction_date) 
),
CulumativeAUM AS(
	SELECT
		fiscal_year,
		yearly_aum,
		SUM(yearly_aum) OVER(ORDER BY fiscal_year) AS culumative_aum
	FROM
		YearlrlyAUM
),
PrevCulumativeAUM AS(
	SELECT *,
		LAG(culumative_aum) OVER(ORDER BY fiscal_year) AS prev_culumative_aum
	FROM
		CulumativeAUM
)
SELECT
	fiscal_year,
	yearly_aum,
	culumative_aum,
	prev_culumative_aum,
	CAST(ROUND(((culumative_aum/prev_culumative_aum)-1)*100, 2) AS DECIMAL (18,2)) AS yoy_perc
FROM
	PrevCulumativeAUM
ORDER BY
		fiscal_year;
		
/*D. Quarter-over-Quarter (QoQ) % Change in Cumulative AUM*/

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












