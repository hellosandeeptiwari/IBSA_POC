#!/usr/bin/env python3
"""
Check Azure SQL Database for MLR/Compliance/Marketing Content Tables
"""
from sqlalchemy import create_engine
from urllib.parse import quote_plus
import pandas as pd
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# Database connection using SQLAlchemy (same as other IBSA scripts)
driver = 'ODBC Driver 18 for SQL Server'  # Use available driver on system
server = os.getenv('AZURE_SQL_HOST')
database = os.getenv('AZURE_SQL_DATABASE')
username = os.getenv('AZURE_SQL_USER')
password = os.getenv('AZURE_SQL_PASSWORD')

odbc_str = (
    f"DRIVER={{{driver}}};"
    f"SERVER={server};"
    f"DATABASE={database};"
    f"UID={username};"
    f"PWD={password};"
    "Encrypt=yes;"
    "TrustServerCertificate=no;"
)

connect_args = quote_plus(odbc_str)
engine_url = f"mssql+pyodbc:///?odbc_connect={connect_args}"

print("="*100)
print("SEARCHING DATABASE FOR MLR/COMPLIANCE/MARKETING CONTENT")
print("="*100)

try:
    engine = create_engine(engine_url, fast_executemany=True)
    conn = engine.connect()
    
    # Get all tables
    print("\nStep 1: Getting all table names...")
    query = """
        SELECT TABLE_SCHEMA, TABLE_NAME 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_TYPE = 'BASE TABLE'
        ORDER BY TABLE_SCHEMA, TABLE_NAME
    """
    
    all_tables_df = pd.read_sql(query, conn)
    all_tables = list(zip(all_tables_df['TABLE_SCHEMA'], all_tables_df['TABLE_NAME']))
    print(f"   Found {len(all_tables)} total tables")
    
    # Search for tables that might contain MLR/compliance/marketing content
    keywords = [
        'mlr', 'compliance', 'approval', 'content', 'message', 'messaging',
        'claim', 'clinical', 'marketing', 'promo', 'promotional', 'material',
        'safety', 'label', 'approved', 'disclaimer', 'objection', 'script',
        'call', 'rep', 'sales', 'aid', 'campaign', 'creative', 'asset'
    ]
    
    print(f"\nStep 2: Searching for tables containing keywords: {', '.join(keywords[:5])}...")
    matching_tables = []
    
    for schema, table in all_tables:
        table_lower = table.lower()
        schema_lower = schema.lower()
        
        if any(keyword in table_lower or keyword in schema_lower for keyword in keywords):
            matching_tables.append((schema, table))
    
    if matching_tables:
        print(f"\nFound {len(matching_tables)} potentially relevant tables:")
        print("="*100)
        
        for schema, table in matching_tables:
            full_name = f"{schema}.{table}"
            print(f"\nTable: {full_name}")
            
            # Get row count
            try:
                count_df = pd.read_sql(f"SELECT COUNT(*) as cnt FROM {full_name}", conn)
                row_count = count_df['cnt'].iloc[0]
                print(f"   Rows: {row_count:,}")
            except:
                print(f"   Rows: Unable to count")
            
            # Get column names
            try:
                cols_query = f"""
                    SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH 
                    FROM INFORMATION_SCHEMA.COLUMNS 
                    WHERE TABLE_SCHEMA = '{schema}' AND TABLE_NAME = '{table}'
                    ORDER BY ORDINAL_POSITION
                """
                
                columns_df = pd.read_sql(cols_query, conn)
                print(f"   Columns ({len(columns_df)}):")
                for _, row in columns_df.iterrows():
                    col_name = row['COLUMN_NAME']
                    data_type = row['DATA_TYPE']
                    max_len = row['CHARACTER_MAXIMUM_LENGTH']
                    type_str = f"{data_type}({max_len})" if pd.notna(max_len) else data_type
                    print(f"      - {col_name} ({type_str})")
                
                # Show sample data (first 3 rows)
                sample_df = pd.read_sql(f"SELECT TOP 3 * FROM {full_name}", conn)
                
                if len(sample_df) > 0:
                    print(f"\n   Sample Data (first 3 rows):")
                    print(sample_df.to_string(index=False, max_colwidth=50))
                
            except Exception as e:
                print(f"   Error getting details: {str(e)}")
            
            print("-" * 100)
    
    else:
        print("\nNo tables found with MLR/compliance/marketing keywords")
        print("\nShowing all tables for manual review:")
        print("="*100)
        
        for schema, table in all_tables[:50]:  # Show first 50
            print(f"   - {schema}.{table}")
        
        if len(all_tables) > 50:
            print(f"\n   ... and {len(all_tables) - 50} more tables")
    
    conn.close()
    
    print("\n" + "="*100)
    print("Database search complete")
    print("="*100)

except Exception as e:
    print(f"\nError connecting to database: {str(e)}")
    print("\nConnection string (masked):")
    print(f"   Server: {os.getenv('AZURE_SQL_HOST')}")
    print(f"   Database: {os.getenv('AZURE_SQL_DATABASE')}")
    print(f"   User: {os.getenv('AZURE_SQL_USER')}")
