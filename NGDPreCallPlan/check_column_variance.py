import pandas as pd
import numpy as np

# Load the deduplicated CSV
csv_path = r"ibsa-poc-eda\outputs\phase7\IBSA_ModelReady_Enhanced_WithPredictions_DEDUP.csv"
print(f"Loading data from: {csv_path}")

df = pd.read_csv(csv_path)

# Get first 50 records
df_top50 = df.head(50)

print(f"\n{'='*80}")
print(f"VARIANCE ANALYSIS - TOP 50 RECORDS")
print(f"{'='*80}\n")

# Columns we want to check for variance
columns_to_check = [
    'TRx_Current',
    'flector_trx',
    'licart_trx',
    'Tirosint_call_success_prob',
    'Tirosint_prescription_lift_pred',
    'Tirosint_wallet_share_growth_pred',
    'Flector_call_success_prob',
    'Flector_prescription_lift_pred',
    'Flector_wallet_share_growth_pred',
    'Licart_call_success_prob',
    'Licart_prescription_lift_pred',
    'Licart_wallet_share_growth_pred',
    'call_success_prob',
    'forecasted_lift',
    'expected_roi',
    'ngd_classification',
    'churn_risk',
    'sample_allocation'
]

# Numeric columns variance
print("NUMERIC COLUMNS - VARIANCE ANALYSIS")
print(f"{'-'*80}")
print(f"{'Column':<45} {'Min':<12} {'Max':<12} {'Mean':<12} {'Variance':<12}")
print(f"{'-'*80}")

for col in columns_to_check:
    if col in df_top50.columns:
        if col == 'ngd_classification':
            # For categorical, show unique values
            unique_vals = df_top50[col].unique()
            print(f"{col:<45} Unique: {len(unique_vals)} values - {list(unique_vals[:5])}")
        else:
            try:
                col_data = pd.to_numeric(df_top50[col], errors='coerce')
                min_val = col_data.min()
                max_val = col_data.max()
                mean_val = col_data.mean()
                variance = col_data.var()
                
                print(f"{col:<45} {min_val:<12.4f} {max_val:<12.4f} {mean_val:<12.4f} {variance:<12.4f}")
                
                # Flag if all zeros
                if max_val == 0:
                    print(f"  ⚠️  WARNING: All values are ZERO!")
                # Flag if no variance
                elif variance < 0.0001:
                    print(f"  ⚠️  WARNING: Very low variance (almost constant)!")
                    
            except Exception as e:
                print(f"{col:<45} ERROR: {str(e)}")
    else:
        print(f"{col:<45} ❌ NOT FOUND IN CSV")

print(f"\n{'-'*80}")
print("\nPRODUCT-SPECIFIC TRx BREAKDOWN (Top 50 records)")
print(f"{'-'*80}")

total_trx = df_top50['TRx_Current'].sum()
flector_trx = df_top50['flector_trx'].sum()
licart_trx = df_top50['licart_trx'].sum()
tirosint_trx = total_trx - flector_trx - licart_trx

print(f"Total TRx:         {total_trx:>10.0f}")
print(f"Flector TRx:       {flector_trx:>10.0f} ({flector_trx/max(total_trx,1)*100:>6.2f}%)")
print(f"Licart TRx:        {licart_trx:>10.0f} ({licart_trx/max(total_trx,1)*100:>6.2f}%)")
print(f"Tirosint TRx:      {tirosint_trx:>10.0f} ({tirosint_trx/max(total_trx,1)*100:>6.2f}%)")

print(f"\n{'-'*80}")
print("NON-ZERO COUNTS (How many HCPs have non-zero values)")
print(f"{'-'*80}")

for col in ['TRx_Current', 'flector_trx', 'licart_trx', 'call_success_prob', 'forecasted_lift', 'expected_roi']:
    if col in df_top50.columns:
        col_data = pd.to_numeric(df_top50[col], errors='coerce')
        non_zero_count = (col_data != 0).sum()
        print(f"{col:<45} {non_zero_count:>3}/50 HCPs have non-zero values")

print(f"\n{'-'*80}")
print("SAMPLE DATA - First 5 Records")
print(f"{'-'*80}\n")

# Show key columns for first 5 records
display_cols = ['NPI', 'PrescriberName', 'TRx_Current', 'flector_trx', 'licart_trx', 
                'call_success_prob', 'forecasted_lift', 'expected_roi', 'ngd_classification']

available_cols = [col for col in display_cols if col in df_top50.columns]
print(df_top50[available_cols].head(5).to_string(index=False))

print(f"\n{'='*80}")
print("SUMMARY")
print(f"{'='*80}")

# Check for problematic columns (all zeros or no variance)
problematic_cols = []
for col in columns_to_check:
    if col in df_top50.columns and col != 'ngd_classification':
        try:
            col_data = pd.to_numeric(df_top50[col], errors='coerce')
            if col_data.max() == 0:
                problematic_cols.append(f"{col} (all zeros)")
            elif col_data.var() < 0.0001:
                problematic_cols.append(f"{col} (no variance)")
        except:
            pass

if problematic_cols:
    print(f"\n⚠️  PROBLEMATIC COLUMNS (need attention):")
    for col in problematic_cols:
        print(f"   - {col}")
else:
    print(f"\n✅ All columns have good variance!")

print(f"\n{'='*80}\n")
