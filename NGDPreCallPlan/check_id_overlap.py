import pandas as pd

# Load Phase 4B output
features = pd.read_csv('ibsa-poc-eda/outputs/features/IBSA_ProductFeatures_20251029_0746.csv')
print(f'Phase 4B unique IDs: {features["PrescriberId"].nunique():,}')
print(f'Phase 4B ID range: {features["PrescriberId"].min()} - {features["PrescriberId"].max()}')
print(f'Phase 4B sample IDs: {features["PrescriberId"].head().tolist()}')

# Load NGD table
ngd = pd.read_csv('ibsa-poc-eda/data/Reporting_BI_NGD.csv')
print(f'\nNGD unique IDs: {ngd["PrescriberId"].nunique():,}')
print(f'NGD ID range: {ngd["PrescriberId"].min()} - {ngd["PrescriberId"].max()}')
print(f'NGD sample IDs: {ngd["PrescriberId"].head().tolist()}')

# Check overlap
overlap = set(features['PrescriberId']) & set(ngd['PrescriberId'])
print(f'\n✓ Overlapping IDs: {len(overlap):,}')
print(f'✓ Overlap rate: {len(overlap)/len(features)*100:.1f}% of Phase 4B IDs')
