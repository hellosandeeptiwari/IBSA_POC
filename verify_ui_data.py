"""
Verify UI data includes wallet_share_growth from Phase 7 predictions
"""

import pandas as pd
from pathlib import Path

# Check Phase 7 predictions file
predictions_file = Path("ibsa_precall_ui/public/data/hcp_ml_predictions_top100.csv")

if not predictions_file.exists():
    print(f"❌ Predictions file not found: {predictions_file}")
    exit(1)

# Load predictions
df = pd.read_csv(predictions_file)

print("="*80)
print("PHASE 7 PREDICTIONS - DATA VERIFICATION")
print("="*80)

print(f"\n✓ Loaded {len(df)} HCP predictions")
print(f"\n📊 Columns ({len(df.columns)}):")
for col in sorted(df.columns):
    print(f"   • {col}")

# Check for wallet_share_growth columns
wallet_cols = [c for c in df.columns if 'wallet_share_growth' in c.lower()]
print(f"\n🎯 Wallet Share Growth Columns ({len(wallet_cols)}):")
for col in wallet_cols:
    print(f"   • {col}")
    print(f"      Mean: {df[col].mean():.2f} pp")
    print(f"      Range: {df[col].min():.2f} to {df[col].max():.2f} pp")

# Sample predictions
print(f"\n📋 Sample HCP Predictions:")
sample = df.head(3)
for idx, row in sample.iterrows():
    print(f"\n   HCP {idx+1}: NPI {int(row['NPI'])}")
    print(f"      • Call Success: {row['call_success_prob']:.1%}")
    print(f"      • Forecasted Lift: {row['forecasted_lift']:.2f} TRx")
    if 'Tirosint_wallet_share_growth_pred' in row:
        print(f"      • Tirosint Wallet Growth: +{row['Tirosint_wallet_share_growth_pred']:.1f}pp")
    if 'Flector_wallet_share_growth_pred' in row:
        print(f"      • Flector Wallet Growth: +{row['Flector_wallet_share_growth_pred']:.1f}pp")
    if 'Licart_wallet_share_growth_pred' in row:
        print(f"      • Licart Wallet Growth: +{row['Licart_wallet_share_growth_pred']:.1f}pp")
    print(f"      • Segment: {row['hcp_segment_name']}")
    print(f"      • Action: {row['next_best_action']}")

# Verify all required fields
required_fields = [
    'NPI', 'call_success_prob', 'forecasted_lift', 'ngd_classification',
    'hcp_segment_name', 'next_best_action', 'sample_allocation'
]

missing = [f for f in required_fields if f not in df.columns]
if missing:
    print(f"\n⚠️  Missing required fields: {missing}")
else:
    print(f"\n✅ All required fields present")

# Check wallet share predictions
if wallet_cols:
    print(f"\n✅ Wallet share growth predictions available ({len(wallet_cols)} columns)")
else:
    print(f"\n❌ No wallet share growth predictions found!")

print("\n" + "="*80)
print("VERIFICATION COMPLETE")
print("="*80)
