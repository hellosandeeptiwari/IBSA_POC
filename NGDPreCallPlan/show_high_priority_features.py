import pandas as pd

# Load feature decisions
df = pd.read_csv('ibsa-poc-eda/outputs/eda-enterprise/feature_selection_decisions.csv')

print("="*100)
print("EDA STATISTICAL ANALYSIS: HIGH PRIORITY FEATURES")
print("="*100)

# Filter HIGH priority
high_priority = df[df['priority'] == 'HIGH']
print(f"\nTotal HIGH priority features: {len(high_priority)}")

print("\nAll HIGH priority features:")
for i, row in high_priority.iterrows():
    print(f"  {i+1}. {row['feature']}")
    print(f"      Value Score: {row['value_score']:.4f}")
    print(f"      Coverage: {row['coverage']:.2f}")
    print(f"      Reasons: {row['reasons']}")
    print()

# Group by feature type
print("\n" + "="*100)
print("HIGH PRIORITY FEATURES BY TYPE")
print("="*100)

high_features = high_priority['feature'].tolist()

# Categorize
categories = {
    'TRX/Sample Ratios': [f for f in high_features if 'Samples/' in f and 'TRX' in f],
    'NRX Features': [f for f in high_features if 'NRX' in f or 'nrx_sample' in f],
    'Call Activity': [f for f in high_features if 'Call' in f],
    'Sample Activity': [f for f in high_features if 'Sample' in f and 'Samples/' not in f],
    'Other': []
}

# Categorize
for feat in high_features:
    categorized = False
    for cat in ['TRX/Sample Ratios', 'NRX Features', 'Call Activity', 'Sample Activity']:
        if feat in categories[cat]:
            categorized = True
            break
    if not categorized:
        categories['Other'].append(feat)

for category, features in categories.items():
    if features:
        print(f"\n{category}: {len(features)} features")
        for feat in features:
            print(f"  - {feat}")

# Check what's available in NGD source
print("\n" + "="*100)
print("MAPPING TO NGD SOURCE DATA")
print("="*100)

ngd = pd.read_csv('ibsa-poc-eda/data/Reporting_BI_PrescriberOverview.csv', nrows=10)
print(f"\nNGD columns available: {len(ngd.columns)}")

# Check which HIGH priority features can be derived from NGD
print("\nFeature derivability:")
for feat in high_features[:20]:
    # These are engineered from Sample Summary table
    if 'nrx_sample' in feat or 'trx_sample' in feat:
        print(f"  {feat}")
        print(f"    → Requires Sample Summary table")
