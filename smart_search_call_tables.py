"""
Smart search for call-related, MLR, compliance, and marketing content tables
Searches for specific naming patterns instead of all 900+ tables
"""

import os
import pandas as pd
from sqlalchemy import create_engine, text
from urllib.parse import quote_plus
from dotenv import load_dotenv

load_dotenv()

try:
    print("="*100)
    print("SMART SEARCH: Call, Script, MLR, Content & Marketing Tables")
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
    
    print(f"\nConnected to: {server}/{database}")
    print("\nSearching for tables with these patterns:")
    
    # Smart search patterns - focus on call/script/content related tables
    patterns = [
        '%call%',           # Call activity, call plans, call details
        '%script%',         # Call scripts, script templates
        '%mlr%',            # MLR approvals, MLR content
        '%compli%',         # Compliance, compliant content
        '%approv%',         # Approved content, approvals
        '%content%',        # Content library, content pieces
        '%message%',        # Messaging, message templates
        '%claim%',          # Clinical claims, product claims
        '%market%',         # Marketing materials, marketing content
        '%promo%',          # Promotional content, promo materials
        '%material%',       # Sales materials, marketing materials
        '%template%',       # Templates for calls/scripts
        '%detail%',         # Detail aids, detailing content
        '%talk%',           # Talking points, talk tracks
        '%object%',         # Objection handlers
        '%disclaim%',       # Disclaimers, disclaimer text
        '%safety%',         # Safety information
        '%clinical%',       # Clinical data, clinical content
        '%campaign%',       # Marketing campaigns
        '%creative%',       # Creative assets
        '%asset%',          # Marketing assets
        '%rep%',            # Rep materials, rep content
        '%sales%',          # Sales materials, sales content
        '%activity%',       # Call activity, rep activity
        '%interaction%',    # HCP interactions
    ]
    
    for i, pattern in enumerate(patterns, 1):
        print(f"   {i}. {pattern}")
    
    print("\n" + "="*100)
    print("SEARCH RESULTS")
    print("="*100)
    
    all_matches = []
    
    for pattern in patterns:
        query = text(f"""
            SELECT DISTINCT TABLE_SCHEMA, TABLE_NAME 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_TYPE = 'BASE TABLE'
            AND (TABLE_NAME LIKE :pattern OR TABLE_SCHEMA LIKE :pattern)
            ORDER BY TABLE_SCHEMA, TABLE_NAME
        """)
        
        result_df = pd.read_sql(query, conn, params={'pattern': pattern})
        
        if len(result_df) > 0:
            for _, row in result_df.iterrows():
                table_info = (row['TABLE_SCHEMA'], row['TABLE_NAME'], pattern)
                if table_info not in all_matches:
                    all_matches.append(table_info)
    
    if all_matches:
        print(f"\nFound {len(all_matches)} matching tables:\n")
        
        # Group by pattern for better readability
        pattern_groups = {}
        for schema, table, pattern in all_matches:
            if pattern not in pattern_groups:
                pattern_groups[pattern] = []
            pattern_groups[pattern].append((schema, table))
        
        for pattern, tables in pattern_groups.items():
            print(f"\nPattern '{pattern}' ({len(tables)} tables):")
            for schema, table in tables:
                full_name = f"[{schema}].[{table}]"
                print(f"   {full_name}")
                
                # Get row count and columns for interesting tables
                try:
                    count_query = text(f"SELECT COUNT(*) as cnt FROM {full_name}")
                    count_df = pd.read_sql(count_query, conn)
                    row_count = count_df['cnt'].iloc[0]
                    
                    cols_query = text(f"""
                        SELECT COLUMN_NAME, DATA_TYPE 
                        FROM INFORMATION_SCHEMA.COLUMNS 
                        WHERE TABLE_SCHEMA = :schema AND TABLE_NAME = :table
                        ORDER BY ORDINAL_POSITION
                    """)
                    columns_df = pd.read_sql(cols_query, conn, params={'schema': schema, 'table': table})
                    
                    print(f"      Rows: {row_count:,}")
                    print(f"      Columns ({len(columns_df)}): {', '.join(columns_df['COLUMN_NAME'].head(10).tolist())}")
                    
                    if len(columns_df) > 10:
                        print(f"                  ... and {len(columns_df) - 10} more")
                    
                    # Show sample data for small tables (likely configuration/content tables)
                    if row_count <= 100:
                        sample_query = text(f"SELECT TOP 3 * FROM {full_name}")
                        sample_df = pd.read_sql(sample_query, conn)
                        if len(sample_df) > 0:
                            print(f"\n      Sample Data (first 3 rows):")
                            print(sample_df.to_string(index=False, max_colwidth=40).replace('\n', '\n      '))
                    
                    print()
                    
                except Exception as e:
                    print(f"      Error: {str(e)[:100]}")
                    print()
        
        print("\n" + "="*100)
        print(f"SUMMARY: Found {len(all_matches)} tables matching call/script/content patterns")
        print("="*100)
        
    else:
        print("\nNo tables found matching call/script/content patterns")
        print("\nThis suggests the database contains operational data (prescriptions, HCPs, samples)")
        print("but NOT MLR-approved marketing content or call scripts.")
        print("\nRecommendation: Use manual JSON editing or spreadsheet import for MLR content")
    
    conn.close()

except Exception as e:
    print(f"\nError: {str(e)}")
    import traceback
    traceback.print_exc()
