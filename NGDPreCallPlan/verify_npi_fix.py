"""
Verify the NPI mapping fix worked correctly
"""
import pandas as pd

print("="*80)
print("VERIFYING NPI MAPPING FIX")
print("="*80)

# 1. Load the UI data
print("\n1. Loading UI data...")
df = pd.read_csv('ibsa_precall_ui/public/data/IBSA_ModelReady_Enhanced_WithPredictions.csv', 
                 usecols=['NPI', 'PrescriberName', 'Specialty', 'City', 'State'], 
                 dtype={'NPI': str}, 
                 low_memory=False)

print(f"   ✓ Total HCPs: {len(df):,}")

# 2. Check NPI format
print("\n2. Checking NPI format...")
print(f"   Sample NPIs: {df['NPI'].head(10).tolist()}")
npi_lengths = df['NPI'].str.len()
print(f"   NPI length range: {npi_lengths.min()}-{npi_lengths.max()} digits")
print(f"   7-digit NPIs: {(npi_lengths == 7).sum():,}")

# 3. Check names
print("\n3. Checking prescriber names...")
print(f"   Sample names:")
for i, row in df.head(10).iterrows():
    print(f"      {row['NPI']}: {row['PrescriberName']}")

has_hcp_prefix = df['PrescriberName'].str.startswith('HCP-', na=False)
print(f"\n   Real names: {(~has_hcp_prefix).sum():,}")
print(f"   Fallback names (HCP-*): {has_hcp_prefix.sum():,}")

# 4. Verify against profile data
print("\n4. Verifying against Prescriber Overview...")
overview = pd.read_csv('ibsa-poc-eda/data/Reporting_BI_PrescriberOverview.csv',
                       usecols=['PrescriberId', 'PrescriberName'],
                       dtype={'PrescriberId': str},
                       low_memory=False)

# Check first 5 NPIs
print("   Checking first 5 NPIs:")
for i in range(5):
    npi = df['NPI'].iloc[i]
    name_in_ui = df['PrescriberName'].iloc[i]
    
    match = overview[overview['PrescriberId'] == npi]
    if len(match) > 0:
        name_in_profile = match['PrescriberName'].iloc[0]
        status = "✓ MATCH" if name_in_ui == name_in_profile else "✗ MISMATCH"
        print(f"      {npi}: {status}")
        print(f"         UI: {name_in_ui}")
        print(f"         Profile: {name_in_profile}")
    else:
        print(f"      {npi}: ✗ NOT FOUND in profile")

# 5. Check data completeness
print("\n5. Checking data completeness...")
print(f"   NPIs with names: {df['PrescriberName'].notna().sum():,}")
print(f"   NPIs with specialty: {df['Specialty'].notna().sum():,}")
print(f"   NPIs with city: {df['City'].notna().sum():,}")
print(f"   NPIs with state: {df['State'].notna().sum():,}")

print("\n" + "="*80)
if has_hcp_prefix.sum() == 0 and (npi_lengths == 7).sum() == len(df):
    print("✅ VERIFICATION PASSED - All NPIs are real and all names are populated!")
else:
    print("⚠️  VERIFICATION WARNINGS:")
    if has_hcp_prefix.sum() > 0:
        print(f"   - {has_hcp_prefix.sum():,} HCPs still have fallback names")
    if (npi_lengths == 7).sum() != len(df):
        print(f"   - {(npi_lengths != 7).sum():,} NPIs are not 7 digits")
print("="*80)
