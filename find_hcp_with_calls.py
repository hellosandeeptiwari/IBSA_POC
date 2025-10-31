import pandas as pd

print("=" * 80)
print("FINDING HCPs WITH CALL HISTORY THAT ARE IN UI")
print("=" * 80)

# Load both datasets
print("\n📂 Loading call history...")
calls_df = pd.read_csv(r'ibsa_precall_ui\public\data\call_history.csv', dtype={'npi': str})
print(f"   {len(calls_df)} calls for {calls_df['npi'].nunique()} unique HCPs")

print("\n📂 Loading HCP predictions...")
hcp_df = pd.read_csv(r'ibsa_precall_ui\public\data\IBSA_ModelReady_Enhanced_WithPredictions.csv', dtype={'NPI': str})
# Clean NPI format
hcp_df['NPI'] = hcp_df['NPI'].astype(str).str.replace('.0', '', regex=False)
print(f"   {len(hcp_df)} HCPs in UI")

# Find intersection
calls_npis = set(calls_df['npi'].unique())
hcp_npis = set(hcp_df['NPI'].unique())
common_npis = calls_npis.intersection(hcp_npis)

print(f"\n✅ INTERSECTION: {len(common_npis)} HCPs with both call history AND in UI")

if len(common_npis) > 0:
    # Get first 10 NPIs with calls that are in UI
    common_list = list(common_npis)[:10]
    
    print(f"\n📋 First 10 HCPs with call history (searchable in UI):")
    print("=" * 80)
    
    for npi in common_list:
        hcp_row = hcp_df[hcp_df['NPI'] == npi].iloc[0]
        call_count = len(calls_df[calls_df['npi'] == npi])
        name = hcp_row.get('PrescriberName', 'N/A')
        specialty = hcp_row.get('Specialty', 'N/A')
        
        print(f"   NPI: {npi}")
        print(f"      Name: {name}")
        print(f"      Specialty: {specialty}")
        print(f"      Calls: {call_count}")
        print()
else:
    print("\n❌ NO OVERLAP! Call history NPIs don't match UI NPIs!")
    print("\n🔍 Sample call history NPIs:")
    print(list(calls_npis)[:5])
    print("\n🔍 Sample UI NPIs:")
    print(list(hcp_npis)[:5])

print("=" * 80)
