import pandas as pd
import glob

# Check Phase 4B files
files = glob.glob('ibsa-poc-eda/outputs/features/IBSA_Features_Phase4B_*.csv')
if files:
    print(f"Found Phase 4B file: {files[-1]}")
    df = pd.read_csv(files[-1], nrows=5)
    
    # Check for product-specific TRx columns
    product_trx_cols = [c for c in df.columns if any(p in c.lower() for p in ['tirosint', 'flector', 'licart']) and 'trx' in c.lower()]
    print(f"\nProduct TRx columns in Phase 4B: {product_trx_cols}")
    
    # Check if they exist
    if 'tirosint_trx' in df.columns:
        print("✓ tirosint_trx exists")
    if 'flector_trx' in df.columns:
        print("✓ flector_trx exists")
    if 'licart_trx' in df.columns:
        print("✓ licart_trx exists")
else:
    print("No Phase 4B files found")

# Check cleaned file
cleaned_file = 'ibsa-poc-eda/outputs/features/IBSA_Features_CLEANED_20251030_025000.csv'
df_clean = pd.read_csv(cleaned_file, nrows=5)
product_trx_cols_clean = [c for c in df_clean.columns if any(p in c.lower() for p in ['tirosint', 'flector', 'licart']) and 'trx' in c.lower()]
print(f"\nProduct TRx columns in CLEANED: {product_trx_cols_clean}")
