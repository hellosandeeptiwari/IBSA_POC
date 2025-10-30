"""Verify ALL records in the Phase 7 output CSV"""
import pandas as pd

print('Loading full CSV (349,864 records)...')
df = pd.read_csv('ibsa-poc-eda/outputs/phase7/IBSA_ModelReady_Enhanced_WithPredictions.csv')

print('\n' + '='*80)
print('FULL DATASET VERIFICATION - ALL RECORDS')
print('='*80)

print(f'\nTotal HCPs: {len(df):,}')
print(f'NPI populated: {df["NPI"].notna().sum():,}')
print(f'PrescriberName populated: {df["PrescriberName"].notna().sum():,}')

# Check real vs dummy names
real_names = (~df["PrescriberName"].astype(str).str.startswith("HCP-")).sum()
dummy_names = (df["PrescriberName"].astype(str).str.startswith("HCP-")).sum()

print(f'\n--- NAME QUALITY ---')
print(f'✅ Real names: {real_names:,} ({real_names/len(df)*100:.1f}%)')
print(f'⚠️  Dummy names (HCP-*): {dummy_names:,} ({dummy_names/len(df)*100:.1f}%)')

print(f'\n--- TERRITORY DATA ---')
print(f'TerritoryName populated: {df["TerritoryName"].notna().sum():,} ({df["TerritoryName"].notna().sum()/len(df)*100:.1f}%)')

print(f'\n--- SAMPLE REAL NAMES (Random 15) ---')
real_name_df = df[~df["PrescriberName"].astype(str).str.startswith("HCP-")]
sample = real_name_df.sample(min(15, len(real_name_df)))[["NPI", "PrescriberName", "TerritoryName"]]
print(sample.to_string())

print(f'\n--- MODEL PREDICTIONS SUMMARY ---')
print(f'Call Success Prob: {df["call_success_prob"].mean():.2%}')
print(f'Forecasted Lift: {df["forecasted_lift"].mean():.1f} TRx')
print(f'Tirosint Wallet Growth: {df["Tirosint_wallet_share_growth_pred"].mean():.2f}pp')
print(f'Flector Wallet Growth: {df["Flector_wallet_share_growth_pred"].mean():.2f}pp')
print(f'Licart Wallet Growth: {df["Licart_wallet_share_growth_pred"].mean():.2f}pp')

print(f'\n--- NGD CLASSIFICATION ---')
ngd_dist = df["ngd_classification"].value_counts()
for category, count in ngd_dist.items():
    print(f'{category}: {count:,} ({count/len(df)*100:.1f}%)')

print(f'\n--- SEGMENT DISTRIBUTION ---')
segment_dist = df["hcp_segment_name"].value_counts().head(5)
for segment, count in segment_dist.items():
    print(f'{segment}: {count:,} ({count/len(df)*100:.1f}%)')

# File size
import os
file_size_mb = os.path.getsize('ibsa-poc-eda/outputs/phase7/IBSA_ModelReady_Enhanced_WithPredictions.csv') / (1024*1024)
print(f'\n--- FILE INFO ---')
print(f'File size: {file_size_mb:.1f} MB')
print(f'Columns: {len(df.columns)}')

if real_names / len(df) > 0.95:
    print('\n' + '='*80)
    print('✅ ✅ ✅  EXCELLENT! 95%+ HAVE REAL NAMES - READY FOR UPLOAD  ✅ ✅ ✅')
    print('='*80)
elif real_names / len(df) > 0.80:
    print('\n' + '='*80)
    print('✅ GOOD! 80%+ have real names - Ready for upload')
    print('='*80)
else:
    print('\n' + '='*80)
    print(f'⚠️  WARNING: Only {real_names/len(df)*100:.1f}% have real names')
    print('='*80)
