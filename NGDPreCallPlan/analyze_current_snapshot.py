"""Analyze what temporal/trend data we CAN show with current data"""
import pandas as pd
import numpy as np

df = pd.read_csv(
    'ibsa-poc-eda/outputs/features/IBSA_Features_CLEANED_20251030_035304.csv',
    usecols=['tirosint_trx', 'flector_trx', 'licart_trx', 'total_trx', 
             'Specialty', 'Territory', 'Tier', 'Wallet_Share_IBSA']
)

print(f"\n{'='*80}")
print("TEMPORAL INSIGHTS FROM CURRENT SNAPSHOT")
print(f"{'='*80}\n")

print(f"📊 Total Universe: {len(df):,} HCPs\n")

# Tier Distribution (tiers are based on historical performance)
print("="*80)
print("HCP TIERS (Based on Historical Performance)")
print("="*80)
tier_summary = df.groupby('Tier').agg({
    'tirosint_trx': ['count', 'sum', 'mean'],
    'total_trx': 'sum'
}).round(1)
print(tier_summary)

print("\n" + "="*80)
print("ACTIVE PRESCRIBER PENETRATION (Current Period)")
print("="*80)
print(f"🏥 Tirosint Active Writers:  {(df['tirosint_trx'] > 0).sum():>7,} HCPs ({(df['tirosint_trx'] > 0).sum()/len(df)*100:>5.1f}%)")
print(f"💊 Flector Active Writers:   {(df['flector_trx'] > 0).sum():>7,} HCPs ({(df['flector_trx'] > 0).sum()/len(df)*100:>5.1f}%)")
print(f"❤️  Licart Active Writers:    {(df['licart_trx'] > 0).sum():>7,} HCPs ({(df['licart_trx'] > 0).sum()/len(df)*100:>5.1f}%)")
print(f"📋 Any IBSA Product:         {(df[['tirosint_trx', 'flector_trx', 'licart_trx']].sum(axis=1) > 0).sum():>7,} HCPs ({(df[['tirosint_trx', 'flector_trx', 'licart_trx']].sum(axis=1) > 0).sum()/len(df)*100:>5.1f}%)")

print("\n" + "="*80)
print("PRESCRIBER CONCENTRATION (Pareto Analysis)")
print("="*80)
active_hcps = df[df['total_trx'] > 0].copy()
active_hcps = active_hcps.sort_values('total_trx', ascending=False)
active_hcps['cumsum_trx'] = active_hcps['total_trx'].cumsum()
active_hcps['cum_pct'] = active_hcps['cumsum_trx'] / active_hcps['total_trx'].sum() * 100

top_10_pct = int(len(active_hcps) * 0.10)
top_20_pct = int(len(active_hcps) * 0.20)

trx_from_top10 = active_hcps.iloc[:top_10_pct]['total_trx'].sum()
trx_from_top20 = active_hcps.iloc[:top_20_pct]['total_trx'].sum()
total_trx = active_hcps['total_trx'].sum()

print(f"Top 10% HCPs ({top_10_pct:,}):  {trx_from_top10:>10,.0f} TRx ({trx_from_top10/total_trx*100:>5.1f}% of total)")
print(f"Top 20% HCPs ({top_20_pct:,}): {trx_from_top20:>10,.0f} TRx ({trx_from_top20/total_trx*100:>5.1f}% of total)")

print("\n" + "="*80)
print("TOP 10 SPECIALTIES (Current Period Volume)")
print("="*80)
spec_summary = df.groupby('Specialty').agg({
    'total_trx': 'sum',
    'tirosint_trx': 'sum',
    'Wallet_Share_IBSA': 'mean'
}).sort_values('total_trx', ascending=False).head(10)

for idx, (spec, row) in enumerate(spec_summary.iterrows(), 1):
    print(f"{idx:2d}. {spec:<35} | {row['total_trx']:>8,.0f} TRx | Tirosint: {row['tirosint_trx']:>7,.0f} | Wallet: {row['Wallet_Share_IBSA']:>5.1f}%")

print("\n" + "="*80)
print("PORTFOLIO MIX (Current Period)")
print("="*80)
total_tirosint = df['tirosint_trx'].sum()
total_flector = df['flector_trx'].sum()
total_licart = df['licart_trx'].sum()
portfolio_total = total_tirosint + total_flector + total_licart

print(f"Tirosint:  {total_tirosint:>10,.0f} TRx ({total_tirosint/portfolio_total*100:>5.1f}%)")
print(f"Flector:   {total_flector:>10,.0f} TRx ({total_flector/portfolio_total*100:>5.1f}%)")
print(f"Licart:    {total_licart:>10,.0f} TRx ({total_licart/portfolio_total*100:>5.1f}%)")
print(f"{'─'*60}")
print(f"TOTAL:     {portfolio_total:>10,.0f} TRx")

print(f"\n{'='*80}\n")
