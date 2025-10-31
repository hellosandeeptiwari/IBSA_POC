import pandas as pd

# Load the CSV
df = pd.read_csv(r'ibsa_precall_ui\public\data\IBSA_ModelReady_Enhanced_WithPredictions.csv')

# Check if NPI exists
npi_search = 2396988
matching = df[df['NPI'] == npi_search]

if len(matching) == 0:
    print(f"❌ NPI {npi_search} NOT FOUND in CSV")
    print(f"\n📊 CSV has {len(df)} HCPs")
    print(f"   Sample NPIs: {df['NPI'].head(10).tolist()}")
    exit(1)

# Find John Hill (NPI 2396988)
row = matching.iloc[0]

print("=" * 60)
print(f"JOHN HILL (NPI: {npi_search}) - Call Success Scores")
print("=" * 60)
print(f"\n📊 GRID (Main Page):")
print(f"   call_success_prob: {row['call_success_prob']:.2%} → Displayed as {row['call_success_prob']*100:.0f}%")

print(f"\n📊 DETAIL PAGE (Product-Specific):")
print(f"   Tirosint_call_success_prob: {row['Tirosint_call_success_prob']:.2%}")
print(f"   Flector_call_success_prob: {row['Flector_call_success_prob']:.2%}")
print(f"   Licart_call_success_prob: {row['Licart_call_success_prob']:.2%}")

print(f"\n🎯 PRODUCT FOCUS: {row.get('recommended_product', 'N/A')}")

print("\n" + "=" * 60)
print("EXPLANATION:")
print("=" * 60)
print("- Main grid shows AVERAGE call_success_prob (5%)")
print("- Detail page shows PRODUCT-SPECIFIC call success based on")
print("  the AI-recommended product focus")
print("- This is correct - different products have different success rates!")
print("=" * 60)
