import pandas as pd

print("Loading files...")
calls = pd.read_csv('ibsa_precall_ui/public/data/call_history.csv')
ui = pd.read_csv('ibsa_precall_ui/public/data/IBSA_ModelReady_Enhanced_WithPredictions.csv', nrows=10)

print("\n=== CALL HISTORY NPIs (first 10) ===")
print("Type:", calls['npi'].dtype)
print("Sample values:")
print(calls['npi'].head(10).tolist())

print("\n=== UI DATA NPIs (first 10) ===")
print("Type:", ui['NPI'].dtype)
print("Sample values:")
print(ui['NPI'].head(10).tolist())

print("\n=== Checking if NPI column exists in UI ===")
print("Columns in UI CSV:", ui.columns.tolist())

# Check if maybe it's using PrescriberId instead
if 'PrescriberId' in ui.columns:
    print("\nFound PrescriberId column!")
    print("Sample PrescriberId values:")
    print(ui['PrescriberId'].head(10).tolist())
