# EBA Risk Dashboard: Data Quality, Trend Analysis & Outlier Detection
Sample scripts (Python and SQL) illustrating data quality checks,
country-level outlier detection, and time-series trend analysis on real,
publicly available EBA Risk Dashboard data.


# Data source
EBA Risk Dashboard - Data Annex, Q4 2025 ("KRIs by country and EU" sheet):
https://www.eba.europa.eu/risk-and-data-analysis/risk-analysis/risk-monitoring/risk-dashboard
The full annex covers all quarters back to 2014; `data/eba_risk_dashboard_kri_2022_2025.csv`
is an extract covering 2022-2025 (16 quarters) to keep the sample dataset
light.

# EBA Risk Dashboard (in Python)
`eba_risk_dashboard_analysis.py`
1. Data quality checks: missing values, duplicate (period, country,
   indicator) records, and out-of-range ratios
2. Country-level descriptive statistics: mean, median, standard
   deviation, quartiles and interquartile range across countries, for the
   latest quarter (Q4 2025), with a boxplot per indicator
3. Country-level outlier detection: for the latest quarter, ranks
   countries by deviation from the EU aggregate for each indicator
4. Trend analysis: EU-level time series with quarter-on-quarter and
   year-on-year change, for four key indicators:
   - CET1 ratio (capital adequacy)
   - NPL ratio (asset quality)
   - Liquidity Coverage Ratio (liquidity)
   - Return on equity (profitability)
5. Exports a distribution boxplot and a trend chart per indicator

### How to run
```bash
pip install pandas matplotlib
python eba_risk_dashboard_analysis.py
```

# EBA Risk Dashboard (in SQL)
`eba_risk_dashboard_queries.sql`, run against the same dataset
1. Data quality checks: missing values, duplicate records, and
   out-of-range ratios
2. EU-level trend analysis: quarter-on-quarter and year-on-year change,
   using the `LAG()` window function
3. Country-level descriptive statistics for the latest quarter
4. Country ranking by deviation from the EU average, using a CTE and the
   `RANK()` window function

### How to run
```bash
pip install pandas
python load_data.py     # loads the CSV into a local SQLite database
sqlite3 data/eba_risk_dashboard.db < eba_risk_dashboard_queries.sql
```

# Files
- `eba_risk_dashboard_analysis.py` – Python analysis script
- `eba_risk_dashboard_queries.sql` – SQL queries
- `load_data.py` – loads the CSV into a local SQLite database (for the SQL queries)
- `data/eba_risk_dashboard_kri_2022_2025.csv` – extract of the public EBA
  Data Annex (2022-2025, "KRIs by country and EU" sheet)
