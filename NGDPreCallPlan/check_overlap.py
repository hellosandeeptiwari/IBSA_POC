import pandas as pd

print("Loading files...")
calls = pd.read_csv('ibsa_precall_ui/public/data/call_history.csv')
ui = pd.read_csv('ibsa_precall_ui/public/data/IBSA_ModelReady_Enhanced_WithPredictions.csv')

# Convert both to integers for comparison
calls['npi_int'] = pd.to_numeric(calls['npi'], errors='coerce').fillna(0).astype(int)
ui['npi_int'] = ui['NPI'].fillna(0).astype(int)

# Find overlap
calls_unique = set(calls['npi_int'].unique())
ui_unique = set(ui['npi_int'].unique())
overlap = calls_unique.intersection(ui_unique)

print(f"\n=== OVERLAP ANALYSIS ===")
print(f"Unique NPIs in call history: {len(calls_unique):,}")
print(f"Unique NPIs in UI data: {len(ui_unique):,}")
print(f"NPIs in BOTH: {len(overlap):,}")

if len(overlap) > 0:
    # Get top HCPs with most calls from the overlap
    overlap_calls = calls[calls['npi_int'].isin(overlap)]
    call_counts = overlap_calls.groupby('npi_int').size().reset_index(name='calls')
    call_counts = call_counts.sort_values('calls', ascending=False)
    
    print(f"\n=== TOP 10 HCPs WITH CALL HISTORY (in UI) ===")
    for idx, row in call_counts.head(10).iterrows():
        npi = row['npi_int']
        calls_count = row['calls']
        name = ui[ui['npi_int'] == npi]['PrescriberName'].iloc[0]
        print(f"  NPI {npi}: {name} ({calls_count} calls)")
else:
    print("\nNO OVERLAP - Call history and UI use completely different NPIs!")
