import pandas as pd

print("=== TERRITORY TABLE STRUCTURES ===\n")

# Table 1: TerritoryPerformanceOverview
t1 = pd.read_csv('ibsa-poc-eda/data/Reporting_BI_TerritoryPerformanceOverview.csv', nrows=5)
print("1. TerritoryPerformanceOverview")
print(f"   Columns: {list(t1.columns)}")
print(f"   Total rows: {len(pd.read_csv('ibsa-poc-eda/data/Reporting_BI_TerritoryPerformanceOverview.csv'))}")

# Table 2: TerritoryPerformanceSummary
t2 = pd.read_csv('ibsa-poc-eda/data/Reporting_BI_TerritoryPerformanceSummary.csv', nrows=5)
print("\n2. TerritoryPerformanceSummary")
print(f"   Columns: {list(t2.columns)}")
print(f"   Total rows: {len(pd.read_csv('ibsa-poc-eda/data/Reporting_BI_TerritoryPerformanceSummary.csv'))}")

# Table 3: Territory_CallSummary
t3 = pd.read_csv('ibsa-poc-eda/data/Reporting_Bi_Territory_CallSummary.csv', nrows=5)
print("\n3. Territory_CallSummary")
print(f"   Columns: {list(t3.columns)}")
print(f"   Total rows: {len(pd.read_csv('ibsa-poc-eda/data/Reporting_Bi_Territory_CallSummary.csv'))}")

print("\n=== SAMPLE DATA ===")
print("\nTerritoryPerformanceOverview (first 3 rows):")
print(t1.head(3))
