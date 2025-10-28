"""
Search for web-based content, APIs, or URLs in the database
"""

import os
import pandas as pd
from sqlalchemy import create_engine, text
from urllib.parse import quote_plus
from dotenv import load_dotenv

load_dotenv()

try:
    print("="*100)
    print("SEARCHING FOR WEB-BASED CONTENT, APIs, AND URLs")
    print("="*100)
    
    # Database credentials
    driver = 'ODBC Driver 18 for SQL Server'
    server = os.getenv('AZURE_SQL_HOST')
    database = os.getenv('AZURE_SQL_DATABASE')
    username = os.getenv('AZURE_SQL_USER')
    password = os.getenv('AZURE_SQL_PASSWORD')

    # Create SQLAlchemy engine
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
    engine = create_engine(engine_url, fast_executemany=True)
    conn = engine.connect()
    
    print(f"\nConnected to: {server}/{database}\n")
    
    # Search 1: Check [web] schema tables in detail
    print("="*100)
    print("1. EXPLORING [web] SCHEMA TABLES")
    print("="*100)
    
    web_tables = pd.read_sql(text("""
        SELECT TABLE_NAME 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA = 'web' AND TABLE_TYPE = 'BASE TABLE'
        ORDER BY TABLE_NAME
    """), conn)
    
    print(f"\nFound {len(web_tables)} tables in [web] schema:\n")
    
    for _, row in web_tables.iterrows():
        table_name = row['TABLE_NAME']
        if 'zzz' not in table_name.lower():  # Skip backup tables
            full_name = f"[web].[{table_name}]"
            
            try:
                # Get row count
                count_df = pd.read_sql(text(f"SELECT COUNT(*) as cnt FROM {full_name}"), conn)
                row_count = count_df['cnt'].iloc[0]
                
                # Get columns
                cols_df = pd.read_sql(text(f"""
                    SELECT COLUMN_NAME, DATA_TYPE 
                    FROM INFORMATION_SCHEMA.COLUMNS 
                    WHERE TABLE_SCHEMA = 'web' AND TABLE_NAME = :table
                    ORDER BY ORDINAL_POSITION
                """), conn, params={'table': table_name})
                
                print(f"{full_name}")
                print(f"   Rows: {row_count:,}")
                print(f"   Columns: {', '.join(cols_df['COLUMN_NAME'].tolist())}")
                
                # Show sample data for small tables
                if row_count > 0 and row_count <= 100:
                    sample_df = pd.read_sql(text(f"SELECT TOP 5 * FROM {full_name}"), conn)
                    print(f"\n   Sample Data (first 5 rows):")
                    print(sample_df.to_string(index=False, max_colwidth=60).replace('\n', '\n   '))
                
                print()
                
            except Exception as e:
                print(f"   Error: {str(e)[:100]}\n")
    
    # Search 2: Look for URL columns across all tables
    print("\n" + "="*100)
    print("2. SEARCHING FOR URL/API COLUMNS")
    print("="*100)
    
    url_columns = pd.read_sql(text("""
        SELECT DISTINCT 
            TABLE_SCHEMA, 
            TABLE_NAME, 
            COLUMN_NAME,
            DATA_TYPE
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE (
            COLUMN_NAME LIKE '%URL%' 
            OR COLUMN_NAME LIKE '%URI%'
            OR COLUMN_NAME LIKE '%API%'
            OR COLUMN_NAME LIKE '%ENDPOINT%'
            OR COLUMN_NAME LIKE '%LINK%'
            OR COLUMN_NAME LIKE '%PATH%'
            OR COLUMN_NAME LIKE '%WEB%'
        )
        AND TABLE_SCHEMA NOT LIKE 'zzz%'
        ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME
    """), conn)
    
    if len(url_columns) > 0:
        print(f"\nFound {len(url_columns)} tables with URL/API columns:\n")
        
        current_table = None
        for _, row in url_columns.iterrows():
            full_name = f"[{row['TABLE_SCHEMA']}].[{row['TABLE_NAME']}]"
            
            if full_name != current_table:
                current_table = full_name
                print(f"\n{full_name}")
                
                # Get sample URLs from this table
                try:
                    col_name = row['COLUMN_NAME']
                    query = text(f"""
                        SELECT DISTINCT TOP 10 [{col_name}]
                        FROM {full_name}
                        WHERE [{col_name}] IS NOT NULL
                    """)
                    urls_df = pd.read_sql(query, conn)
                    
                    if len(urls_df) > 0:
                        print(f"   Sample URLs from {col_name}:")
                        for url in urls_df[col_name]:
                            if url:
                                print(f"      - {str(url)[:150]}")
                    
                except Exception as e:
                    print(f"   Error reading URLs: {str(e)[:100]}")
            
            print(f"   Column: {row['COLUMN_NAME']} ({row['DATA_TYPE']})")
    
    # Search 3: Look for configuration or settings tables
    print("\n" + "="*100)
    print("3. SEARCHING FOR CONFIGURATION/SETTINGS TABLES")
    print("="*100)
    
    config_tables = pd.read_sql(text("""
        SELECT TABLE_SCHEMA, TABLE_NAME 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_TYPE = 'BASE TABLE'
        AND (
            TABLE_NAME LIKE '%config%'
            OR TABLE_NAME LIKE '%setting%'
            OR TABLE_NAME LIKE '%parameter%'
            OR TABLE_NAME LIKE '%integration%'
            OR TABLE_NAME LIKE '%service%'
            OR TABLE_NAME LIKE '%system%'
        )
        AND TABLE_NAME NOT LIKE 'zzz%'
        ORDER BY TABLE_SCHEMA, TABLE_NAME
    """), conn)
    
    if len(config_tables) > 0:
        print(f"\nFound {len(config_tables)} configuration/settings tables:\n")
        
        for _, row in config_tables.iterrows():
            full_name = f"[{row['TABLE_SCHEMA']}].[{row['TABLE_NAME']}]"
            
            try:
                count_df = pd.read_sql(text(f"SELECT COUNT(*) as cnt FROM {full_name}"), conn)
                row_count = count_df['cnt'].iloc[0]
                
                print(f"{full_name} ({row_count:,} rows)")
                
                if row_count > 0 and row_count <= 50:
                    sample_df = pd.read_sql(text(f"SELECT TOP 5 * FROM {full_name}"), conn)
                    print(sample_df.to_string(index=False, max_colwidth=60).replace('\n', '\n   '))
                    print()
                
            except Exception as e:
                print(f"   Error: {str(e)[:100]}\n")
    
    # Search 4: Check .env for any web service credentials
    print("\n" + "="*100)
    print("4. CHECKING .ENV FOR WEB SERVICE CREDENTIALS")
    print("="*100)
    
    env_file = '.env'
    if os.path.exists(env_file):
        with open(env_file, 'r') as f:
            lines = f.readlines()
            
        web_services = []
        for line in lines:
            line = line.strip()
            if line and not line.startswith('#'):
                # Look for web service indicators
                if any(keyword in line.upper() for keyword in [
                    'VEEVA', 'VAULT', 'SALESFORCE', 'SHAREPOINT', 
                    'API_KEY', 'API_URL', 'ENDPOINT', 'WEBHOOK',
                    'CRM', 'DAM', 'MLR', 'CONTENT'
                ]):
                    # Mask sensitive values
                    if '=' in line:
                        key, value = line.split('=', 1)
                        if any(sensitive in key.upper() for sensitive in ['KEY', 'SECRET', 'PASSWORD', 'TOKEN']):
                            web_services.append(f"{key}=***MASKED***")
                        else:
                            web_services.append(line)
        
        if web_services:
            print("\nFound potential web service credentials:\n")
            for service in web_services:
                print(f"   {service}")
        else:
            print("\nNo web service credentials found in .env file")
    
    conn.close()
    
    print("\n" + "="*100)
    print("SEARCH COMPLETE")
    print("="*100)

except Exception as e:
    print(f"\nError: {str(e)}")
    import traceback
    traceback.print_exc()
