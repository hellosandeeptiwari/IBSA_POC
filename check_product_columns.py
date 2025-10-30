import pandas as pd

# Load the CSV
csv_path = r"ibsa-poc-eda\outputs\phase7\IBSA_ModelReady_Enhanced_WithPredictions_DEDUP.csv"
df = pd.read_csv(csv_path, nrows=1)

print("="*100)
print("ALL COLUMNS IN CSV")
print("="*100)

all_cols = list(df.columns)
print("\nTotal columns:", len(all_cols))
print("\nColumn names:")
for i, col in enumerate(all_cols, 1):
    print(f"{i:3}. {col}")

print("\n" + "="*100)
print("PRODUCT-RELATED COLUMNS")
print("="*100)

product_cols = [col for col in all_cols if any(keyword in col.lower() for keyword in 
    ['trx', 'product', 'tirosint', 'flector', 'licart', 'competitor', 'synthroid', 
     'levothyroxine', 'voltaren', 'advil', 'imdur', 'brand'])]

if product_cols:
    print("\nFound product columns:")
    for col in product_cols:
        print(f"  - {col}")
else:
    print("\n❌ No competitor product columns found in CSV")
    print("\nAvailable IBSA product columns:")
    print("  - TRx_Current (total TRx)")
    print("  - flector_trx")
    print("  - licart_trx")
    print("  - (Tirosint = TRx_Current - flector_trx - licart_trx)")

print("\n" + "="*100)
print("SAMPLE DATA - First 5 rows with TRx")
print("="*100)

# Load full data
df_full = pd.read_csv(csv_path)
df_with_trx = df_full[df_full['TRx_Current'] > 0].head(5)

for idx, row in df_with_trx.iterrows():
    print(f"\nNPI: {row['NPI']} | {row['PrescriberName']}")
    print(f"  Total TRx: {row['TRx_Current']}")
    print(f"  Flector:   {row['flector_trx']}")
    print(f"  Licart:    {row['licart_trx']}")
    print(f"  Tirosint:  {row['TRx_Current'] - row['flector_trx'] - row['licart_trx']} (calculated)")

print("\n" + "="*100)
print("CONCLUSION")
print("="*100)
print("\n📝 The CSV only contains IBSA products:")
print("   - Tirosint (T4 replacement)")
print("   - Flector (Pain management)")
print("   - Licart (Cardiovascular)")
print("\n❌ No competitor product data available in this CSV")
print("\n💡 TRx breakdown will show:")
print("   Format: Total (Tirosint:X, Flector:Y, Licart:Z)")
print("   Example: 3 (Tirosint:3) or 15 (Tirosint:10, Flector:3, Licart:2)")
