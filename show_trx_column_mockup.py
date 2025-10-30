import pandas as pd

# Load sample data
csv_path = r"ibsa-poc-eda\outputs\phase7\IBSA_ModelReady_Enhanced_WithPredictions_DEDUP.csv"
df = pd.read_csv(csv_path)

# Get first 10 records with TRx > 0
df_with_trx = df[df['TRx_Current'] > 0].head(10)

print("="*100)
print("PROPOSED GRID LAYOUT - Total TRx Column with Product Breakdown")
print("="*100)
print("\nExample of how the 'Total TRx' column will display:\n")

for idx, row in df_with_trx.iterrows():
    npi = row['NPI']
    name = row['PrescriberName']
    total_trx = row['TRx_Current']
    flector_trx = row['flector_trx'] if pd.notna(row['flector_trx']) else 0
    licart_trx = row['licart_trx'] if pd.notna(row['licart_trx']) else 0
    tirosint_trx = total_trx - flector_trx - licart_trx
    
    print(f"\n{'-'*100}")
    print(f"HCP: {name} (NPI: {npi})")
    print(f"{'-'*100}")
    
    # Show what the Total TRx cell will contain
    print(f"Total TRx Cell Content:")
    print(f"┌─────────────────────────────────────┐")
    print(f"│ Total: {total_trx:>5.0f} TRx                   │")
    print(f"│ ─────────────────────────────────── │")
    
    if tirosint_trx > 0:
        print(f"│ 💊 Tirosint:  {tirosint_trx:>5.0f} ({tirosint_trx/total_trx*100:>5.1f}%)       │")
    if flector_trx > 0:
        print(f"│ 💊 Flector:   {flector_trx:>5.0f} ({flector_trx/total_trx*100:>5.1f}%)       │")
    if licart_trx > 0:
        print(f"│ 💊 Licart:    {licart_trx:>5.0f} ({licart_trx/total_trx*100:>5.1f}%)       │")
    
    print(f"└─────────────────────────────────────┘")

print("\n" + "="*100)
print("VISUAL MOCKUP - How it will look in the grid:")
print("="*100)

print("\n┌─────────────┬──────────────────────────┬────────────────┬──────────────────────────────────┬────────────┐")
print("│ NPI         │ Prescriber Name          │ Specialty      │ Total TRx (Product Mix)          │ Territory  │")
print("├─────────────┼──────────────────────────┼────────────────┼──────────────────────────────────┼────────────┤")

for idx, row in df_with_trx.head(5).iterrows():
    npi = str(row['NPI'])[:10]
    name = str(row['PrescriberName'])[:24]
    specialty = str(row['Specialty'])[:14]
    territory = str(row['Territory'])[:10]
    
    total_trx = row['TRx_Current']
    flector_trx = row['flector_trx'] if pd.notna(row['flector_trx']) else 0
    licart_trx = row['licart_trx'] if pd.notna(row['licart_trx']) else 0
    tirosint_trx = total_trx - flector_trx - licart_trx
    
    # Create product breakdown text
    products = []
    if tirosint_trx > 0:
        products.append(f"T:{tirosint_trx:.0f}")
    if flector_trx > 0:
        products.append(f"F:{flector_trx:.0f}")
    if licart_trx > 0:
        products.append(f"L:{licart_trx:.0f}")
    
    product_text = f"{total_trx:.0f} ({', '.join(products)})" if products else f"{total_trx:.0f}"
    
    print(f"│ {npi:<11} │ {name:<24} │ {specialty:<14} │ {product_text:<32} │ {territory:<10} │")

print("└─────────────┴──────────────────────────┴────────────────┴──────────────────────────────────┴────────────┘")

print("\n" + "="*100)
print("LEGEND:")
print("="*100)
print("T: Tirosint (calculated: Total - Flector - Licart)")
print("F: Flector (from flector_trx column)")
print("L: Licart (from licart_trx column)")
print("\nFormat: Total (Product1:count, Product2:count, ...)")

print("\n" + "="*100)
print("CHANGES TO BE MADE:")
print("="*100)
print("1. ✅ Sort by NPI by default (ascending)")
print("2. ❌ Remove: Tirosint TRx column")
print("3. ❌ Remove: Flector TRx column")
print("4. ❌ Remove: Licart TRx column")
print("5. ✅ Update: Total TRx column to show product breakdown inline")
print("6. 📝 Note: No competitor data available in CSV (only IBSA products)")

print("\n" + "="*100)
print("Confirm to proceed? (Yes/No)")
print("="*100)
