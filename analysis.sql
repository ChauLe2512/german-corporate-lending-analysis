-- German Corporate Lending Conditions and ECB Monetary Policy
-- Source: European Central Bank Data Portal
-- The four ECB source tables were imported from CSV files into SQL using DB Browser for SQLite.

-- 1. RENAME COLUMNS

ALTER TABLE ECB_DFR 
RENAME COLUMN "Deposit facility - date of changes (raw data) - Level (FM.D.U2.EUR.4F.KR.DFR.LEV)" 
TO "ECB_DFR";

ALTER TABLE ECB_DFR 
RENAME COLUMN "Marginal lending facility - date of changes (raw data) - Level (FM.D.U2.EUR.4F.KR.MLFR.LEV)"
TO "Marginal lending facility";

ALTER TABLE ECB_DFR
RENAME COLUMN "Main refinancing operations - Minimum bid rate/fixed rate (date of changes) - Level (FM.D.U2.EUR.4F.KR.MRR_RT.LEV)"
TO "Main refinancing operations";

ALTER TABLE Corporate_Loan_Rate
RENAME COLUMN "Bank interest rates - loans to corporations (pure new loans)  (MIR.M.DE.B.A2A.A.R.A.2240.EUR.P)"
TO "Corporate_Loan_Rate";

ALTER TABLE Loan_Stock
RENAME COLUMN "Loans to euro area NFCs granted by MFIs excluding NCB, Stocks (BSI.M.DE.N.A.A20.A.1.U2.2240.Z01.E)"
TO Loan_Stock;

ALTER TABLE New_Loan_Volume
RENAME COLUMN "Bank business volumes - loans to corporations (pure new loans)  (MIR.M.DE.B.A2A.A.B.A.2240.EUR.P)"
TO New_Loan_Volume;

-- 2. STANDARDIZE DATES

SELECT
    DATE AS old_date,

    substr(DATE, -4) || '-' ||
    printf('%02d',
        CAST(substr(DATE, 1, instr(DATE, '/') - 1) AS INTEGER)
    ) || '-' ||
    printf('%02d',
        CAST(
            substr(
                substr(DATE, instr(DATE, '/') + 1),
                1,
                instr(substr(DATE, instr(DATE, '/') + 1), '/') - 1
            )
            AS INTEGER
        )
    ) AS new_date

FROM Loan_Stock
LIMIT 10;

UPDATE Loan_Stock
SET DATE =
    substr(DATE, -4) || '-' ||
    printf('%02d',
        CAST(substr(DATE, 1, instr(DATE, '/') - 1) AS INTEGER)
    ) || '-' ||
    printf('%02d',
        CAST(
            substr(
                substr(DATE, instr(DATE, '/') + 1),
                1,
                instr(substr(DATE, instr(DATE, '/') + 1), '/') - 1
            )
            AS INTEGER
        )
    );
	
UPDATE New_Loan_Volume
SET DATE =
    substr(DATE, -4) || '-' ||
    printf('%02d',
        CAST(substr(DATE, 1, instr(DATE, '/') - 1) AS INTEGER)
    ) || '-' ||
    printf('%02d',
        CAST(
            substr(
                substr(DATE, instr(DATE, '/') + 1),
                1,
                instr(substr(DATE, instr(DATE, '/') + 1), '/') - 1
            )
            AS INTEGER
        )
    );
	
UPDATE ECB_DFR
SET DATE =
    substr(DATE, -4) || '-' ||
    printf('%02d',
        CAST(substr(DATE, 1, instr(DATE, '/') - 1) AS INTEGER)
    ) || '-' ||
    printf('%02d',
        CAST(
            substr(
                substr(DATE, instr(DATE, '/') + 1),
                1,
                instr(substr(DATE, instr(DATE, '/') + 1), '/') - 1
            )
            AS INTEGER
        )
    );
	
SELECT MIN(DATE),MAX(DATE) FROM Corporate_Loan_Rate;
SELECT MIN(DATE),MAX(DATE) FROM Loan_Stock;
SELECT MIN(DATE),MAX(DATE) FROM ECB_DFR;
SELECT MIN(DATE),MAX(DATE) FROM New_Loan_Volume;

-- 3. CREATE MERGED ANALYTICAL VIEW

CREATE VIEW analysis_data AS 

SELECT
	r.DATE,
	r."TIME PERIOD" AS TIME_PERIOD,
	r.Corporate_Loan_Rate,
	e.ECB_DFR,
	s.Loan_Stock,
	v.New_Loan_Volume
	
FROM Corporate_Loan_Rate AS r

INNER JOIN Loan_Stock AS s ON r.DATE = s.DATE

INNER JOIN New_Loan_Volume AS v ON r.DATE = v.DATE 

LEFT JOIN ECB_DFR AS e 
	ON e.DATE = (
		SELECT MAX(e2.DATE)
		FROM ECB_DFR AS e2
		WHERE e2.DATE <= r.DATE 
		)
		
WHERE r.DATE >= '2019-01-01'
AND r.DATE <= '2026-07-31';

SELECT * 
FROM analysis_data 
ORDER BY DATE;

SELECT COUNT(*) AS Number_of_Date
FROM analysis_data;

-- 4. CREATE CALCULATED ANALYTICAL VIEW

CREATE VIEW analysis_calculated AS

WITH calc AS (
	SELECT 
		DATE,
		TIME_PERIOD,
		Corporate_Loan_Rate,
		ECB_DFR,
		Loan_Stock,
		New_Loan_Volume,
		
		LAG(New_loan_Volume, 12) OVER (
			ORDER BY DATE
		) AS New_Loan_Volume_12M_Ago,
		
		LAG(Loan_Stock, 12) OVER (
			ORDER BY DATE 
		) AS Loan_Stock_12M_Ago
	
	FROM analysis_data
)

SELECT 
	DATE,
	TIME_PERIOD,
	Corporate_Loan_Rate,
	ECB_DFR,
	Loan_Stock,
	New_Loan_Volume,
	
	Corporate_Loan_Rate - ECB_DFR AS Lending_Spread,
	
	CASE 
		WHEN New_Loan_Volume_12M_Ago IS NULL THEN NULL 
		ELSE CAST(New_Loan_Volume AS REAL) / New_Loan_Volume_12M_Ago - 1
	END
	AS New_Loan_Volume_YoY,

	CASE 
		WHEN Loan_Stock_12M_Ago IS NULL THEN NULL
		ELSE CAST (Loan_Stock AS REAL) / Loan_Stock_12M_Ago - 1
	END
	AS Loan_Stock_Growth_YoY,
	
	CASE 
		WHEN 
			ROW_NUMBER() OVER (ORDER BY DATE) < 3 
		THEN NULL
		ELSE 
			AVG(New_Loan_Volume) OVER (
				ORDER BY DATE
				ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
			)
	END
	AS New_Loan_Volume_3M_Avg,
	
	ECB_DFR - LAG(ECB_DFR, 1) OVER (ORDER BY DATE) 
	AS ECB_DFR_Monthly_Change,
	
	CASE
		WHEN ECB_DFR < 0 THEN 'Negative Rate'
		WHEN ECB_DFR = 0 THEN 'Zero Rate'
		ELSE 'Positive Rate'
	END AS Policy_Regime

FROM calc;

SELECT * 
FROM analysis_calculated
ORDER BY DATE; 

-- 5. DATA VALIDATION

SELECT
	COUNT(*) AS Number_of_Rows,
	MIN(DATE) AS Start_Date,
	MAX(DATE) AS End_Date,

	SUM(CASE WHEN Corporate_Loan_Rate IS NULL THEN 1 ELSE 0 END) 
	AS Missing_Corporate_Loan_Rate,
	
	SUM(CASE WHEN ECB_DFR IS NULL THEN 1 ELSE 0 END)
	AS Missing_ECB_DFR,
	
	SUM(CASE WHEN Loan_Stock IS NULL THEN 1 ELSE 0 END)
	AS Missing_Loan_Stock,
	
	SUM(CASE WHEN New_Loan_Volume IS NULL THEN 1 ELSE 0 END)
	AS Missing_New_Loan_Volume
	
FROM analysis_calculated;

-- 6. DESCRIPTIVE ANALYSIS

--What were average corporate borrowing conditions by year?

SELECT 
	strftime('%Y', DATE) AS YEAR,
	AVG(ECB_DFR) AS Average_ECB_DFR,
	AVG(Corporate_Loan_Rate) AS Average_Corporate_Loan_Rate,
	AVG(Lending_Spread) AS Average_Lending_Spread,
	AVG(New_Loan_Volume) AS Average_New_Loan_Volume,
	SUM(New_Loan_Volume) AS Sum_New_Loan_Volume,
	AVG(New_Loan_Volume_YoY) AS Average_New_Loan_Volume_YoY,
	AVG(Loan_Stock_Growth_YoY) AS Average_Loan_Stock_Growth_YoY
FROM analysis_calculated
GROUP BY YEAR
ORDER BY YEAR;

-- During which monetary-policy regime was corporate borrowing most expensive, 
-- and how did average new-loan volume compare across regimes?

SELECT 
	Policy_Regime,
	COUNT(*) AS Number_of_Months,
	AVG(Corporate_Loan_Rate) AS Avg_Corporate_Loan_Rate,
	AVG(New_Loan_Volume) AS Avg_New_Loan_Volume
FROM analysis_calculated
GROUP BY Policy_Regime
ORDER BY Avg_Corporate_Loan_Rate DESC;