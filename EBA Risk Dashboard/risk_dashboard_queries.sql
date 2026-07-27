-- risk_dashboard_queries.sql
--
-- Data quality checks, aggregation and country-ranking queries on real
-- EBA Risk Dashboard data (Key Risk Indicators by country and EU),
-- covering 2022-2025.
--
-- Source: EBA Risk Dashboard - Data Annex, Q4 2025 ("KRIs by country and
-- EU" sheet), publicly available at:
-- https://www.eba.europa.eu/risk-and-data-analysis/risk-analysis/risk-monitoring/risk-dashboard
--
--
-- Table structure (kri_data):
--   Period   INTEGER   -- reference period, format YYYYMM (e.g. 202512 = Q4 2025)
--   Country  TEXT      -- ISO 2-letter country code, or 'EU' for the EU aggregate
--   Number   TEXT      -- EBA indicator code (e.g. 'SVC_3' = CET1 ratio)
--   Name     TEXT      -- full indicator name
--   Ratio    REAL      -- indicator value, expressed as a ratio (0.16 = 16%)


-- =================================================================
-- 1. DATA QUALITY CHECKS
-- =================================================================

-- 1a. Missing values
SELECT COUNT(*) AS missing_ratio_count
FROM kri_data
WHERE Ratio IS NULL;

-- 1b. Duplicate records (same period, country and indicator reported twice)
SELECT Period, Country, Number, COUNT(*) AS n_records
FROM kri_data
GROUP BY Period, Country, Number
HAVING COUNT(*) > 1;

-- 1c. Out-of-range values
SELECT Period, Country, Number, Name, Ratio
FROM kri_data
WHERE
    (Number = 'SVC_3'   AND (Ratio < 0 OR Ratio > 1))   -- CET1 ratio: 0-100%
    OR (Number = 'AQT_3.2' AND (Ratio < 0 OR Ratio > 1))   -- NPL ratio: 0-100%
    OR (Number = 'PFT_21'  AND (Ratio < -1 OR Ratio > 1))  -- ROE: can be negative
    OR (Number = 'LIQ_17'  AND (Ratio < 0 OR Ratio > 6))   -- LCR: can run much higher than 100%
    OR (Number = 'FND_32'  AND (Ratio < 0 OR Ratio > 6))   -- loan-to-deposit ratio: can exceed 100% (e.g. Denmark)
    OR (Number NOT IN ('SVC_3', 'AQT_3.2', 'PFT_21', 'LIQ_17', 'FND_32')
        AND (Ratio < -1 OR Ratio > 3));                    -- generic fallback range


-- =================================================================
-- 2. EU-LEVEL AGGREGATION AND TREND (quarter-on-quarter, year-on-year)
-- =================================================================

-- EU-level time series for CET1 ratio (SVC_3), with QoQ and YoY change
-- computed using window functions (LAG).
SELECT
    Period,
    Ratio AS eu_value,
    ROUND(Ratio - LAG(Ratio, 1) OVER (ORDER BY Period), 4) AS qoq_change,
    ROUND(Ratio - LAG(Ratio, 4) OVER (ORDER BY Period), 4) AS yoy_change
FROM kri_data
WHERE Number = 'SVC_3' AND Country = 'EU'
ORDER BY Period;


-- =================================================================
-- 3. COUNTRY-LEVEL DESCRIPTIVE STATISTICS (latest quarter)
-- =================================================================

-- Mean, min, max and standard deviation of CET1 ratio across countries
-- (EU aggregate excluded, since it is a weighted summary value, not one
-- more data point in the country distribution).
SELECT
    COUNT(*)                                   AS n_countries,
    ROUND(AVG(Ratio), 4)                       AS mean_ratio,
    ROUND(MIN(Ratio), 4)                       AS min_ratio,
    ROUND(MAX(Ratio), 4)                       AS max_ratio,
    ROUND(
        SQRT(AVG(Ratio * Ratio) - AVG(Ratio) * AVG(Ratio)), 4
    )                                           AS stddev_ratio
FROM kri_data
WHERE Number = 'SVC_3' AND Period = 202512 AND Country <> 'EU';


-- =================================================================
-- 4. COUNTRY RANKING BY DEVIATION FROM EU AVERAGE (window function)
-- =================================================================

-- Rank countries by how far their latest-quarter CET1 ratio deviates from
-- the EU aggregate, using a window function to avoid a self-join.
WITH eu_avg AS (
    SELECT Ratio AS eu_value
    FROM kri_data
    WHERE Number = 'SVC_3' AND Period = 202512 AND Country = 'EU'
)
SELECT
    k.Country,
    k.Ratio,
    ROUND(k.Ratio - eu_avg.eu_value, 4) AS deviation_from_eu,
    RANK() OVER (ORDER BY ABS(k.Ratio - eu_avg.eu_value) DESC) AS deviation_rank
FROM kri_data k
CROSS JOIN eu_avg
WHERE k.Number = 'SVC_3' AND k.Period = 202512 AND k.Country <> 'EU'
ORDER BY deviation_rank
LIMIT 10;
