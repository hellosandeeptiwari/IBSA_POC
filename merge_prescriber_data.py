"""
Merge phase7 predictions with prescriber profile data to add names and territories
"""
import pandas as pd
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).parent
PREDICTIONS_FILE = BASE_DIR / "ibsa-poc-eda" / "outputs" / "phase7" / "IBSA_ModelReady_Enhanced_WithPredictions.csv"
PROFILE_FILE = BASE_DIR / "ibsa-poc-eda" / "data" / "Reporting_BI_PrescriberOverview.csv"
OUTPUT_FILE = BASE_DIR / "ibsa_precall_ui" / "public" / "data" / "IBSA_ModelReady_Enhanced_WithPredictions.csv"

print("Loading predictions (streaming in chunks to limit memory)...")
# chunk size for processing predictions
CHUNK_SIZE = 50000
predictions_iter = pd.read_csv(PREDICTIONS_FILE, chunksize=CHUNK_SIZE, dtype=str, low_memory=True)
print(f"✓ Will process predictions in chunks of {CHUNK_SIZE:,}")

print("\nLoading prescriber profiles (this may take a moment)...")
# Only load the columns we need to keep memory usage low on large CSV
profile_cols = ['PrescriberId', 'PrescriberName', 'TerritoryName', 'City', 'State', 'Zipcode',
                'TirosintTargetTier', 'FlectorTargetTier', 'LicartTargetTier']
profiles = pd.read_csv(PROFILE_FILE, usecols=profile_cols, dtype={'PrescriberId': str}, low_memory=True)
print(f"✓ Loaded {len(profiles):,} prescriber profiles (columns: {', '.join(profiles.columns)})")

# Clean PrescriberId in profiles
profiles['PrescriberId'] = profiles['PrescriberId'].astype(str).str.replace('.0', '', regex=False)

# Rename profile columns to avoid collision during merge (we'll prefer profile values)
profiles.rename(columns={
    'PrescriberName': 'PrescriberName_prof',
    'TerritoryName': 'TerritoryName_prof',
    'City': 'City_prof',
    'State': 'State_prof',
    'Zipcode': 'Zipcode_prof',
    'TirosintTargetTier': 'TirosintTargetTier_prof',
    'FlectorTargetTier': 'FlectorTargetTier_prof',
    'LicartTargetTier': 'LicartTargetTier_prof'
}, inplace=True)

print("\nMerging data (chunked)...")

# Prepare output file (overwrite) and counters
first_chunk = True
total_rows = 0
total_with_names = 0
total_with_territories = 0

for i, chunk in enumerate(predictions_iter, start=1):
    print(f"Processing chunk {i} (rows: {len(chunk):,})...")
    # Normalize NPI in chunk
    chunk['NPI'] = chunk['NPI'].astype(str).str.replace('.0', '', regex=False)

    # Merge with profiles (profiles loaded with only required columns)
    merged = chunk.merge(profiles, left_on='NPI', right_on='PrescriberId', how='left')

    # Prefer profile values when available (profile columns were renamed with _prof)
    if 'City_prof' in merged.columns:
        merged['City'] = merged['City_prof'].fillna(merged.get('City', ''))
    if 'State_prof' in merged.columns:
        merged['State'] = merged['State_prof'].fillna(merged.get('State', ''))

    # PrescriberName: prefer profile, else any existing PrescriberName in chunk, else HCP-NPI
    if 'PrescriberName_prof' in merged.columns:
        merged['PrescriberName'] = merged['PrescriberName_prof'].fillna('HCP-' + merged['NPI'].astype(str))
    elif 'PrescriberName' not in merged.columns:
        merged['PrescriberName'] = 'HCP-' + merged['NPI'].astype(str)

    # Territory: prefer TerritoryName_prof, else State, else Unknown
    if 'TerritoryName_prof' in merged.columns:
        merged['Territory'] = merged['TerritoryName_prof'].fillna(merged.get('State', 'Unknown'))
    else:
        merged['Territory'] = merged.get('State', 'Unknown')

    # Tier: prefer Tirosint_prof, then Flector_prof, then Licart_prof, then default
    if 'TirosintTargetTier_prof' in merged.columns:
        merged['Tier'] = merged['TirosintTargetTier_prof'].fillna(
            merged.get('FlectorTargetTier_prof', pd.Series(['Silver'] * len(merged))).fillna(
                merged.get('LicartTargetTier_prof', pd.Series(['Silver'] * len(merged))).fillna('Silver')
            )
        )
    else:
        merged['Tier'] = 'Silver'

    # Drop profile helper columns and PrescriberId
    cols_to_drop = ['PrescriberId', 'TerritoryName', 'TirosintTargetTier', 'FlectorTargetTier', 
                    'LicartTargetTier', 'Zipcode', 'Zipcode_x', 'Zipcode_y',
                    'PrescriberName_prof', 'TerritoryName_prof', 'City_prof', 'State_prof',
                    'Zipcode_prof', 'TirosintTargetTier_prof', 'FlectorTargetTier_prof', 'LicartTargetTier_prof']
    merged.drop([c for c in cols_to_drop if c in merged.columns], axis=1, inplace=True)

    essential_cols = ['NPI', 'PrescriberName', 'Specialty', 'City', 'State', 'Territory', 'Tier', 
                      'TRx_Current', 'flector_trx', 'licart_trx']
    other_cols = [c for c in merged.columns if c not in essential_cols]
    # Ensure columns exist before reordering
    final_cols = [c for c in essential_cols if c in merged.columns] + other_cols
    merged = merged[final_cols]

    # Write chunk to output (first chunk writes header)
    mode = 'w' if first_chunk else 'a'
    header = first_chunk
    merged.to_csv(OUTPUT_FILE, index=False, mode=mode, header=header)

    # Update counters
    total_rows += len(merged)
    total_with_names += (merged['PrescriberName'].notna()).sum()
    total_with_territories += (merged['Territory'] != 'Unknown').sum()
    first_chunk = False

print(f"\n✓ Merged data written to {OUTPUT_FILE}")
print(f"✓ Total merged rows: {total_rows:,}")
print(f"✓ Total with names: {total_with_names:,}")
print(f"✓ Total with territories: {total_with_territories:,}")

# Print a sample row from the generated file
sample = pd.read_csv(OUTPUT_FILE, nrows=1, dtype=str, low_memory=True)
print("\nSample row:")
print(sample[['NPI', 'PrescriberName', 'Specialty', 'Territory', 'City', 'State', 'Tier']].to_dict('records')[0])
