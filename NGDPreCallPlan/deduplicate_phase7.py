"""Deduplicate Phase 7 output by NPI - keep first occurrence per unique NPI"""
import pandas as pd

print('Loading CSV with all rows...')
df = pd.read_csv('ibsa-poc-eda/outputs/phase7/IBSA_ModelReady_Enhanced_WithPredictions.csv')

print(f'Original rows: {len(df):,}')
print(f'Unique NPIs: {df["NPI"].nunique():,}')

# Check for duplicates
duplicates = df.duplicated(subset=['NPI'], keep=False)
print(f'Duplicate NPIs: {duplicates.sum():,}')

if duplicates.sum() > 0:
    print('\nSample duplicates (first 5):')
    dup_npis = df[duplicates]['NPI'].unique()[:5]
    for npi in dup_npis:
        print(f'\nNPI {npi}:')
        print(df[df['NPI'] == npi][['NPI', 'PrescriberName', 'Specialty', 'TerritoryName']].to_string())

# Deduplicate - keep first occurrence per NPI
print('\nDeduplicating by NPI (keeping first occurrence)...')
df_dedup = df.drop_duplicates(subset=['NPI'], keep='first')

print(f'Deduplicated rows: {len(df_dedup):,}')
print(f'Removed: {len(df) - len(df_dedup):,} duplicate rows')

# Save deduplicated version
output_file = 'ibsa-poc-eda/outputs/phase7/IBSA_ModelReady_Enhanced_WithPredictions_DEDUP.csv'
print(f'\nSaving deduplicated file to: {output_file}')
df_dedup.to_csv(output_file, index=False)

import os
file_size_mb = os.path.getsize(output_file) / (1024*1024)
print(f'✅ Deduplicated file size: {file_size_mb:.1f} MB')
print(f'✅ Ready for Azure upload!')
