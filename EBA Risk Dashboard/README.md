# EBA Risk Dashboard (in Python)

Sample script illustrating data quality checks, country-level outlier
detection, and time-series trend analysis on real, publicly available
EBA Risk Dashboard data.

That underlying supervisory data and production code are confidential and
cannot be shared, so this script instead applies the same approach to the
Risk Dashboard's official public data release, to illustrate my coding
style and analytical process in a form I'm able to share.

# Data source
EBA Risk Dashboard - Data Annex, Q4 2025 ("KRIs by country and EU" sheet):
https://www.eba.europa.eu/risk-and-data-analysis/risk-analysis/risk-monitoring/risk-dashboard

The full annex covers all quarters back to 2014; `data/eba_risk_dashboard_kri_2022_2025.csv`
is an extract covering 2022-2025 (16 quarters) to keep the sample dataset
light .

# What the script does
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


# How to run
```bash
pip install pandas matplotlib
python eba_risk_dashboard_analysis.py
```
