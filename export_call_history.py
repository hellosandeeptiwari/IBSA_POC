#!/usr/bin/env python3
"""
Extract Call History Data from IBSA Database
Export to CSV for UI integration
"""

import pyodbc
import pandas as pd
from pathlib import Path

# Database credentials
SERVER = 'odsproduction.database.windows.net'
DATABASE = 'DWHPRODIBSA'
USERNAME = 'odsjobsuser'
PASSWORD = 'DwHIBSAOD$J0bs!1'

def connect_to_db():
    """Establish database connection"""
    connection_string = (
        f"DRIVER={{ODBC Driver 18 for SQL Server}};"
        f"SERVER={SERVER};"
        f"DATABASE={DATABASE};"
        f"UID={USERNAME};"
        f"PWD={PASSWORD};"
        f"Encrypt=yes;"
        f"TrustServerCertificate=yes;"
    )
    return pyodbc.connect(connection_string)

print("=" * 80)
print("EXTRACTING CALL HISTORY DATA")
print("=" * 80)

conn = connect_to_db()

# First, check if there's an Account table to map AccountId to NPI
print("\n🔍 Checking for Account/NPI mapping...")
account_check_query = """
SELECT TOP 5 
    TABLE_SCHEMA,
    TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE '%Account%' 
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME
"""
account_tables = pd.read_sql(account_check_query, conn)
print("Found Account tables:")
print(account_tables.to_string(index=False))

# Try to get NPI mapping from dbo.Account or similar
print("\n🔍 Looking for NPI column in Account tables...")
npi_column_query = """
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE '%Account%'
  AND COLUMN_NAME LIKE '%NPI%'
ORDER BY TABLE_SCHEMA, TABLE_NAME
"""
npi_columns = pd.read_sql(npi_column_query, conn)
if not npi_columns.empty:
    print("Found NPI columns:")
    print(npi_columns.to_string(index=False))
else:
    print("No NPI columns found in Account tables")

# Extract call history with best available data
print("\n📊 Extracting call history data (2025 only)...")
print("-" * 80)

# Query to get calls - we'll try to join with Account if possible
# Using chunking for large result set
call_history_query = """
SELECT 
    c.Id as call_id,
    c.VeevaId as veeva_call_id,
    c.AccountId as account_id,
    c.CallDate as call_date,
    c.CallType as call_type,
    c.Status as status,
    c.UserId as user_id,
    c.NextCallObjective as next_call_objective,
    c.CallComments as call_comments,
    c.NextCallNotes as next_call_notes,
    c.Duration as duration,
    c.DetailedProducts as products,
    c.IsSampledCall as is_sampled,
    c.Location as location
FROM dbo.Call c
WHERE c.CallDate >= '2025-01-01'  -- 2025 only
  AND c.CallDate < '2026-01-01'
  AND c.Status = 'Submitted_vod'  -- Only submitted calls
  AND c.CallDate IS NOT NULL
ORDER BY c.CallDate DESC
"""

print("Executing query with chunking (50,000 rows at a time)...")
chunk_size = 50000
calls_chunks = []
for chunk in pd.read_sql(call_history_query, conn, chunksize=chunk_size):
    calls_chunks.append(chunk)
    print(f"  Loaded chunk: {len(chunk):,} rows")

calls_df = pd.concat(calls_chunks, ignore_index=True)
print(f"✅ Retrieved {len(calls_df):,} calls")

# Try to get user names
print("\n👤 Looking for user/rep names...")
user_query = """
SELECT TOP 5
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE '%User%'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME
"""
user_tables = pd.read_sql(user_query, conn)
print("Found User tables:")
print(user_tables.to_string(index=False))

# Check web.SOpsUser table
print("\n👤 Getting rep names from web.SOpsUser...")
rep_query = """
SELECT 
    ExternalId1 as user_id,
    DisplayName as rep_name,
    Email
FROM web.SOpsUser
"""
reps_df = pd.read_sql(rep_query, conn)
print(f"✅ Retrieved {len(reps_df):,} reps")

# Try to get Account/NPI mapping from Reporting tables
print("\n🔍 Looking for NPI in Reporting tables...")
reporting_npi_query = """
SELECT TOP 5
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME LIKE 'Reporting%'
  AND (COLUMN_NAME LIKE '%NPI%' OR COLUMN_NAME LIKE '%Prescriber%')
ORDER BY TABLE_NAME
"""
reporting_cols = pd.read_sql(reporting_npi_query, conn)
if not reporting_cols.empty:
    print("Found NPI/Prescriber columns in Reporting tables:")
    print(reporting_cols.to_string(index=False))

# Get VeevaId-to-PrescriberId mapping (this matches UI format!)
print("\n🔍 Getting VeevaId-to-PrescriberId mapping from Reporting_BI_AccountExtract...")
prescriber_mapping_query = """
SELECT DISTINCT
    r.VeevaId as AccountId,
    r.PrescriberId as prescriber_id
FROM dbo.Reporting_BI_AccountExtract r
WHERE r.VeevaId IS NOT NULL
  AND r.PrescriberId IS NOT NULL
"""
prescriber_mapping_raw = pd.read_sql(prescriber_mapping_query, conn)
print(f"✅ Retrieved {len(prescriber_mapping_raw):,} VeevaId-PrescriberId mappings (before dedup)")

# Deduplicate - keep first PrescriberId per VeevaId
prescriber_mapping = prescriber_mapping_raw.drop_duplicates(subset=['AccountId'], keep='first')
# Clean PrescriberId format to match UI (remove .0)
prescriber_mapping['prescriber_id'] = prescriber_mapping['prescriber_id'].astype(str).str.replace('.0', '', regex=False)
print(f"✅ After dedup: {len(prescriber_mapping):,} unique VeevaId-PrescriberId mappings")

conn.close()

# Merge data
print("\n🔗 Merging data...")
print("-" * 80)

# Merge with PrescriberId mapping (matches UI format!)
calls_df = calls_df.merge(prescriber_mapping, left_on='account_id', right_on='AccountId', how='left')
calls_with_prescriber = calls_df[calls_df['prescriber_id'].notna()]
print(f"✅ Matched {len(calls_with_prescriber):,} calls to PrescriberIds ({len(calls_with_prescriber)/len(calls_df)*100:.1f}%)")

# Deduplicate reps too
reps_df = reps_df.drop_duplicates(subset=['user_id'], keep='first')

# Merge with rep names
calls_with_prescriber = calls_with_prescriber.merge(reps_df, on='user_id', how='left')
calls_with_rep = calls_with_prescriber[calls_with_prescriber['rep_name'].notna()]
print(f"✅ Matched {len(calls_with_rep):,} calls to rep names ({len(calls_with_rep)/len(calls_with_prescriber)*100:.1f}%)")

# Prepare final CSV - LIMIT TO MOST RECENT 10 CALLS PER HCP
print("\n📝 Preparing final CSV (limiting to most recent 10 calls per HCP)...")
print("-" * 80)

final_df = calls_with_rep[[
    'prescriber_id',
    'call_date',
    'call_type',
    'rep_name',
    'next_call_objective',
    'status',
    'products',
    'is_sampled',
    'duration',
    'location'
]].copy()

# Rename prescriber_id to npi for consistency with UI expectations
final_df.rename(columns={'prescriber_id': 'npi'}, inplace=True)

# Clean up data
final_df['call_date'] = pd.to_datetime(final_df['call_date']).dt.strftime('%Y-%m-%d')
final_df['products'] = final_df['products'].fillna('')
final_df['next_call_objective'] = final_df['next_call_objective'].fillna('')
final_df['is_sampled'] = final_df['is_sampled'].fillna(False)
final_df['duration'] = final_df['duration'].fillna(0)
final_df['location'] = final_df['location'].fillna('')

# Map call_type to simpler values
type_mapping = {
    'Detail Only': 'Detail',
    'Detail with Sample': 'Detail',
    'Sample Only': 'Sample Drop',
    'Sample Drop Off': 'Sample Drop',
    'Remote Detail Only': 'Virtual',
    'Remote Detail with Sample': 'Virtual',
}
final_df['call_type'] = final_df['call_type'].replace(type_mapping)

# Sort by date descending and keep only most recent 10 calls per HCP
final_df = final_df.sort_values('call_date', ascending=False)
final_df = final_df.groupby('npi').head(10).reset_index(drop=True)

print(f"✅ Final dataset: {len(final_df):,} calls")
print(f"   Unique HCPs: {final_df['npi'].nunique():,}")
print(f"   Date range: {final_df['call_date'].min()} to {final_df['call_date'].max()}")
print(f"   Call types: {final_df['call_type'].value_counts().to_dict()}")

# Show sample
print("\n📊 Sample data:")
print(final_df.head(10).to_string(index=False))

# Save to CSV in the data source folder
output_path = Path('ibsa-poc-eda/data/call_history.csv')
output_path.parent.mkdir(parents=True, exist_ok=True)
final_df.to_csv(output_path, index=False)

print("\n" + "=" * 80)
print(f"✅ EXPORT COMPLETE")
print(f"   File: {output_path}")
print(f"   Rows: {len(final_df):,}")
print(f"   Size: {output_path.stat().st_size / 1024:.1f} KB")
print("=" * 80)
