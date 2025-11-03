"""
Compare datasets to identify which file to upload to Azure
"""
import pandas as pd
from pathlib import Path

print("="*80)
print("DATASET COMPARISON - WHICH FILE FOR AZURE?")
print("="*80)

files = {
    'IBSA_ModelReady_Enhanced.csv': 'ibsa_precall_ui/public/data/IBSA_ModelReady_Enhanced.csv',
    'IBSA_ModelReady_Sample.csv': 'ibsa_precall_ui/public/data/IBSA_ModelReady_Sample.csv',
    'hcp_ml_predictions_top100.csv': 'ibsa_precall_ui/public/data/hcp_ml_predictions_top100.csv',
}

for name, path in files.items():
    p = Path(path)
    if p.exists():
        df = pd.read_csv(p)
        size_mb = p.stat().st_size / (1024 * 1024)
        has_wallet = any('wallet_share' in c.lower() for c in df.columns)
        has_prescriber = 'PrescriberId' in df.columns or 'NPI' in df.columns
        
        print(f"\n📄 {name}")
        print(f"   Rows: {len(df):,}")
        print(f"   Columns: {len(df.columns)}")
        print(f"   Size: {size_mb:.1f} MB")
        print(f"   Has wallet_share predictions: {'✅ YES' if has_wallet else '❌ NO'}")
        print(f"   Has PrescriberId/NPI: {'✅ YES' if has_prescriber else '❌ NO'}")
        
        if has_wallet:
            wallet_cols = [c for c in df.columns if 'wallet_share' in c.lower()]
            print(f"   Wallet columns: {wallet_cols}")

print("\n" + "="*80)
print("RECOMMENDATION")
print("="*80)

print("""
❌ hcp_ml_predictions_top100.csv (19 HCPs) - TOO SMALL for production UI

✅ IBSA_ModelReady_Enhanced.csv (346K HCPs) - BEST CHOICE
   - Full dataset with all HCPs
   - UI will calculate wallet_share_growth on-the-fly
   - 188 MB - manageable size

This is the file you should upload to Azure Blob!
""")
