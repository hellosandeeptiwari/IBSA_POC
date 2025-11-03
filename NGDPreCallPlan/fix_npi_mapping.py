"""
FIX: Map sequential IDs back to real NPIs using Prescriber Overview as source of truth
ROOT CAUSE: Phase4c used index_col=0 which corrupted PrescriberId to sequential IDs
"""
import pandas as pd
from pathlib import Path

BASE_DIR = Path(__file__).parent

# 1. Load the predictions with sequential IDs
predictions_file = BASE_DIR / "ibsa-poc-eda" / "outputs" / "phase7" / "IBSA_ModelReady_Enhanced_WithPredictions.csv"
print("Loading predictions with sequential IDs...")
predictions = pd.read_csv(predictions_file, low_memory=False)
print(f"✓ Loaded {len(predictions):,} predictions")
print(f"  Sample NPIs (currently sequential): {predictions['NPI'].head(10).tolist()}")

# 2. Load Prescriber Overview to get real NPIs
overview_file = BASE_DIR / "ibsa-poc-eda" / "data" / "Reporting_BI_PrescriberOverview.csv"
print("\nLoading Prescriber Overview (source of truth for real NPIs)...")
overview = pd.read_csv(overview_file, usecols=['PrescriberId', 'PrescriberName', 'TerritoryName', 'City', 'State', 
                                                'TirosintTargetTier', 'FlectorTargetTier', 'LicartTargetTier'],
                       dtype={'PrescriberId': str}, low_memory=True)
print(f"✓ Loaded {len(overview):,} prescribers")

# 3. The sequential IDs are actually row indices from when the features were created
# We need to map: sequential_id → real_prescriber_id
# The overview CSV was used to create features, so we need to get unique PrecriberIDs in the order they appear

overview_unique = overview.drop_duplicates(subset=['PrescriberId'], keep='first').reset_index(drop=True)
print(f"✓ Unique prescribers: {len(overview_unique):,}")

# Create mapping: row_index → real_NPI
id_mapping = overview_unique['PrescriberId'].reset_index()
id_mapping.columns = ['SequentialID', 'RealNPI']
id_mapping['SequentialID'] = id_mapping['SequentialID'].astype(str)

print(f"\n✓ Created ID mapping:")
print(id_mapping.head(10))

# 4. Map the sequential IDs in predictions to real NPIs
predictions['NPI_str'] = predictions['NPI'].astype(str)
predictions_mapped = predictions.merge(id_mapping, left_on='NPI_str', right_on='SequentialID', how='left')

# Replace NPI with real NPI
predictions_mapped['NPI'] = predictions_mapped['RealNPI'].fillna(predictions_mapped['NPI'])
predictions_mapped.drop(['NPI_str', 'SequentialID', 'RealNPI'], axis=1, inplace=True)

print(f"\n✓ Mapped NPIs:")
print(f"  Before: {predictions['NPI'].head(10).tolist()}")
print(f"  After: {predictions_mapped['NPI'].head(10).tolist()}")

# 5. Now merge with prescriber overview to get names and territories
print("\nMerging with prescriber data...")
profile_cols_renamed = overview_unique.copy()
profile_cols_renamed.columns = [f'{c}_profile' if c != 'PrescriberId' else c for c in profile_cols_renamed.columns]

final = predictions_mapped.merge(profile_cols_renamed, left_on='NPI', right_on='PrescriberId', how='left')

# Use profile data where available
final['PrescriberName'] = final['PrescriberName_profile'].fillna('HCP-' + final['NPI'].astype(str))
final['Territory'] = final['TerritoryName_profile'].fillna(final.get('State', 'Unknown'))
final['City'] = final['City_profile'].fillna(final.get('City', ''))
final['State'] = final['State_profile'].fillna(final.get('State', ''))
final['Tier'] = final['TirosintTargetTier_profile'].fillna(
    final.get('FlectorTargetTier_profile', pd.Series(['Silver'] * len(final))).fillna('Silver')
)

# Drop profile helper columns
profile_cols_to_drop = [c for c in final.columns if c.endswith('_profile') or c == 'PrescriberId']
final.drop(profile_cols_to_drop, axis=1, inplace=True)

# Reorder columns
essential_cols = ['NPI', 'PrescriberName', 'Specialty', 'City', 'State', 'Territory', 'Tier', 
                  'TRx_Current', 'flector_trx', 'licart_trx']
other_cols = [c for c in final.columns if c not in essential_cols]
final = final[[c for c in essential_cols if c in final.columns] + other_cols]

print(f"\n✓ Final dataset: {len(final):,} HCPs")
print(f"✓ HCPs with real names: {(final['PrescriberName'] != final['PrescriberName'].str.startswith('HCP-')).sum():,}")

# 6. Save to UI data folder
output_file = BASE_DIR / "ibsa_precall_ui" / "public" / "data" / "IBSA_ModelReady_Enhanced_WithPredictions.csv"
final.to_csv(output_file, index=False)
print(f"\n✅ Saved to: {output_file}")
print(f"   Size: {output_file.stat().st_size / (1024*1024):.1f} MB")

# Show sample
print("\nSample rows:")
print(final[['NPI', 'PrescriberName', 'Specialty', 'City', 'State', 'Territory']].head(5).to_string(index=False))
