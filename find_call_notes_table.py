#!/usr/bin/env python3
"""
Find Call Notes Table in IBSA Database
Search for tables containing call history, notes, or activity data
"""

import pyodbc
import pandas as pd
from typing import List, Dict

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

def search_tables_for_keywords(conn, keywords: List[str]) -> pd.DataFrame:
    """Search for tables containing specific keywords"""
    query = """
    SELECT 
        t.TABLE_SCHEMA,
        t.TABLE_NAME,
        t.TABLE_TYPE
    FROM INFORMATION_SCHEMA.TABLES t
    WHERE t.TABLE_TYPE = 'BASE TABLE'
    ORDER BY t.TABLE_SCHEMA, t.TABLE_NAME
    """
    
    all_tables = pd.read_sql(query, conn)
    
    # Filter tables by keywords
    pattern = '|'.join(keywords)
    matching_tables = all_tables[
        all_tables['TABLE_NAME'].str.contains(pattern, case=False, na=False)
    ]
    
    return matching_tables

def get_table_columns(conn, schema: str, table: str) -> pd.DataFrame:
    """Get all columns for a specific table"""
    query = f"""
    SELECT 
        COLUMN_NAME,
        DATA_TYPE,
        CHARACTER_MAXIMUM_LENGTH,
        IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = '{schema}'
      AND TABLE_NAME = '{table}'
    ORDER BY ORDINAL_POSITION
    """
    return pd.read_sql(query, conn)

def sample_table_data(conn, schema: str, table: str, limit: int = 5) -> pd.DataFrame:
    """Get sample data from table"""
    try:
        query = f"SELECT TOP {limit} * FROM [{schema}].[{table}]"
        return pd.read_sql(query, conn)
    except Exception as e:
        return pd.DataFrame({'error': [str(e)]})

def search_for_call_notes():
    """Main function to search for call notes tables"""
    print("=" * 80)
    print("SEARCHING FOR CALL NOTES TABLES IN IBSA DATABASE")
    print("=" * 80)
    
    # Connect to database
    print(f"\n📡 Connecting to: {SERVER}/{DATABASE}")
    conn = connect_to_db()
    print("✅ Connected successfully!")
    
    # Search keywords
    keywords = ['call', 'note', 'activity', 'detail', 'contact', 'interaction', 'visit', 'history']
    
    print(f"\n🔍 Searching for tables with keywords: {', '.join(keywords)}")
    matching_tables = search_tables_for_keywords(conn, keywords)
    
    print(f"\n📊 Found {len(matching_tables)} matching tables:")
    print("-" * 80)
    for idx, row in matching_tables.iterrows():
        print(f"{row['TABLE_SCHEMA']}.{row['TABLE_NAME']}")
    
    # Analyze each table
    print("\n" + "=" * 80)
    print("ANALYZING EACH TABLE")
    print("=" * 80)
    
    results = []
    
    for idx, row in matching_tables.iterrows():
        schema = row['TABLE_SCHEMA']
        table = row['TABLE_NAME']
        
        print(f"\n{'='*80}")
        print(f"TABLE: {schema}.{table}")
        print(f"{'='*80}")
        
        # Get columns
        columns = get_table_columns(conn, schema, table)
        print(f"\n📋 Columns ({len(columns)}):")
        for _, col in columns.iterrows():
            print(f"  - {col['COLUMN_NAME']}: {col['DATA_TYPE']}")
        
        # Check for note/comment columns
        note_columns = columns[
            columns['COLUMN_NAME'].str.contains('note|comment|text|description|memo', case=False, na=False)
        ]
        
        if not note_columns.empty:
            print(f"\n💬 FOUND NOTE COLUMNS:")
            for _, col in note_columns.iterrows():
                print(f"  ✅ {col['COLUMN_NAME']}: {col['DATA_TYPE']}")
        
        # Get sample data
        print(f"\n📝 Sample Data (5 rows):")
        sample = sample_table_data(conn, schema, table, limit=5)
        if 'error' in sample.columns:
            print(f"  ❌ Error: {sample['error'].iloc[0]}")
        else:
            print(sample.to_string())
        
        # Store results
        results.append({
            'schema': schema,
            'table': table,
            'column_count': len(columns),
            'has_note_columns': not note_columns.empty,
            'note_columns': list(note_columns['COLUMN_NAME']) if not note_columns.empty else [],
            'all_columns': list(columns['COLUMN_NAME'])
        })
    
    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY - TABLES WITH NOTE/COMMENT COLUMNS")
    print("=" * 80)
    
    tables_with_notes = [r for r in results if r['has_note_columns']]
    
    if tables_with_notes:
        for result in tables_with_notes:
            print(f"\n✅ {result['schema']}.{result['table']}")
            print(f"   Note Columns: {', '.join(result['note_columns'])}")
    else:
        print("\n❌ No tables found with note/comment columns")
    
    # Close connection
    conn.close()
    print("\n" + "=" * 80)
    print("✅ SEARCH COMPLETE")
    print("=" * 80)
    
    return results

if __name__ == "__main__":
    try:
        results = search_for_call_notes()
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
