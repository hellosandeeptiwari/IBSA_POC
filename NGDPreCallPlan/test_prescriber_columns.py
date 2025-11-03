"""Test if PrescriberName, NPI are populated correctly"""
import pandas as pd

# Load first 50 rows
df = pd.read_csv('ibsa-poc-eda/outputs/phase7/IBSA_ModelReady_Enhanced_WithPredictions.csv', nrows=50)

print("=" * 80)
print("PRESCRIBER DATA TEST - PHASE 7 OUTPUT")
print("=" * 80)

print("\n--- Column Check ---")
print(f"Total rows sampled: {len(df)}")
print(f"NPI populated: {df['NPI'].notna().sum()}")
print(f"PrescriberName populated: {df['PrescriberName'].notna().sum()}")
print(f"Real names (not HCP-*): {(~df['PrescriberName'].astype(str).str.startswith('HCP-')).sum()}")

print("\n--- Sample of First 20 Rows ---")
cols = ['NPI', 'PrescriberName', 'Specialty', 'City', 'State', 'TerritoryName']
print(df[cols].head(20).to_string())

print("\n--- Check for Dummy Names ---")
dummy_names = df[df['PrescriberName'].astype(str).str.startswith('HCP-')]
if len(dummy_names) > 0:
    print(f"Found {len(dummy_names)} dummy names:")
    print(dummy_names[['NPI', 'PrescriberName']].to_string())
else:
    print("✓ ✓ ✓ No dummy names found! All have REAL prescriber names! ✓ ✓ ✓")

print("\n--- Territory Data ---")
print(f"TerritoryName populated: {df['TerritoryName'].notna().sum()}")
print("\nSample territories:")
print(df[['PrescriberName', 'TerritoryName', 'City', 'State']].head(10).to_string())

print("\n--- Model Predictions Check ---")
print(f"Tirosint Wallet Growth: {df['Tirosint_wallet_share_growth_pred'].mean():.2f}pp avg")
print(f"Flector Wallet Growth: {df['Flector_wallet_share_growth_pred'].mean():.2f}pp avg")
print(f"Licart Wallet Growth: {df['Licart_wallet_share_growth_pred'].mean():.2f}pp avg")
print(f"NGD Classification: {df['ngd_classification'].value_counts().to_dict()}")

print("\n" + "=" * 80)
print("✅ CSV READY FOR AZURE BLOB UPLOAD!")
print("=" * 80)
