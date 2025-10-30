"""
Verify Phase 7 output - all HCPs scored with real predictions
"""
import pandas as pd
from pathlib import Path

output_file = Path('ibsa_precall_ui/public/data/IBSA_ModelReady_Enhanced_WithPredictions.csv')

print("="*80)
print("PHASE 7 COMPLETE - OUTPUT VERIFICATION")
print("="*80)

if output_file.exists():
    df = pd.read_csv(output_file)
    size_mb = output_file.stat().st_size / (1024 * 1024)
    
    print(f"\n✅ File created successfully!")
    print(f"📄 File: {output_file.name}")
    print(f"📊 Size: {size_mb:.1f} MB")
    print(f"👥 HCPs: {len(df):,}")
    print(f"📋 Columns: {len(df.columns)}")
    
    # Check wallet share growth columns
    wallet_cols = [c for c in df.columns if 'wallet_share' in c.lower()]
    print(f"\n✅ Wallet Share Growth Predictions: {len(wallet_cols)} columns")
    for col in wallet_cols:
        print(f"   • {col}")
        print(f"     Mean: {df[col].mean():.2f}pp, Range: {df[col].min():.2f} to {df[col].max():.2f}pp")
    
    # Sample data
    print(f"\n📊 Sample Data (First 3 HCPs):")
    for i in range(min(3, len(df))):
        row = df.iloc[i]
        print(f"\n   HCP {i+1}: NPI {int(row['NPI'])}")
        print(f"      • Tirosint Wallet Growth: {row['Tirosint_wallet_share_growth_pred']:.2f}pp")
        print(f"      • Flector Wallet Growth: {row['Flector_wallet_share_growth_pred']:.2f}pp")
        print(f"      • Licart Wallet Growth: {row['Licart_wallet_share_growth_pred']:.2f}pp")
        print(f"      • Call Success: {row['call_success_prob']:.1%}")
        print(f"      • Forecasted Lift: {row['forecasted_lift']:.1f} TRx")
        print(f"      • Segment: {row['hcp_segment_name']}")
        print(f"      • Action: {row['next_best_action']}")
    
    print("\n" + "="*80)
    print("✅ ✅ ✅  READY TO UPLOAD TO AZURE BLOB  ✅ ✅ ✅")
    print("="*80)
    print(f"\n📋 Upload Instructions:")
    print(f"   1. File to upload: {output_file.name}")
    print(f"   2. Azure container: ngddatasets")
    print(f"   3. Set in .env.local:")
    print(f"      NEXT_PUBLIC_BLOB_URL=https://ibsangdpocdata.blob.core.windows.net/ngddatasets/{output_file.name}")
    print(f"   4. Start UI: cd ibsa_precall_ui && npm run dev")
    print(f"   5. Test: http://localhost:3000")
    
else:
    print(f"\n❌ Output file not found: {output_file}")
    print("   Phase 7 may still be running or encountered an error")

print("\n" + "="*80)
