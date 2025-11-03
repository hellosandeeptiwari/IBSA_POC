"""Analyze payer types in our data"""
import pandas as pd

# Load payer plan data
df = pd.read_csv(
    'ibsa-poc-eda/data/Reporting_BI_PrescriberPaymentPlanSummary.csv',
    usecols=['PrescriberId', 'PaymentType', 'PayerName', 'TRX', 'TQTY']
)

print(f"\n{'='*80}")
print("PAYER TYPE ANALYSIS")
print(f"{'='*80}\n")

print(f"Total records: {len(df):,}\n")

print("="*80)
print("PAYMENT TYPE DISTRIBUTION")
print("="*80)
payment_type_dist = df['PaymentType'].value_counts()
for ptype, count in payment_type_dist.items():
    print(f"{ptype:<30} | {count:>10,} records ({count/len(df)*100:>5.1f}%)")

print("\n" + "="*80)
print("TRX VOLUME BY PAYMENT TYPE")
print("="*80)
trx_by_payment = df.groupby('PaymentType')['TRX'].sum().sort_values(ascending=False)
total_trx = df['TRX'].sum()
for ptype, trx in trx_by_payment.items():
    print(f"{ptype:<30} | {trx:>10,.0f} TRx ({trx/total_trx*100:>5.1f}%)")

print("\n" + "="*80)
print("UNIQUE HCPs BY PAYMENT TYPE")
print("="*80)
hcp_by_payment = df.groupby('PaymentType')['PrescriberId'].nunique().sort_values(ascending=False)
for ptype, hcp_count in hcp_by_payment.items():
    print(f"{ptype:<30} | {hcp_count:>10,} unique HCPs")

print("\n" + "="*80)
print("TOP 10 PAYER NAMES (By TRx Volume)")
print("="*80)
top_payers = df.groupby('PayerName')['TRX'].sum().sort_values(ascending=False).head(10)
for payer, trx in top_payers.items():
    payment_types = df[df['PayerName'] == payer]['PaymentType'].unique()
    payment_types_str = ', '.join([str(pt) for pt in payment_types if pd.notna(pt)])
    print(f"{payer:<50} | {trx:>8,.0f} TRx | Types: {payment_types_str}")

print("\n" + "="*80)
print("SAMPLE BREAKDOWN BY PAYMENT TYPE")
print("="*80)
sample_df = df.groupby('PaymentType').agg({
    'PrescriberId': 'nunique',
    'TRX': ['sum', 'mean'],
    'TQTY': 'sum'
}).round(1)
print(sample_df)

print(f"\n{'='*80}\n")
