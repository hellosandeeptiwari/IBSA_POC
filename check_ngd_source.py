"""Check NGD data source - engineered flags or predictions?"""
import pandas as pd

df = pd.read_csv(
    'ibsa-poc-eda/outputs/features/IBSA_Features_CLEANED_20251030_035304.csv',
    usecols=['ngd_type', 'is_ngd_new', 'is_ngd_grower', 'is_ngd_decliner', 'tirosint_trx', 'PrescriberId']
)

print(f"\n{'='*80}")
print("NGD DATA SOURCE ANALYSIS")
print(f"{'='*80}\n")

print("NGD Type Distribution:")
print(df['ngd_type'].value_counts())
print(f"\nTotal HCPs: {len(df):,}")

print(f"\n{'='*80}")
print("NGD FLAGS (Binary Indicators)")
print(f"{'='*80}")
print(f"is_ngd_new:      {df['is_ngd_new'].sum():>8,} HCPs ({df['is_ngd_new'].sum()/len(df)*100:>5.2f}%)")
print(f"is_ngd_grower:   {df['is_ngd_grower'].sum():>8,} HCPs ({df['is_ngd_grower'].sum()/len(df)*100:>5.2f}%)")
print(f"is_ngd_decliner: {df['is_ngd_decliner'].sum():>8,} HCPs ({df['is_ngd_decliner'].sum()/len(df)*100:>5.2f}%)")

stable = len(df) - df['is_ngd_new'].sum() - df['is_ngd_grower'].sum() - df['is_ngd_decliner'].sum()
print(f"Stable (inferred): {stable:>8,} HCPs ({stable/len(df)*100:>5.2f}%)")

print(f"\n{'='*80}")
print("SAMPLE ACTIVE PRESCRIBERS")
print(f"{'='*80}")
active = df[df['tirosint_trx'] > 0].head(20)
print(active[['PrescriberId', 'tirosint_trx', 'ngd_type', 'is_ngd_new', 'is_ngd_grower', 'is_ngd_decliner']].to_string())

print(f"\n{'='*80}")
print("CONCLUSION")
print(f"{'='*80}")
print("These are ENGINEERED FLAGS from Phase 4B feature engineering,")
print("NOT predictions from trained NGD classification models.")
print("\nSource: Phase 4B creates these binary flags based on:")
print("  - trx_lag features (historical TRx snapshots)")
print("  - Growth/decline patterns across periods")
print("  - Official NGD data if available")
