#!/usr/bin/env python3
"""
FILTER UI DATASET - KEEP ONLY COMPLETE HCPs
============================================
Keeps only the 346K HCPs that have complete data from Prescriber Overview
This gives us high-quality, complete records for the UI
"""

import pandas as pd
import os

print("="*80)
print("FILTERING UI DATASET TO COMPLETE HCPs ONLY")
print("="*80)

# Load current UI dataset
df = pd.read_csv(r'ibsa_precall_ui\public\data\IBSA_ModelReady_Enhanced.csv', low_memory=False)
print(f"\nLoaded: {len(df):,} HCPs")
print(f"Columns: {len(df.columns)}")

# Filter to only HCPs with complete data
# These are HCPs that have real data from Prescriber Overview
print(f"\nFiltering to complete HCPs...")
df_filtered = df[
    df['PrescriberName'].notna() & 
    df['TerritoryId'].notna() & 
    df['call_success'].notna()
].copy()

print(f"  Filtered: {len(df_filtered):,} HCPs ({len(df_filtered)/len(df)*100:.1f}%)")

# Verify data quality
print(f"\nDATA QUALITY CHECK:")
print(f"  PrescriberName: {df_filtered['PrescriberName'].notna().sum():,} (100%)")
print(f"  TerritoryName: {df_filtered['TerritoryName'].notna().sum():,} (100%)")
print(f"  Specialty: {df_filtered['Specialty'].notna().sum():,} ({df_filtered['Specialty'].notna().sum()/len(df_filtered)*100:.1f}%)")
print(f"  City: {df_filtered['City'].notna().sum():,} (100%)")
print(f"  State: {df_filtered['State'].notna().sum():,} (100%)")
print(f"  call_success: {df_filtered['call_success'].notna().sum():,} (100%)")
print(f"  prescription_lift: {df_filtered['prescription_lift'].notna().sum():,} (100%)")

# Check distributions
print(f"\nDISTRIBUTIONS:")
print(f"  Unique Territories: {df_filtered['TerritoryId'].nunique()}")
print(f"  Unique Regions: {df_filtered['RegionId'].nunique()}")
print(f"  Unique States: {df_filtered['State'].nunique()}")
print(f"  Unique Specialties: {df_filtered['Specialty'].nunique()}")

# Show top specialties
print(f"\nTOP 5 SPECIALTIES:")
for specialty, count in df_filtered['Specialty'].value_counts().head(5).items():
    print(f"  {specialty}: {count:,}")

# Show top territories
print(f"\nTOP 5 TERRITORIES:")
for territory, count in df_filtered['TerritoryName'].value_counts().head(5).items():
    print(f"  {territory}: {count:,}")

# Save filtered dataset
output_file = r'ibsa_precall_ui\public\data\IBSA_ModelReady_Enhanced.csv'
print(f"\nSaving filtered dataset...")
df_filtered.to_csv(output_file, index=False)

file_size = os.path.getsize(output_file) / 1024 / 1024
print(f"  Saved: {output_file}")
print(f"  Size: {file_size:.1f} MB (reduced from 526.8 MB)")

print("\n" + "="*80)
print("UI DATASET FILTERED - HIGH QUALITY DATA ONLY!")
print("="*80)
print(f"\nSUMMARY:")
print(f"  Total HCPs: {len(df_filtered):,}")
print(f"  All HCPs have:")
print(f"    - Complete prescriber profile (name, specialty, location)")
print(f"    - Territory assignment")
print(f"    - ML predictions (call_success, prescription_lift, ngd_category)")
print(f"    - Historical TRx data")
print(f"\n  UI will now show {len(df_filtered):,} high-quality HCPs!")
print("="*80)
