"""
Identify the correct CSV file to upload to Azure Blob
"""

import pandas as pd
from pathlib import Path
import os

print("="*100)
print("AZURE BLOB UPLOAD - FILE IDENTIFICATION")
print("="*100)

# Check for the main dataset that UI expects
candidates = [
    "ibsa_precall_ui/public/data/IBSA_ModelReady_Sample.csv",
    "ibsa_precall_ui/public/data/IBSA_ModelReady_Enhanced.csv",
    "ibsa-poc-eda/outputs/features/IBSA_Features_CLEANED_20251030_035304.csv",
]

print("\n📁 Checking potential CSV files...\n")

best_file = None
best_score = 0

for file_path in candidates:
    path = Path(file_path)
    if path.exists():
        size_mb = path.stat().st_size / (1024 * 1024)
        df = pd.read_csv(path, nrows=5)  # Just check structure
        
        print(f"✅ {file_path}")
        print(f"   Size: {size_mb:.1f} MB")
        print(f"   Rows: {pd.read_csv(path).shape[0]:,}")
        print(f"   Columns: {len(df.columns)}")
        
        # Score based on requirements
        score = 0
        required = ['PrescriberId', 'Specialty', 'State', 'trx_current_qtd', 'ngd_decile']
        has_cols = [col for col in required if col in df.columns]
        score = len(has_cols)
        
        print(f"   Required columns present: {len(has_cols)}/{len(required)}")
        print(f"   Columns: {', '.join(df.columns[:10])}...")
        
        if score > best_score:
            best_score = score
            best_file = file_path
        print()
    else:
        print(f"❌ {file_path} (not found)")
        print()

print("="*100)
print("RECOMMENDATION")
print("="*100)

if best_file:
    path = Path(best_file)
    size_mb = path.stat().st_size / (1024 * 1024)
    df = pd.read_csv(path)
    
    print(f"\n🎯 UPLOAD THIS FILE TO AZURE BLOB:\n")
    print(f"   📄 File: {best_file}")
    print(f"   📊 Size: {size_mb:.1f} MB")
    print(f"   👥 Rows: {len(df):,} HCPs")
    print(f"   📋 Columns: {len(df.columns)}")
    
    # Check if it has the wallet share growth predictions
    wallet_cols = [c for c in df.columns if 'wallet_share' in c.lower()]
    if wallet_cols:
        print(f"\n   ⚠️  WARNING: This file already has wallet_share columns: {wallet_cols}")
        print(f"      The UI will calculate these dynamically based on NGD decile")
        print(f"      Consider using the file WITHOUT pre-calculated predictions")
    
    print(f"\n📋 Key columns present:")
    key_cols = ['PrescriberId', 'PrescriberName', 'Specialty', 'State', 'TerritoryName', 
                'trx_current_qtd', 'trx_prior_qtd', 'ngd_decile', 'call_success_score']
    for col in key_cols:
        status = "✅" if col in df.columns else "❌"
        print(f"      {status} {col}")
    
    print(f"\n🔗 Azure Blob Upload Steps:")
    print(f"   1. Go to Azure Portal → Storage Account")
    print(f"   2. Container: ngddatasets")
    print(f"   3. Upload file: {Path(best_file).name}")
    print(f"   4. Set URL in .env.local: NEXT_PUBLIC_BLOB_URL=https://ibsangdpocdata.blob.core.windows.net/ngddatasets/{Path(best_file).name}")
    print(f"   5. Make blob public or use SAS token if needed")
    
else:
    print("\n❌ No suitable CSV file found!")
    print("\n💡 You need a CSV with:")
    print("   - PrescriberId (NPI)")
    print("   - Specialty, State")
    print("   - TerritoryName, RegionName")
    print("   - trx_current_qtd, trx_prior_qtd")
    print("   - ngd_decile, call_success_score")
    print("   - All Phase 4C feature engineering columns")

print("\n" + "="*100)
print("HOW THE UI WORKS WITH THIS FILE")
print("="*100)
print("""
1. UI loads CSV from Azure Blob (all HCPs)
2. For each HCP, data-loader.ts calculates predictions:
   
   a) wallet_share_growth calculation:
      tirosint_wallet_share_growth = 3 + (ngd_decile / 10) * 6  // 3-9pp
      flector_wallet_share_growth = 2 + (ngd_decile / 10) * 5   // 2-7pp
      licart_wallet_share_growth = 1 + (ngd_decile / 10) * 4    // 1-5pp
   
   b) Other predictions based on:
      - call_success_score
      - ngd_decile
      - specialty flags (is_endocrinology, etc.)
      - trx data
   
3. UI displays these calculated predictions to user

✅ This approach means:
   - No need to run Phase 7 on ALL HCPs
   - UI calculates predictions on-the-fly
   - Fast, efficient, scalable
   
⚠️  Note: These are approximations based on features, not actual model predictions
   For real model predictions, you would need to:
   - Run Phase 7 on ALL HCPs (not just top 100)
   - Or set up FastAPI backend to call models in real-time
""")

print("="*100)
