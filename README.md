# German Corporate Lending Conditions and ECB Monetary Policy, 2019–Jul 2026

Small finance data-analysis project using publicly available European Central Bank data to examine how German corporate borrowing conditions evolved alongside ECB monetary policy.

The same analytical problem was completed through two workflows:

- **Excel:** data preparation, validation, calculations, PivotTables and PivotCharts
- **SQL + Tableau:** database preparation, SQL transformations and analytical queries, followed by dashboard visualization

## Dashboard



**Interactive dashboard:** 

---

## Research Questions

1. How did German corporate loan rates evolve alongside the ECB Deposit Facility Rate?
2. How did new corporate loan volumes change over time?
3. How did YoY growth in new lending differ from growth in the outstanding stock of corporate loans?
4. How did borrowing conditions differ across negative-, zero- and positive-rate ECB policy regimes?

The analysis is descriptive and does not attempt to establish causal effects of monetary policy.

---

## Data

**Source:** European Central Bank Data Portal  
**Period:** January 2019 – July 2026  
**Final analytical dataset:** 91 monthly observations

| Variable | Description |
|---|---|
| `Corporate_Loan_Rate` | Interest rate on pure new corporate loans in Germany |
| `New_Loan_Volume` | Monthly volume of pure new corporate loans |
| `Loan_Stock` | Outstanding stock of loans to non-financial corporations |
| `ECB_DFR` | ECB Deposit Facility Rate |

Derived variables include lending spread, YoY new-loan-volume growth, YoY loan-stock growth, a 3-month moving average of new-loan volume, monthly ECB DFR change and ECB policy regime.

---

## Workflow 1 — Excel

The ECB series were imported separately and combined using dates.

Data preparation included:

- Standardizing dates
- Checking missing and duplicate values
- Verifying monthly continuity
- Checking loan variables for implausible values

Calculated variables included:

- Lending spread
- YoY new-loan-volume growth
- YoY loan-stock growth
- 3-month moving average of new-loan volume

---

## Workflow 2 — SQL + Tableau

The SQL workflow started from four separate source tables:

- `Corporate_Loan_Rate`
- `New_Loan_Volume`
- `Loan_Stock`
- `ECB_DFR`

The tables were standardized, joined into an analytical view, and transformed using SQL to reproduce the main Excel calculations. The resulting dataset was then visualized in Tableau.

---

## Key Findings

1. **Corporate borrowing rates moved broadly alongside the ECB Deposit Facility Rate.** Corporate loan rates rose sharply during the tightening period and later declined as policy rates decreased.

2. **Corporate loan rates remained above the ECB policy rate throughout the sample**, leaving a positive lending spread.

3. **New corporate lending volumes were more volatile than the outstanding stock of corporate loans.**

4. **YoY growth in new lending fluctuated substantially more than YoY growth in outstanding loan stocks**, consistent with the difference between a flow variable and a stock variable.

5. **Average corporate loan rates were highest during the positive-rate regime.** Average new-loan volumes were also higher during that period, but this descriptive relationship should not be interpreted as causal.

---

## Tools & Skills

**Excel** · **SQL / SQLite** · **Tableau** · Data Cleaning · Data Validation · Time-Series Analysis · Window Functions · Data Visualization · Financial Data Analysis
