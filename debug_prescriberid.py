import pandas as pd

# Check if ID 326 exists in source
ngd = pd.read_csv('ibsa-poc-eda/data/Reporting_BI_PrescriberOverview.csv', low_memory=False)
print(f"Total source rows: {len(ngd):,}")
print(f"Unique PrescriberIds: {ngd['PrescriberId'].nunique():,}")

match_326 = ngd[ngd['PrescriberId'] == 326]
print(f"\nPrescriberId 326 exists: {len(match_326)} rows")
if len(match_326) > 0:
    print(match_326[['PrescriberId', 'PrescriberName', 'Specialty', 'ProductGroupName']].head())

# Check what the REAL first HCP ID should be
print(f"\nFirst unique PrescriberIds in source:")
print(ngd.groupby('PrescriberId').first().head().index.tolist())
