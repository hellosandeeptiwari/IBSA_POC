#!/usr/bin/env python3
"""
Examine dbo.Call table structure and sample data
"""

import pyodbc
import pandas as pd

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
print("EXAMINING dbo.Call TABLE")
print("=" * 80)

conn = connect_to_db()

# Get all columns
print("\n📋 ALL COLUMNS IN dbo.Call:")
print("-" * 80)
columns_query = """
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Call'
ORDER BY ORDINAL_POSITION
"""
columns = pd.read_sql(columns_query, conn)
print(columns.to_string(index=False))

# Get row count
print("\n📊 ROW COUNT:")
print("-" * 80)
count_query = "SELECT COUNT(*) as total_calls FROM dbo.Call"
count = pd.read_sql(count_query, conn)
print(f"Total calls: {count['total_calls'].iloc[0]:,}")

# Get sample with notes
print("\n💬 SAMPLE CALLS WITH NOTES (showing key columns):")
print("-" * 80)
sample_query = """
SELECT TOP 10
    Id,
    VeevaId,
    AccountId,
    UserId,
    CallDate,
    CallComments,
    NextCallNotes,
    CallType,
    Status
FROM dbo.Call
WHERE CallComments IS NOT NULL OR NextCallNotes IS NOT NULL
ORDER BY CallDate DESC
"""
sample = pd.read_sql(sample_query, conn)
pd.set_option('display.max_colwidth', 50)
print(sample.to_string(index=False))

# Statistics on notes
print("\n📈 NOTES STATISTICS:")
print("-" * 80)
stats_query = """
SELECT 
    COUNT(*) as total_calls,
    SUM(CASE WHEN CallComments IS NOT NULL THEN 1 ELSE 0 END) as calls_with_comments,
    SUM(CASE WHEN NextCallNotes IS NOT NULL THEN 1 ELSE 0 END) as calls_with_next_notes,
    SUM(CASE WHEN CallComments IS NOT NULL OR NextCallNotes IS NOT NULL THEN 1 ELSE 0 END) as calls_with_any_notes
FROM dbo.Call
"""
stats = pd.read_sql(stats_query, conn)
print(stats.to_string(index=False))

# Check if AccountId maps to NPI
print("\n🔍 CHECKING ACCOUNT/NPI MAPPING:")
print("-" * 80)
npi_check_query = """
SELECT TOP 5
    c.Id,
    c.VeevaId,
    c.AccountId,
    c.CallComments,
    c.CallDate
FROM dbo.Call c
WHERE c.CallComments IS NOT NULL
ORDER BY c.CallDate DESC
"""
npi_sample = pd.read_sql(npi_check_query, conn)
print(npi_sample.to_string(index=False))

conn.close()

print("\n" + "=" * 80)
print("✅ ANALYSIS COMPLETE")
print("=" * 80)
print("\n📝 SUMMARY:")
print("   Table: dbo.Call")
print("   Note Columns: CallComments, NextCallNotes")
print("   These contain the actual call notes from sales reps")
