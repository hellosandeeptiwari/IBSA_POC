#!/usr/bin/env python3
"""
Reduce call_history.csv to most recent 10 calls per HCP
"""

import pandas as pd
from pathlib import Path

print("=" * 80)
print("REDUCING CALL HISTORY TO RECENT CALLS PER HCP")
print("=" * 80)

# Load the large CSV
input_path = Path('ibsa-poc-eda/data/call_history.csv')
print(f"\n📂 Loading: {input_path}")
print(f"   Size: {input_path.stat().st_size / 1024 / 1024:.1f} MB")

df = pd.read_csv(input_path)
print(f"✅ Loaded: {len(df):,} calls")
print(f"   Unique HCPs: {df['npi'].nunique():,}")

# Keep only most recent 10 calls per HCP
print("\n✂️ Reducing to 10 most recent calls per HCP...")
df['call_date'] = pd.to_datetime(df['call_date'])
df = df.sort_values('call_date', ascending=False)
df_reduced = df.groupby('npi').head(10).reset_index(drop=True)
df_reduced['call_date'] = df_reduced['call_date'].dt.strftime('%Y-%m-%d')

print(f"✅ Reduced to: {len(df_reduced):,} calls")
print(f"   Unique HCPs: {df_reduced['npi'].nunique():,}")

# Copy to UI public/data folder
output_path = Path('ibsa_precall_ui/public/data/call_history.csv')
output_path.parent.mkdir(parents=True, exist_ok=True)
df_reduced.to_csv(output_path, index=False)

print(f"\n✅ Saved to: {output_path}")
print(f"   Size: {output_path.stat().st_size / 1024:.1f} KB")
print("=" * 80)
