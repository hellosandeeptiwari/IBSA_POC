"""
Copy phase7 predictions to UI data folder with enhanced metadata
Since PrescriberId is an internal index, we'll use descriptive names based on available metadata
"""
import pandas as pd
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).parent
PREDICTIONS_FILE = BASE_DIR / "ibsa-poc-eda" / "outputs" / "phase7" / "IBSA_ModelReady_Enhanced_WithPredictions.csv"
OUTPUT_FILE = BASE_DIR / "ibsa_precall_ui" / "public" / "data" / "IBSA_ModelReady_Enhanced_WithPredictions.csv"

print("Loading predictions...")
df = pd.read_csv(PREDICTIONS_FILE, low_memory=False)
print(f"✓ Loaded {len(df):,} HCP predictions")

# Create a readable PrescriberName from available metadata
# Format: "Specialty - City, State" for better UX
df['PrescriberName'] = (df['Specialty'].fillna('Unknown Specialty') + ' - ' + 
                         df['City'].fillna('Unknown City') + ', ' + 
                         df['State'].fillna('??'))

# Set Territory to State (since we don't have territory mapping)
df['Territory'] = df['State'].fillna('Unknown')

# Set default Tier
df['Tier'] = 'Silver'

# Reorder columns - put essential ones first
essential_cols = ['NPI', 'PrescriberName', 'Specialty', 'City', 'State', 'Territory', 'Tier', 
                  'TRx_Current', 'flector_trx', 'licart_trx']
other_cols = [c for c in df.columns if c not in essential_cols]
df = df[[c for c in essential_cols if c in df.columns] + other_cols]

print(f"\n✓ Prepared data with {len(df):,} HCPs")
print(f"✓ Sample names:")
print(df[['NPI', 'PrescriberName']].head(5).to_string(index=False))

# Save
print(f"\nSaving to {OUTPUT_FILE}...")
df.to_csv(OUTPUT_FILE, index=False)
print(f"✓ Saved {len(df):,} HCPs")

# Show sample
print("\nSample row:")
print(df[['NPI', 'PrescriberName', 'Specialty', 'Territory', 'City', 'State', 'Tier']].head(1).to_dict('records')[0])
