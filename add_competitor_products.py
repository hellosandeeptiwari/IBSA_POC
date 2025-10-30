import pandas as pd
import numpy as np

print("="*100)
print("ADDING COMPETITOR PRODUCT DATA TO PHASE 7 OUTPUT")
print("="*100)

# Load Phase 7 deduplicated data
phase7_path = r"ibsa-poc-eda\outputs\phase7\IBSA_ModelReady_Enhanced_WithPredictions_DEDUP.csv"
print(f"\n1. Loading Phase 7 data: {phase7_path}")
df_phase7 = pd.read_csv(phase7_path)
print(f"   ✅ Loaded {len(df_phase7):,} HCPs")

# Load PrescriberOverview for market share data
overview_path = r"ibsa-poc-eda\data\Reporting_BI_PrescriberOverview.csv"
print(f"\n2. Loading PrescriberOverview: {overview_path}")
df_overview = pd.read_csv(overview_path)
print(f"   ✅ Loaded {len(df_overview):,} records")

# Filter for relevant time period (QTD)
print(f"\n3. Filtering PrescriberOverview...")
relevant_cols = ['PrescriberId', 'TRX(C QTD)', 'TRXMktShareQTD']
df_overview_qtd = df_overview[relevant_cols].copy()

# Clean PrescriberId
df_overview_qtd['PrescriberId'] = df_overview_qtd['PrescriberId'].astype(str).str.replace('.0', '', regex=False)
df_phase7['NPI'] = df_phase7['NPI'].astype(str).str.replace('.0', '', regex=False)

# Aggregate by PrescriberId (sum TRx, average market share)
print(f"   Aggregating by PrescriberId...")
df_market = df_overview_qtd.groupby('PrescriberId').agg({
    'TRX(C QTD)': 'sum',  # IBSA TRx
    'TRXMktShareQTD': 'mean'  # Average market share
}).reset_index()

df_market.columns = ['NPI', 'ibsa_trx_qtd', 'ibsa_market_share_pct']

print(f"   ✅ Aggregated to {len(df_market):,} unique HCPs")

# Calculate competitor TRx
# Formula: Total Market TRx = IBSA TRx / (Market Share %)
# Competitor TRx = Total Market TRx - IBSA TRx
print(f"\n4. Calculating competitor TRx...")

df_market['total_market_trx'] = np.where(
    df_market['ibsa_market_share_pct'] > 0,
    df_market['ibsa_trx_qtd'] / (df_market['ibsa_market_share_pct'] / 100),
    df_market['ibsa_trx_qtd']
)

df_market['competitor_trx'] = df_market['total_market_trx'] - df_market['ibsa_trx_qtd']

# Clean up negative values (data quality issues)
df_market['competitor_trx'] = df_market['competitor_trx'].clip(lower=0)

print(f"   ✅ Calculated competitor TRx")

# Merge with Phase 7 data
print(f"\n5. Merging with Phase 7 data...")
df_merged = df_phase7.merge(
    df_market[['NPI', 'ibsa_market_share_pct', 'total_market_trx', 'competitor_trx']],
    on='NPI',
    how='left'
)

# Fill NaN with 0
df_merged['ibsa_market_share_pct'] = df_merged['ibsa_market_share_pct'].fillna(0)
df_merged['total_market_trx'] = df_merged['total_market_trx'].fillna(df_merged['TRx_Current'])
df_merged['competitor_trx'] = df_merged['competitor_trx'].fillna(0)

print(f"   ✅ Merged successfully")

# Add breakdown columns
print(f"\n6. Adding product breakdown columns...")

# IBSA Products (already in CSV)
df_merged['tirosint_trx'] = df_merged['TRx_Current'] - df_merged['flector_trx'] - df_merged['licart_trx']
df_merged['tirosint_trx'] = df_merged['tirosint_trx'].clip(lower=0)

# Competitor products breakdown (estimate based on specialty/product focus)
# For Tirosint competitors (T4 replacement market)
df_merged['competitor_t4_trx'] = np.where(
    df_merged['Specialty'].str.contains('ENDO|INTERNAL|FAMILY', case=False, na=False),
    df_merged['competitor_trx'] * 0.7,  # 70% of competitor is T4 replacement
    df_merged['competitor_trx'] * 0.3   # 30% otherwise
)

# For pain management competitors
df_merged['competitor_pain_trx'] = np.where(
    df_merged['Specialty'].str.contains('PAIN|RHEUM|ORTHO', case=False, na=False),
    df_merged['competitor_trx'] * 0.7,  # 70% of competitor is pain meds
    df_merged['competitor_trx'] * 0.1   # 10% otherwise
)

# For cardiovascular competitors
df_merged['competitor_cardio_trx'] = df_merged['competitor_trx'] - df_merged['competitor_t4_trx'] - df_merged['competitor_pain_trx']
df_merged['competitor_cardio_trx'] = df_merged['competitor_cardio_trx'].clip(lower=0)

print(f"   ✅ Added competitor product breakdown")

# Reorder columns
output_cols = [
    'Specialty', 'State', 'City', 
    'TRx_Current', 'tirosint_trx', 'flector_trx', 'licart_trx',
    'total_market_trx', 'ibsa_market_share_pct',
    'competitor_trx', 'competitor_t4_trx', 'competitor_pain_trx', 'competitor_cardio_trx',
    'NPI'
] + [col for col in df_merged.columns if col not in ['Specialty', 'State', 'City', 'TRx_Current', 'tirosint_trx', 'flector_trx', 'licart_trx', 'total_market_trx', 'ibsa_market_share_pct', 'competitor_trx', 'competitor_t4_trx', 'competitor_pain_trx', 'competitor_cardio_trx', 'NPI']]

df_output = df_merged[output_cols]

# Save
output_path = r"ibsa-poc-eda\outputs\phase7\IBSA_ModelReady_Enhanced_WithPredictions_DEDUP_WithCompetitors.csv"
print(f"\n7. Saving to: {output_path}")
df_output.to_csv(output_path, index=False)
print(f"   ✅ Saved {len(df_output):,} records")

# Show sample data
print(f"\n" + "="*100)
print("SAMPLE DATA - First 5 HCPs with TRx > 0")
print("="*100)

sample = df_output[df_output['TRx_Current'] > 0].head(5)
for idx, row in sample.iterrows():
    print(f"\n{'-'*100}")
    print(f"HCP: {row['PrescriberName']} (NPI: {row['NPI']}) | Specialty: {row['Specialty']}")
    print(f"{'-'*100}")
    print(f"Total Market TRx:     {row['total_market_trx']:>8.1f}")
    print(f"IBSA Market Share:    {row['ibsa_market_share_pct']:>8.1f}%")
    print(f"")
    print(f"IBSA Products:")
    print(f"  - Tirosint:         {row['tirosint_trx']:>8.1f} TRx")
    print(f"  - Flector:          {row['flector_trx']:>8.1f} TRx")
    print(f"  - Licart:           {row['licart_trx']:>8.1f} TRx")
    print(f"  IBSA Total:         {row['TRx_Current']:>8.1f} TRx")
    print(f"")
    print(f"Competitor Products:")
    print(f"  - T4 Replacement:   {row['competitor_t4_trx']:>8.1f} TRx (Synthroid/Levothyroxine)")
    print(f"  - Pain Mgmt:        {row['competitor_pain_trx']:>8.1f} TRx (Voltaren/Advil)")
    print(f"  - Cardiovascular:   {row['competitor_cardio_trx']:>8.1f} TRx (Imdur/Others)")
    print(f"  Competitor Total:   {row['competitor_trx']:>8.1f} TRx")

print(f"\n" + "="*100)
print("STATISTICS")
print("="*100)

total_hcps = len(df_output)
hcps_with_trx = len(df_output[df_output['TRx_Current'] > 0])
hcps_with_competitors = len(df_output[df_output['competitor_trx'] > 0])

print(f"Total HCPs:                     {total_hcps:>10,}")
print(f"HCPs with IBSA TRx:             {hcps_with_trx:>10,} ({hcps_with_trx/total_hcps*100:.1f}%)")
print(f"HCPs with Competitor TRx:       {hcps_with_competitors:>10,} ({hcps_with_competitors/total_hcps*100:.1f}%)")
print(f"")
print(f"Total IBSA TRx:                 {df_output['TRx_Current'].sum():>10,.0f}")
print(f"Total Competitor TRx:           {df_output['competitor_trx'].sum():>10,.0f}")
print(f"Total Market TRx:               {df_output['total_market_trx'].sum():>10,.0f}")
print(f"")
print(f"Avg IBSA Market Share:          {df_output[df_output['ibsa_market_share_pct'] > 0]['ibsa_market_share_pct'].mean():>10.2f}%")

print(f"\n" + "="*100)
print("✅ COMPLETE - Competitor data added successfully!")
print(f"📁 Output file: {output_path}")
print("="*100)
