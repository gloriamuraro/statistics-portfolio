"""
risk_dashboard_analysis.py

Country-level trend analysis, outlier detection and data quality checks on  EBA Risk Dashboard data
(Key Risk Indicators by country and EU), Q4 2025 reference period, 
sourced from the EBA's official public Data Annex.

Source: EBA Risk Dashboard - Data Annex, Q4 2025
https://www.eba.europa.eu/risk-and-data-analysis/risk-analysis/risk-monitoring/risk-dashboard
(publicly available; extracted here to a CSV covering 2022-2025 for a
lighter, more manageable working dataset)

Steps:
1. Load data and run data quality checks (missing values, duplicates,
   out-of-range ratios)
2. Compute country-level descriptive statistics (mean, median, std,
   quartiles, IQR) per indicator for the latest quarter
3. Country-level outlier detection vs. the EU average, per indicator
4. Time series / trend analysis (quarter-on-quarter and year-on-year
   change) for selected key indicators
5. Export summary tables, distribution boxplots and trend charts
"""

import os
import pandas as pd
import matplotlib.pyplot as plt

DATA_PATH = "data/eba_risk_dashboard_kri_2022_2025.csv"
OUTPUT_DIR = "outputs"
LATEST_PERIOD = 202512  # Q4 2025

os.makedirs(OUTPUT_DIR, exist_ok=True)

# Indicators of interest (EBA "Number" codes), with readable short labels
INDICATORS = {
    "SVC_3":   "CET1 ratio",
    "AQT_3.2": "NPL ratio",
    "LIQ_17":  "Liquidity coverage ratio",
    "PFT_21":  "Return on equity",
}


def load_data(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)
    return df


def data_quality_checks(df: pd.DataFrame) -> pd.DataFrame:
    """
    Check for missing values, duplicate records, and out-of-range ratios.
    Plausible ranges are defined per indicator rather than as a general
    rule

    """
    print("\n--- Data Quality Report ---")

    missing = df["Ratio"].isna().sum()
    print(f"Missing ratio values: {missing}")

    dup_key = ["Period", "Country", "Number"]
    duplicates = df.duplicated(subset=dup_key).sum()
    print(f"Duplicate (Period, Country, Number) records: {duplicates}")

    # Per-indicator plausible ranges (min, max), expressed as ratios (0.10 = 10%).
    # Indicators not listed fall back to a generic [-1, 3] sanity bound.
    plausible_ranges = {
        "SVC_3":   (0, 1),    
        "AQT_3.2": (0, 1),    
        "PFT_21":  (-1, 1),   
        "LIQ_17":  (0, 6),    
        "FND_32":  (0, 6),    
    }
    default_range = (-1, 3)

    flagged_rows = []
    for code, group in df.groupby("Number"):
        low, high = plausible_ranges.get(code, default_range)
        out = group[(group["Ratio"] < low) | (group["Ratio"] > high)]
        if len(out):
            flagged_rows.append(out)

    out_of_range = pd.concat(flagged_rows) if flagged_rows else df.iloc[0:0]
    print(f"Ratio values outside indicator-specific plausible ranges: {len(out_of_range)}")
    if len(out_of_range):
        print(out_of_range[["Period", "Country", "Number", "Name", "Ratio"]].to_string(index=False))

    return df


def latest_quarter_outliers(df: pd.DataFrame, indicator_code: str, label: str) -> pd.DataFrame:
    """
    Flag countries whose latest-quarter value deviates most from the EU
    aggregate for a given indicator .
    """
    latest = df[(df["Number"] == indicator_code) & (df["Period"] == LATEST_PERIOD)].copy()
    eu_value = latest.loc[latest["Country"] == "EU", "Ratio"]

    if eu_value.empty:
        print(f"No EU aggregate found for {label} in {LATEST_PERIOD}")
        return pd.DataFrame()

    eu_value = eu_value.iloc[0]
    countries = latest[latest["Country"] != "EU"].copy()
    countries["deviation_from_eu"] = (countries["Ratio"] - eu_value).round(4)

    ranked = countries[["Country", "Ratio", "deviation_from_eu"]].sort_values(
        "deviation_from_eu", key=abs, ascending=False
    )

    print(f"\n--- {label}: largest deviations from EU average ({LATEST_PERIOD}, EU = {eu_value:.4f}) ---")
    print(ranked.head(8).to_string(index=False))
    return ranked


def country_distribution_stats(df: pd.DataFrame, indicator_code: str, label: str) -> pd.Series:
    """
    Descriptive statistics of the country-level distribution for a given
    indicator in the latest quarter 
    """
    latest = df[(df["Number"] == indicator_code) & (df["Period"] == LATEST_PERIOD)]
    country_values = latest.loc[latest["Country"] != "EU", "Ratio"]

    stats = country_values.describe()  # count, mean, std, min, 25%, 50%, 75%, max
    stats["iqr"] = stats["75%"] - stats["25%"]

    print(f"\n--- {label}: country-level distribution ({LATEST_PERIOD}) ---")
    print(stats.round(4).to_string())
    return stats


def plot_distribution(df: pd.DataFrame, indicator_code: str, label: str) -> None:
    """Boxplot of the country-level distribution for the latest quarter."""
    latest = df[(df["Number"] == indicator_code) & (df["Period"] == LATEST_PERIOD)]
    country_values = latest.loc[latest["Country"] != "EU", "Ratio"] * 100
    eu_value = latest.loc[latest["Country"] == "EU", "Ratio"]

    fig, ax = plt.subplots(figsize=(6, 4))
    ax.boxplot(country_values, vert=False, widths=0.5)
    if not eu_value.empty:
        ax.axvline(eu_value.iloc[0] * 100, color="red", linestyle="--", label="EU average")
        ax.legend(loc="best")
    ax.set_title(f"Distribution across countries: {label} ({LATEST_PERIOD})")
    ax.set_xlabel(f"{label} (%)")
    ax.set_yticks([])
    fig.tight_layout()
    out_path = os.path.join(OUTPUT_DIR, f"{label.replace(' ', '_')}_distribution.png")
    fig.savefig(out_path, dpi=150)
    print(f"Distribution chart saved to {out_path}")


def trend_analysis(df: pd.DataFrame, indicator_code: str, label: str) -> pd.DataFrame:
    """EU-level time series with quarter-on-quarter and year-on-year change."""
    eu_series = (
        df[(df["Number"] == indicator_code) & (df["Country"] == "EU")]
        .sort_values("Period")
        .set_index("Period")["Ratio"]
    )

    trend = pd.DataFrame({"eu_value": eu_series})
    trend["qoq_change"] = trend["eu_value"].diff().round(4)
    trend["yoy_change"] = trend["eu_value"].diff(4).round(4)

    print(f"\n--- {label}: EU-level trend ---")
    print(trend.to_string())
    return trend


def plot_trend(trend: pd.DataFrame, label: str) -> None:
    fig, ax = plt.subplots(figsize=(8, 4))
    (trend["eu_value"] * 100).plot(ax=ax, marker="o")
    ax.set_title(f"EU average {label} over time")
    ax.set_ylabel(f"{label} (%)")
    ax.set_xlabel("Period (YYYYMM)")
    fig.tight_layout()
    out_path = os.path.join(OUTPUT_DIR, f"{label.replace(' ', '_')}_trend.png")
    fig.savefig(out_path, dpi=150)
    print(f"Chart saved to {out_path}")


def main():
    df = load_data(DATA_PATH)
    df = data_quality_checks(df)

    for code, label in INDICATORS.items():
        country_distribution_stats(df, code, label)
        latest_quarter_outliers(df, code, label)
        plot_distribution(df, code, label)
        trend = trend_analysis(df, code, label)
        plot_trend(trend, label)


if __name__ == "__main__":
    main()
