import pandas as pd

print('Loading data...')
calls = pd.read_csv('ibsa_precall_ui/public/data/call_history.csv')
ui = pd.read_csv('ibsa_precall_ui/public/data/IBSA_ModelReady_Enhanced_WithPredictions.csv')

ui['NPI'] = ui['NPI'].fillna(0).astype(int)
calls_count = calls.groupby('npi').size().reset_index(name='calls')
overlap = calls_count[calls_count['npi'].isin(ui['NPI'])].sort_values('calls', ascending=False)

print(f'\nFound {len(overlap)} NPIs with call history that are in UI')
print('\nTop 10 NPIs to test:')
for idx, row in overlap.head(10).iterrows():
    npi_val = int(row['npi'])
    name = ui[ui['NPI'] == npi_val]['PrescriberName'].iloc[0] if len(ui[ui['NPI'] == npi_val]) > 0 else 'Unknown'
    print(f"  {npi_val}: {name} ({row['calls']} calls)")
