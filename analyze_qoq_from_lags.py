"""Analyze QoQ-like growth from temporal lag features"""
import pandas as pd
import numpy as np

# Load data with lag features
df = pd.read_csv(
    'ibsa-poc-eda/outputs/features/IBSA_Features_CLEANED_20251030_035304.csv',
    usecols=[
        'tirosint_trx', 'trx_lag_1period', 'trx_lag_2period', 'trx_lag_3period',
        'trx_growth_recent', 'trx_trending_up', 'trx_trending_down', 'Specialty'
    ]
)

print(f"\n{'='*80}")
print("QOQ-STYLE ANALYSIS FROM LAG FEATURES")
print(f"{'='*80}\n")

# Filter to HCPs with complete lag data
df_complete = df.dropna(subset=['tirosint_trx', 'trx_lag_1period', 'trx_lag_2period', 'trx_lag_3period'])
print(f"📊 Sample: {len(df_complete):,} HCPs with complete temporal data (out of {len(df):,} total)\n")

# Calculate period-over-period growth rates
df_complete['qoq_current_vs_lag1'] = (
    (df_complete['tirosint_trx'] - df_complete['trx_lag_1period']) / 
    df_complete['trx_lag_1period'].replace(0, np.nan) * 100
)
df_complete['qoq_lag1_vs_lag2'] = (
    (df_complete['trx_lag_1period'] - df_complete['trx_lag_2period']) / 
    df_complete['trx_lag_2period'].replace(0, np.nan) * 100
)
df_complete['qoq_lag2_vs_lag3'] = (
    (df_complete['trx_lag_2period'] - df_complete['trx_lag_3period']) / 
    df_complete['trx_lag_3period'].replace(0, np.nan) * 100
)

print("="*80)
print("AGGREGATE PERIOD-OVER-PERIOD GROWTH RATES")
print("="*80)
print(f"📈 Current vs Previous Period:")
print(f"   Median: {df_complete['qoq_current_vs_lag1'].median():.1f}%")
print(f"   Mean:   {df_complete['qoq_current_vs_lag1'].mean():.1f}%")
print(f"   Growing HCPs: {(df_complete['qoq_current_vs_lag1'] > 0).sum():,} ({(df_complete['qoq_current_vs_lag1'] > 0).sum()/len(df_complete)*100:.1f}%)")
print(f"   Declining HCPs: {(df_complete['qoq_current_vs_lag1'] < 0).sum():,} ({(df_complete['qoq_current_vs_lag1'] < 0).sum()/len(df_complete)*100:.1f}%)\n")

print(f"📉 Previous vs 2 Periods Ago:")
print(f"   Median: {df_complete['qoq_lag1_vs_lag2'].median():.1f}%")
print(f"   Mean:   {df_complete['qoq_lag1_vs_lag2'].mean():.1f}%\n")

print(f"📊 2 Periods Ago vs 3 Periods Ago:")
print(f"   Median: {df_complete['qoq_lag2_vs_lag3'].median():.1f}%")
print(f"   Mean:   {df_complete['qoq_lag2_vs_lag3'].mean():.1f}%\n")

print("="*80)
print("HCP TRAJECTORY DISTRIBUTION")
print("="*80)
trending_up = df_complete['trx_trending_up'].sum()
trending_down = df_complete['trx_trending_down'].sum()
stable = len(df_complete) - trending_up - trending_down

print(f"🚀 Trending UP (consistent growth):    {trending_up:>7,} HCPs ({trending_up/len(df_complete)*100:>5.1f}%)")
print(f"📉 Trending DOWN (consistent decline): {trending_down:>7,} HCPs ({trending_down/len(df_complete)*100:>5.1f}%)")
print(f"➡️  Stable (no clear trend):          {stable:>7,} HCPs ({stable/len(df_complete)*100:>5.1f}%)\n")

print("="*80)
print("VOLUME CHANGES (Absolute TRx)")
print("="*80)
current_total = df_complete['tirosint_trx'].sum()
lag1_total = df_complete['trx_lag_1period'].sum()
lag2_total = df_complete['trx_lag_2period'].sum()
lag3_total = df_complete['trx_lag_3period'].sum()

print(f"📅 Period T (Current):       {current_total:>10,.0f} TRx")
print(f"📅 Period T-1 (Previous):    {lag1_total:>10,.0f} TRx  |  Change: {((current_total - lag1_total) / lag1_total * 100):>+6.2f}%")
print(f"📅 Period T-2 (2 Periods):   {lag2_total:>10,.0f} TRx  |  Change: {((lag1_total - lag2_total) / lag2_total * 100):>+6.2f}%")
print(f"📅 Period T-3 (3 Periods):   {lag3_total:>10,.0f} TRx  |  Change: {((lag2_total - lag3_total) / lag3_total * 100):>+6.2f}%\n")

print("="*80)
print("TOP 5 SPECIALTIES BY CURRENT VOLUME")
print("="*80)
specialty_summary = df_complete.groupby('Specialty').agg({
    'tirosint_trx': 'sum',
    'trx_lag_1period': 'sum',
    'qoq_current_vs_lag1': 'median'
}).sort_values('tirosint_trx', ascending=False).head(5)

for spec, row in specialty_summary.iterrows():
    current = row['tirosint_trx']
    previous = row['trx_lag_1period']
    growth = row['qoq_current_vs_lag1']
    print(f"{spec:<30} | Current: {current:>8,.0f} TRx | Previous: {previous:>8,.0f} TRx | Median Growth: {growth:>+6.1f}%")

print(f"\n{'='*80}")
print("✅ ANALYSIS COMPLETE - Ready for presentation slide")
print(f"{'='*80}\n")

# Calculate additional insights
accelerating = (
    (df_complete['qoq_current_vs_lag1'] > df_complete['qoq_lag1_vs_lag2']) &
    (df_complete['qoq_current_vs_lag1'] > 0)
).sum()

decelerating = (
    (df_complete['qoq_current_vs_lag1'] < df_complete['qoq_lag1_vs_lag2']) &
    (df_complete['qoq_current_vs_lag1'] < 0)
).sum()

print("📊 MOMENTUM INSIGHTS:")
print(f"   🚀 Accelerating Growth: {accelerating:,} HCPs (growth rate increasing)")
print(f"   🛑 Accelerating Decline: {decelerating:,} HCPs (decline rate worsening)")
print(f"   📈 Net Momentum: {accelerating - decelerating:+,} HCPs\n")
