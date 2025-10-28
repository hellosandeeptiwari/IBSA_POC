#!/usr/bin/env python3
"""
CREATE UI-COMPATIBLE DATASET
============================
Creates a UI-ready version of the clean ModelReady dataset
Adds back display-only columns that were removed from ML training

APPROACH:
- Use CLEAN lag-feature dataset (zero temporal leakage for ML)
- Add back "display-only" versions of removed features for UI
- These display columns are for UI/reporting ONLY, never used in model training
"""

import pandas as pd
import numpy as np
import os
from datetime import datetime

print("="*80)
print("CREATING UI-COMPATIBLE DATASET")
print("="*80)

# Load CLEAN dataset (with lag features)
clean_file = r'ibsa-poc-eda\outputs\targets\IBSA_ModelReady_Enhanced_20251022_1119.csv'
print(f"\nLoading clean dataset: {os.path.basename(clean_file)}")
df = pd.read_csv(clean_file, low_memory=False)
print(f"  Rows: {len(df):,}")
print(f"  Columns: {len(df.columns)}")

# Load Prescriber Overview for display data
overview_file = r'ibsa-poc-eda\data\Reporting_BI_PrescriberOverview.csv'
print(f"\nLoading Prescriber Overview for display fields...")
overview_df = pd.read_csv(overview_file, low_memory=False)

# Aggregate to get latest snapshot per HCP
overview_agg = overview_df.groupby('PrescriberId').agg({
    'PrescriberName': 'first',
    'Address': 'first',
    'City': 'first',
    'State': 'first',
    'Zipcode': 'first',
    'Specialty': 'first',
    'TerritoryId': 'first',
    'TerritoryName': 'first',
    'RegionId': 'first',
    'RegionName': 'first',
    'LastCallDate': 'first',
    'TRX(C QTD)': 'last',  # For DISPLAY only
    'TRX(P QTD)': 'last',
    'NRX(C QTD)': 'last',
    'NRX(P QTD)': 'last',
}).reset_index()

print(f"  Aggregated to {len(overview_agg):,} unique HCPs")

# Merge display fields
print(f"\nMerging display fields...")
df['PrescriberId'] = pd.to_numeric(df['PrescriberId'], errors='coerce').astype('Int64')
overview_agg['PrescriberId'] = pd.to_numeric(overview_agg['PrescriberId'], errors='coerce').astype('Int64')

df_ui = df.merge(overview_agg, on='PrescriberId', how='left', suffixes=('', '_display'))

print(f"  Merged: {len(df_ui):,} rows")

# Add DISPLAY-ONLY versions of removed leaky features
# These are for UI visualization ONLY, never used in model training
print(f"\nAdding display-only fields (for UI visualization)...")

# 1. trx_current_qtd (DISPLAY ONLY - shows current prescriptions)
if 'TRX(C QTD)' in df_ui.columns:
    df_ui['trx_current_qtd'] = df_ui['TRX(C QTD)'].fillna(0)
    print(f"  ✓ trx_current_qtd (display only)")

# 2. trx_qtd_growth (DISPLAY ONLY - shows historical growth)
if 'TRX(C QTD)' in df_ui.columns and 'TRX(P QTD)' in df_ui.columns:
    df_ui['trx_qtd_growth'] = (df_ui['TRX(C QTD)'] - df_ui['TRX(P QTD)']).fillna(0)
    print(f"  ✓ trx_qtd_growth (display only)")

# 3. nrx_current_qtd (DISPLAY ONLY)
if 'NRX(C QTD)' in df_ui.columns:
    df_ui['nrx_current_qtd'] = df_ui['NRX(C QTD)'].fillna(0)
    print(f"  ✓ nrx_current_qtd (display only)")

# 4. nrx_qtd_growth (DISPLAY ONLY)
if 'NRX(C QTD)' in df_ui.columns and 'NRX(P QTD)' in df_ui.columns:
    df_ui['nrx_qtd_growth'] = (df_ui['NRX(C QTD)'] - df_ui['NRX(P QTD)']).fillna(0)
    print(f"  ✓ nrx_qtd_growth (display only)")

# 5. growth_opportunity (DISPLAY ONLY - use historical version for display)
if 'growth_opportunity_hist' in df_ui.columns:
    df_ui['growth_opportunity'] = df_ui['growth_opportunity_hist']
    print(f"  ✓ growth_opportunity (from historical version)")

# 6. hcp_value_score (DISPLAY ONLY - create safe display version)
# Use ONLY historical features (no current period data)
if 'trx_prior_qtd' in df_ui.columns and 'nrx_prior_qtd' in df_ui.columns:
    trx_norm = df_ui['trx_prior_qtd'] / df_ui['trx_prior_qtd'].max()
    nrx_norm = df_ui['nrx_prior_qtd'] / df_ui['nrx_prior_qtd'].max()
    engagement_norm = df_ui.get('engagement_score', 0) / 100.0
    
    df_ui['hcp_value_score'] = (
        trx_norm.fillna(0) * 0.5 + 
        nrx_norm.fillna(0) * 0.3 + 
        engagement_norm.fillna(0) * 0.2
    ).clip(0, 1)
    print(f"  ✓ hcp_value_score (display only, from historical data)")

# 7. hcp_value_quintile (DISPLAY ONLY)
if 'hcp_value_score' in df_ui.columns:
    try:
        df_ui['hcp_value_quintile'] = pd.qcut(
            df_ui['hcp_value_score'], 
            q=5, 
            labels=False,
            duplicates='drop'
        ) + 1  # Make it 1-5 instead of 0-4
        df_ui['hcp_value_quintile'] = df_ui['hcp_value_quintile'].fillna(3).astype(int)
    except:
        # Fallback if qcut fails
        df_ui['hcp_value_quintile'] = 3
    print(f"  ✓ hcp_value_quintile (display only)")

# 8. Rename Specialty if merged
if 'Specialty_y' in df_ui.columns:
    df_ui['Specialty'] = df_ui['Specialty_y'].fillna(df_ui.get('Specialty_x', ''))
    df_ui = df_ui.drop(columns=['Specialty_x', 'Specialty_y'], errors='ignore')

# 9. Rename State if merged
if 'State_y' in df_ui.columns:
    df_ui['State'] = df_ui['State_y'].fillna(df_ui.get('State_x', ''))
    df_ui = df_ui.drop(columns=['State_x', 'State_y'], errors='ignore')

# Select columns for UI (include display fields but mark as display-only)
print(f"\nFinal dataset:")
print(f"  Rows: {len(df_ui):,}")
print(f"  Columns: {len(df_ui.columns)}")

# Drop temporary columns
df_ui = df_ui.drop(columns=['TRX(C QTD)', 'TRX(P QTD)', 'NRX(C QTD)', 'NRX(P QTD)'], errors='ignore')

# Save UI-compatible dataset
output_file = r'ibsa_precall_ui\public\data\IBSA_ModelReady_Enhanced.csv'
print(f"\nSaving UI-compatible dataset...")
df_ui.to_csv(output_file, index=False)
print(f"  ✓ Saved: {output_file}")
print(f"  ✓ Size: {os.path.getsize(output_file) / 1024 / 1024:.1f} MB")

print("\n" + "="*80)
print("UI-COMPATIBLE DATASET CREATED!")
print("="*80)
print("\n⚠️  IMPORTANT NOTES:")
print("  • Display fields (trx_current_qtd, growth_opportunity, etc.) are for UI ONLY")
print("  • These fields were NOT used in model training (zero leakage)")
print("  • ML models use CLEAN lag features (trx_qtd_lag1, growth_opportunity_hist)")
print("  • UI can safely display historical data for context")
print("\n✅ UI can now run with updated dataset!")
print("="*80)
