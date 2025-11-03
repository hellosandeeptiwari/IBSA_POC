import pandas as pd
import numpy as np

print("="*100)
print("ADDING NRX COMPETITOR BREAKDOWN TO PHASE 7 OUTPUT")
print("="*100)

# Load the enhanced file with TRx competitor data
input_path = r"ibsa-poc-eda\outputs\phase7\IBSA_ModelReady_Enhanced_WithPredictions_DEDUP_WithCompetitors_v2.csv"
print(f"\n1. Loading data with TRx competitor breakdown: {input_path}")
df = pd.read_csv(input_path)
print(f"   ✅ Loaded {len(df):,} HCPs")

# Load PrescriberOverview for NRx market share data
overview_path = r"ibsa-poc-eda\data\Reporting_BI_PrescriberOverview.csv"
print(f"\n2. Loading PrescriberOverview for NRx data: {overview_path}")
df_overview = pd.read_csv(overview_path)
print(f"   ✅ Loaded {len(df_overview):,} records")

# Filter for NRx columns
print(f"\n3. Extracting NRx market share data...")
nrx_cols = ['PrescriberId', 'NRX(C QTD)', 'NRXMktShareQTD']
df_nrx = df_overview[nrx_cols].copy()

# Clean PrescriberId
df_nrx['PrescriberId'] = df_nrx['PrescriberId'].astype(str).str.replace('.0', '', regex=False)
df['NPI'] = df['NPI'].astype(str).str.replace('.0', '', regex=False)

# Aggregate by PrescriberId
df_nrx_agg = df_nrx.groupby('PrescriberId').agg({
    'NRX(C QTD)': 'sum',
    'NRXMktShareQTD': 'mean'
}).reset_index()

df_nrx_agg.columns = ['NPI', 'ibsa_nrx_qtd', 'ibsa_nrx_market_share_pct']
print(f"   ✅ Aggregated to {len(df_nrx_agg):,} unique HCPs")

# Calculate competitor NRx
print(f"\n4. Calculating competitor NRx...")
df_nrx_agg['total_market_nrx'] = np.where(
    df_nrx_agg['ibsa_nrx_market_share_pct'] > 0,
    df_nrx_agg['ibsa_nrx_qtd'] / (df_nrx_agg['ibsa_nrx_market_share_pct'] / 100),
    df_nrx_agg['ibsa_nrx_qtd']
)

df_nrx_agg['competitor_nrx'] = df_nrx_agg['total_market_nrx'] - df_nrx_agg['ibsa_nrx_qtd']
df_nrx_agg['competitor_nrx'] = df_nrx_agg['competitor_nrx'].clip(lower=0)

print(f"   ✅ Calculated competitor NRx")

# Merge with main data
print(f"\n5. Merging NRx data...")
df_merged = df.merge(
    df_nrx_agg[['NPI', 'ibsa_nrx_qtd', 'ibsa_nrx_market_share_pct', 'total_market_nrx', 'competitor_nrx']],
    on='NPI',
    how='left'
)

# Fill NaN
df_merged['ibsa_nrx_qtd'] = df_merged['ibsa_nrx_qtd'].fillna(0)
df_merged['ibsa_nrx_market_share_pct'] = df_merged['ibsa_nrx_market_share_pct'].fillna(0)
df_merged['total_market_nrx'] = df_merged['total_market_nrx'].fillna(0)
df_merged['competitor_nrx'] = df_merged['competitor_nrx'].fillna(0)

print(f"   ✅ Merged NRx data")

# Calculate NRx competitor product breakdown using same ML logic as TRx
print(f"\n6. Calculating NRx competitor product breakdown using ML predictions...")

# Use wallet share growth predictions (same as TRx)
df_merged['comp_nrx_tirosint_pct'] = np.where(
    df_merged['total_wallet_growth'] > 0,
    df_merged['tirosint_wallet_growth'] / df_merged['total_wallet_growth'],
    0.4
)

df_merged['comp_nrx_flector_pct'] = np.where(
    df_merged['total_wallet_growth'] > 0,
    df_merged['flector_wallet_growth'] / df_merged['total_wallet_growth'],
    0.35
)

df_merged['comp_nrx_licart_pct'] = np.where(
    df_merged['total_wallet_growth'] > 0,
    df_merged['licart_wallet_growth'] / df_merged['total_wallet_growth'],
    0.25
)

# Apply distribution to competitor NRx
df_merged['competitor_nrx_synthroid_levothyroxine'] = df_merged['competitor_nrx'] * df_merged['comp_nrx_tirosint_pct']
df_merged['competitor_nrx_voltaren_diclofenac'] = df_merged['competitor_nrx'] * df_merged['comp_nrx_flector_pct']
df_merged['competitor_nrx_imdur_nitrates'] = df_merged['competitor_nrx'] * df_merged['comp_nrx_licart_pct']

# Refine based on specialty
endocrinology_mask = df_merged['Specialty'].str.contains('ENDO|THYROID', case=False, na=False)
pain_mask = df_merged['Specialty'].str.contains('PAIN|RHEUM|ORTHO|ANEST', case=False, na=False)
cardio_mask = df_merged['Specialty'].str.contains('CARDIO|INTERNAL', case=False, na=False)

df_merged.loc[endocrinology_mask, 'competitor_nrx_synthroid_levothyroxine'] *= 1.5
df_merged.loc[pain_mask, 'competitor_nrx_voltaren_diclofenac'] *= 1.5
df_merged.loc[cardio_mask, 'competitor_nrx_imdur_nitrates'] *= 1.5

# Renormalize
df_merged['comp_nrx_total_adjusted'] = (df_merged['competitor_nrx_synthroid_levothyroxine'] + 
                                         df_merged['competitor_nrx_voltaren_diclofenac'] + 
                                         df_merged['competitor_nrx_imdur_nitrates'])

df_merged['competitor_nrx_synthroid_levothyroxine'] = np.where(
    df_merged['comp_nrx_total_adjusted'] > 0,
    df_merged['competitor_nrx_synthroid_levothyroxine'] / df_merged['comp_nrx_total_adjusted'] * df_merged['competitor_nrx'],
    df_merged['competitor_nrx_synthroid_levothyroxine']
)

df_merged['competitor_nrx_voltaren_diclofenac'] = np.where(
    df_merged['comp_nrx_total_adjusted'] > 0,
    df_merged['competitor_nrx_voltaren_diclofenac'] / df_merged['comp_nrx_total_adjusted'] * df_merged['competitor_nrx'],
    df_merged['competitor_nrx_voltaren_diclofenac']
)

df_merged['competitor_nrx_imdur_nitrates'] = np.where(
    df_merged['comp_nrx_total_adjusted'] > 0,
    df_merged['competitor_nrx_imdur_nitrates'] / df_merged['comp_nrx_total_adjusted'] * df_merged['competitor_nrx'],
    df_merged['competitor_nrx_imdur_nitrates']
)

print(f"   ✅ Calculated NRx competitor product breakdown")

# Save final file
output_path = r"ibsa-poc-eda\outputs\phase7\IBSA_ModelReady_Enhanced_WithPredictions_DEDUP_Final.csv"
print(f"\n7. Saving final file: {output_path}")

# Reorder columns
output_cols = [
    'Specialty', 'State', 'City',
    # TRx columns
    'TRx_Current', 'tirosint_trx', 'flector_trx', 'licart_trx',
    'total_market_trx', 'ibsa_market_share_pct',
    'competitor_trx', 'competitor_synthroid_levothyroxine', 'competitor_voltaren_diclofenac', 'competitor_imdur_nitrates',
    # NRx columns
    'ibsa_nrx_qtd', 'total_market_nrx', 'ibsa_nrx_market_share_pct',
    'competitor_nrx', 'competitor_nrx_synthroid_levothyroxine', 'competitor_nrx_voltaren_diclofenac', 'competitor_nrx_imdur_nitrates',
    # Other columns
    'NPI'
] + [col for col in df_merged.columns if col not in [
    'Specialty', 'State', 'City', 'TRx_Current', 'tirosint_trx', 'flector_trx', 'licart_trx',
    'total_market_trx', 'ibsa_market_share_pct', 'competitor_trx', 
    'competitor_synthroid_levothyroxine', 'competitor_voltaren_diclofenac', 'competitor_imdur_nitrates',
    'ibsa_nrx_qtd', 'total_market_nrx', 'ibsa_nrx_market_share_pct', 'competitor_nrx',
    'competitor_nrx_synthroid_levothyroxine', 'competitor_nrx_voltaren_diclofenac', 'competitor_nrx_imdur_nitrates',
    'NPI', 'comp_nrx_tirosint_pct', 'comp_nrx_flector_pct', 'comp_nrx_licart_pct', 'comp_nrx_total_adjusted'
]]

df_output = df_merged[output_cols]
df_output.to_csv(output_path, index=False)
print(f"   ✅ Saved {len(df_output):,} records")

# Show sample data
print(f"\n" + "="*100)
print("SAMPLE DATA - TRx AND NRx WITH COMPETITOR BREAKDOWN")
print("="*100)

sample = df_output[(df_output['TRx_Current'] > 0) | (df_output['ibsa_nrx_qtd'] > 0)].head(5)

for idx, row in sample.iterrows():
    print(f"\n{'-'*100}")
    print(f"HCP: {row['PrescriberName']} (NPI: {row['NPI']}) | Specialty: {row['Specialty']}")
    print(f"{'-'*100}")
    
    # TRx section
    print(f"\n📊 TRx (Total Prescriptions)")
    print(f"   Total Market: {row['total_market_trx']:.0f} | IBSA Share: {row['ibsa_market_share_pct']:.1f}%")
    print(f"   ")
    print(f"   IBSA ({row['TRx_Current']:.0f}):")
    print(f"   ├─ Tirosint:  {row['tirosint_trx']:.0f}")
    print(f"   ├─ Flector:   {row['flector_trx']:.0f}")
    print(f"   └─ Licart:    {row['licart_trx']:.0f}")
    print(f"   ")
    print(f"   Competitor ({row['competitor_trx']:.0f}):")
    print(f"   ├─ Synthroid/Levothyroxine: {row['competitor_synthroid_levothyroxine']:.0f}")
    print(f"   ├─ Voltaren/Diclofenac:     {row['competitor_voltaren_diclofenac']:.0f}")
    print(f"   └─ Imdur/Nitrates:          {row['competitor_imdur_nitrates']:.0f}")
    
    # NRx section
    if row['total_market_nrx'] > 0:
        print(f"\n")
        print(f"📈 NRx (New Prescriptions)")
        print(f"   Total Market: {row['total_market_nrx']:.0f} | IBSA Share: {row['ibsa_nrx_market_share_pct']:.1f}%")
        print(f"   ")
        print(f"   IBSA: {row['ibsa_nrx_qtd']:.0f}")
        print(f"   ")
        print(f"   Competitor ({row['competitor_nrx']:.0f}):")
        print(f"   ├─ Synthroid/Levothyroxine: {row['competitor_nrx_synthroid_levothyroxine']:.0f}")
        print(f"   ├─ Voltaren/Diclofenac:     {row['competitor_nrx_voltaren_diclofenac']:.0f}")
        print(f"   └─ Imdur/Nitrates:          {row['competitor_nrx_imdur_nitrates']:.0f}")

print(f"\n" + "="*100)
print("STATISTICS")
print("="*100)

print(f"\n📊 TRx Statistics:")
print(f"   Total IBSA TRx:       {df_output['TRx_Current'].sum():>12,.0f}")
print(f"   Total Competitor TRx: {df_output['competitor_trx'].sum():>12,.0f}")
print(f"   Total Market TRx:     {df_output['total_market_trx'].sum():>12,.0f}")

print(f"\n📈 NRx Statistics:")
print(f"   Total IBSA NRx:       {df_output['ibsa_nrx_qtd'].sum():>12,.0f}")
print(f"   Total Competitor NRx: {df_output['competitor_nrx'].sum():>12,.0f}")
print(f"   Total Market NRx:     {df_output['total_market_nrx'].sum():>12,.0f}")

print(f"\n" + "="*100)
print("✅ COMPLETE - TRx AND NRx competitor breakdown added!")
print(f"📁 Output file: {output_path}")
print("="*100)
