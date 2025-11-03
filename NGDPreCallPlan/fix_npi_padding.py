"""
REAL FIX: The sequential IDs ARE real NPIs, just without leading zeros
ROOT CAUSE: NPIs stored as integers lose leading zeros (326 should be 0000326)
"""
import pandas as pd
from pathlib import Path

BASE_DIR = Path(__file__).parent

# 1. Load predictions
predictions_file = BASE_DIR / "ibsa-poc-eda" / "outputs" / "phase7" / "IBSA_ModelReady_Enhanced_WithPredictions.csv"
print("Loading predictions...")
predictions = pd.read_csv(predictions_file, low_memory=False)
print(f"✓ Loaded {len(predictions):,} predictions")
print(f"  Sample NPIs: {predictions['NPI'].head(5).tolist()}")

# 2. Pad NPIs to 7 digits (standard NPI format)
predictions['NPI'] = predictions['NPI'].astype(str).str.zfill(7)
print(f"\n✓ Padded NPIs to 7 digits:")
print(f"  Sample NPIs: {predictions['NPI'].head(5).tolist()}")

# 3. Load prescriber overview with padded NPIs
print("\nLoading Prescriber Overview...")
overview = pd.read_csv(
    BASE_DIR / "ibsa-poc-eda" / "data" / "Reporting_BI_PrescriberOverview.csv",
    usecols=['PrescriberId', 'PrescriberName', 'TerritoryName', 'City', 'State',
             'TirosintTargetTier', 'FlectorTargetTier', 'LicartTargetTier'],
    dtype={'PrescriberId': str},
    low_memory=True
)
print(f"✓ Loaded {len(overview):,} rows")

# Pad PrescriberId to 7 digits
overview['PrescriberId'] = overview['PrescriberId'].str.zfill(7)

# Get unique prescribers
overview_unique = overview.drop_duplicates(subset=['PrescriberId'], keep='first')
print(f"✓ Unique prescribers: {len(overview_unique):,}")

# 4. Merge predictions with prescriber data
print("\nMerging with prescriber data...")
merged = predictions.merge(
    overview_unique,
    left_on='NPI',
    right_on='PrescriberId',
    how='left'
)

print(f"✓ Merged: {len(merged):,} rows")
print(f"✓ Successful matches: {merged['PrescriberName'].notna().sum():,}")

# 5. Use profile data to populate fields
merged['PrescriberName'] = merged['PrescriberName'].fillna('HCP-' + merged['NPI'])
merged['City'] = merged['City_y'].fillna(merged['City_x'])
merged['State'] = merged['State_y'].fillna(merged['State_x'])
merged['Territory'] = merged['TerritoryName'].fillna(merged['State'])
merged['Tier'] = merged['TirosintTargetTier'].fillna(
    merged['FlectorTargetTier'].fillna(
        merged['LicartTargetTier'].fillna('Silver')
    )
)

# 6. Drop merge artifacts and profile columns
cols_to_drop = ['PrescriberId', 'City_x', 'City_y', 'State_x', 'State_y',
                'TerritoryName', 'TirosintTargetTier', 'FlectorTargetTier', 'LicartTargetTier']
merged.drop([c for c in cols_to_drop if c in merged.columns], axis=1, inplace=True)

# 7. Reorder columns
essential_cols = ['NPI', 'PrescriberName', 'Specialty', 'City', 'State', 'Territory', 'Tier',
                  'TRx_Current', 'flector_trx', 'licart_trx']
other_cols = [c for c in merged.columns if c not in essential_cols]
merged = merged[[c for c in essential_cols if c in merged.columns] + other_cols]

# 8. Verify
has_real_names = ~merged['PrescriberName'].str.startswith('HCP-', na=False)
print(f"\n✓ Final dataset: {len(merged):,} HCPs")
print(f"✓ HCPs with real names: {has_real_names.sum():,} ({100*has_real_names.sum()/len(merged):.1f}%)")

# 9. Save
output_file = BASE_DIR / "ibsa_precall_ui" / "public" / "data" / "IBSA_ModelReady_Enhanced_WithPredictions.csv"
merged.to_csv(output_file, index=False)
print(f"\n✅ Saved to: {output_file}")
print(f"   Size: {output_file.stat().st_size / (1024*1024):.1f} MB")

# 10. Show samples
print("\n📋 Sample rows:")
print(merged[['NPI', 'PrescriberName', 'Specialty', 'City', 'State']].head(10).to_string(index=False))
