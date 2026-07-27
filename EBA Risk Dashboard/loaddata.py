"""
load_data.py

Loads the EBA Risk Dashboard KRI CSV extract into a local SQLite database
(eba_risk_dashboard.db) 
"""

import sqlite3
import pandas as pd

df = pd.read_csv("eba_risk_dashboard_kri_2022_2025.csv")
conn = sqlite3.connect("eba_risk_dashboard.db")
df.to_sql("kri_data", conn, if_exists="replace", index=False)
conn.close()

print(f"Loaded {len(df)} rows into eba_risk_dashboard.db (table: kri_data)")
