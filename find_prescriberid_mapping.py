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

print("="*80)
print("FINDING PRESCRIBERID MAPPING")
print("="*80)

conn = connect_to_db()

# Check Account table columns
print("\n1. Columns in dbo.Account:")
cols_query = """
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Account'
ORDER BY ORDINAL_POSITION
"""
cols = pd.read_sql(cols_query, conn)
print(cols.to_string(index=False))

# Check Reporting_BI_AccountExtract (has both PrescriberId and NPI per earlier output)
print("\n2. Columns in dbo.Reporting_BI_AccountExtract:")
reporting_cols_query = """
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Reporting_BI_AccountExtract'
ORDER BY ORDINAL_POSITION
"""
reporting_cols = pd.read_sql(reporting_cols_query, conn)
print(reporting_cols.to_string(index=False))

# Sample data from Reporting_BI_AccountExtract
print("\n3. Sample data from Reporting_BI_AccountExtract:")
sample_query = """
SELECT TOP 10 VeevaId, PrescriberId, NPI
FROM dbo.Reporting_BI_AccountExtract
WHERE VeevaId IS NOT NULL AND PrescriberId IS NOT NULL
"""
sample = pd.read_sql(sample_query, conn)
print(sample.to_string(index=False))

conn.close()
print("\n"+"="*80)
