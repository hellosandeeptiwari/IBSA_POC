#!/usr/bin/env python3
"""
Examine NextCallObjective column in dbo.Call table
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
print("EXAMINING NextCallObjective COLUMN IN dbo.Call")
print("=" * 80)

conn = connect_to_db()

# Get column info
print("\n📋 COLUMN DETAILS:")
print("-" * 80)
col_query = """
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Call'
  AND COLUMN_NAME = 'NextCallObjective'
"""
col_info = pd.read_sql(col_query, conn)
print(col_info.to_string(index=False))

# Get statistics
print("\n📊 DATA STATISTICS:")
print("-" * 80)
stats_query = """
SELECT 
    COUNT(*) as total_calls,
    SUM(CASE WHEN NextCallObjective IS NOT NULL THEN 1 ELSE 0 END) as with_next_objective,
    SUM(CASE WHEN NextCallObjective IS NULL THEN 1 ELSE 0 END) as null_next_objective,
    CAST(SUM(CASE WHEN NextCallObjective IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as pct_with_objective
FROM dbo.Call
"""
stats = pd.read_sql(stats_query, conn)
print(stats.to_string(index=False))

# Get sample values
print("\n💬 SAMPLE VALUES (Recent calls with NextCallObjective):")
print("-" * 80)
sample_query = """
SELECT TOP 20
    Id,
    AccountId,
    CallDate,
    NextCallObjective,
    NextCallNotes,
    CallType,
    Status
FROM dbo.Call
WHERE NextCallObjective IS NOT NULL
ORDER BY CallDate DESC
"""
sample = pd.read_sql(sample_query, conn)
pd.set_option('display.max_colwidth', 60)
if not sample.empty:
    print(sample.to_string(index=False))
else:
    print("No rows with NextCallObjective found")

# Get unique values
print("\n🔍 UNIQUE VALUES IN NextCallObjective:")
print("-" * 80)
unique_query = """
SELECT 
    NextCallObjective,
    COUNT(*) as count
FROM dbo.Call
WHERE NextCallObjective IS NOT NULL
GROUP BY NextCallObjective
ORDER BY COUNT(*) DESC
"""
unique = pd.read_sql(unique_query, conn)
if not unique.empty:
    print(unique.to_string(index=False))
else:
    print("No non-null values found")

conn.close()

print("\n" + "=" * 80)
print("✅ ANALYSIS COMPLETE")
print("=" * 80)
