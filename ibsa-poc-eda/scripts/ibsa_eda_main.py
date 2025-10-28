#!/usr/bin/env python3
"""
IBSA Pharmaceutical EDA - Main Script
=====================================
Comprehensive EDA pipeline for IBSA pharmaceutical data using PySpark
Replicates all functionality from IBSA_PoC_EDA notebook with better performance

Usage:
    python ibsa_eda_main.py
    
Requirements:
    - PySpark
    - pandas  
    - matplotlib
    - seaborn
"""

import sys
import os
from pathlib import Path

# Setup Java and Spark environment
def setup_spark_environment():
    """Setup Spark environment with proper Java configuration"""
    try:
        import findspark
        findspark.init()
    except Exception:
        pass
    
    # Set environment variables
    os.environ['SPARK_LOCAL_IP'] = '127.0.0.1'
    os.environ['PYSPARK_PYTHON'] = sys.executable
    os.environ['PYSPARK_DRIVER_PYTHON'] = sys.executable

# Initialize Spark environment
setup_spark_environment()

from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

# Add src to path for imports
sys.path.append(str(Path(__file__).parent.parent / "src"))

class IBSAEDAAnalysis:
    def __init__(self):
        """Initialize IBSA EDA Analysis with Spark configuration"""
        self.spark = None
        self.reporting_dataframes = {}
        self.table_relationships = {}
        
        # IBSA Reporting Tables to analyze
        self.IBSA_REPORTING_TABLES = {
            'call_activity': 'Call Activity',
            'call_attainment': 'Call Attainment',
            'territory_performance': 'Territory Performance', 
            'prescriber_profile': 'Prescriber Profile',
            'hcp_universe': 'HCP Universe',
            'trx_data': 'TRx Data',
            'nrx_data': 'NRx Data',
            'sample_data': 'Sample Data',
            'ngd_analysis': 'NGD Analysis',
            'market_share': 'Market Share',
            'competitor_data': 'Competitor Data',
            'payment_methods': 'Payment Methods',
            'geography_mapping': 'Geography Mapping',
            'product_analysis': 'Product Analysis',
            'reporting_live_hcp': 'Reporting Live HCP Universe'
        }
        
    def setup_spark(self):
        """Initialize Spark session with robust configuration"""
        print("🔧 Setting up Spark session for IBSA EDA...")
        print("   Using pure Spark (no pandas) for pharmaceutical data processing")
        
        try:
            self.spark = SparkSession.builder \
                .appName("IBSA_Pharmaceutical_EDA") \
                .master("local[*]") \
                .config("spark.ui.enabled", "false") \
                .config("spark.sql.warehouse.dir", str(Path.cwd() / "spark-warehouse")) \
                .config("spark.driver.host", "127.0.0.1") \
                .config("spark.driver.memory", "2g") \
                .config("spark.executor.memory", "2g") \
                .config("spark.sql.execution.arrow.pyspark.enabled", "false") \
                .config("spark.sql.adaptive.enabled", "true") \
                .config("spark.sql.adaptive.coalescePartitions.enabled", "true") \
                .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
                .getOrCreate()
                
            # Set log level to reduce noise
            self.spark.sparkContext.setLogLevel("ERROR")
            
            print(f"✅ Spark session created successfully")
            print(f"   Version: {self.spark.version}")
            print(f"   Master: {self.spark.sparkContext.master}")
            print(f"   Memory: 2GB driver/executor")
            
            return True
            
        except Exception as e:
            print(f"❌ Spark setup failed: {str(e)}")
            print(f"💡 Make sure Java is installed or use findspark")
            return False
        
    def discover_csv_files(self):
        """Discover available IBSA CSV files"""
        print("\n📄 Discovering IBSA CSV files...")
        print("=" * 50)
        
        # Look in parent directory
        data_dir = Path("..").resolve()
        ibsa_files = {}
        
        # Find IBSA CSV files
        for file in data_dir.glob("*.csv"):
            if "IBSA" in file.name or "ibsa" in file.name.lower():
                file_size = file.stat().st_size / (1024*1024)  # MB
                ibsa_files[file.name.lower()] = {
                    'path': str(file),
                    'size_mb': file_size,
                    'name': file.name
                }
                
        if ibsa_files:
            print(f"Found {len(ibsa_files)} IBSA CSV files:")
            for i, (_, info) in enumerate(ibsa_files.items(), 1):
                print(f"  {i:2d}. {info['name']:<35} ({info['size_mb']:.1f} MB)")
        else:
            print("❌ No IBSA CSV files found in parent directory")
            
        return ibsa_files
        
    def load_reporting_tables(self, csv_files):
        """Load IBSA reporting tables from CSV files"""
        print(f"\n🔄 Loading IBSA Reporting Tables...")
        print("=" * 60)
        
        print("📋 Tables to load:")
        for i, (key, name) in enumerate(self.IBSA_REPORTING_TABLES.items(), 1):
            print(f"  {i:2d}. {key:<25} → {name}")
            
        # Load each table
        loaded_count = 0
        missing_tables = []
        
        for table_key, table_name in self.IBSA_REPORTING_TABLES.items():
            print(f"\n🔍 Processing: {table_key} ({table_name})")
            
            # Find matching CSV
            csv_file = self._find_matching_csv(table_name, csv_files)
            
            if csv_file:
                try:
                    df = self.spark.read.option("header", "true").option("inferSchema", "true").csv(csv_file['path'])
                    df.cache()
                    
                    count = df.count()
                    columns = len(df.columns)
                    
                    self.reporting_dataframes[table_key] = {
                        'dataframe': df,
                        'source_file': csv_file['path'],
                        'table_name': table_name,
                        'row_count': count,
                        'column_count': columns
                    }
                    
                    print(f"  ✅ Loaded: {count:,} rows × {columns} columns from {csv_file['name']}")
                    loaded_count += 1
                    
                except Exception as e:
                    print(f"  ❌ Error loading {csv_file['name']}: {str(e)}")
                    missing_tables.append((table_key, table_name))
            else:
                print(f"  ⚠️  No matching CSV file found")
                missing_tables.append((table_key, table_name))
                
        print(f"\n📊 Loading Summary:")
        print(f"  ✅ Successfully loaded: {loaded_count} tables")
        print(f"  ❌ Missing: {len(missing_tables)} tables")
        
        return loaded_count > 0
        
    def _find_matching_csv(self, table_name, csv_files):
        """Find best matching CSV file for a reporting table"""
        table_lower = table_name.lower()
        
        # Direct name matching
        for filename, info in csv_files.items():
            if table_lower in filename or any(word in filename for word in table_lower.split()):
                return info
                
        # Keyword matching
        keywords = {
            'call': ['call', 'activity'],
            'trx': ['trx', 'prescription'],
            'nrx': ['nrx', 'prescription'],
            'prescriber': ['prescriber', 'hcp', 'provider'],
            'territory': ['territory', 'region'],
            'sample': ['sample'],
            'hcp': ['hcp', 'universe', 'provider']
        }
        
        for keyword, search_terms in keywords.items():
            if keyword in table_lower:
                for filename, info in csv_files.items():
                    if any(term in filename for term in search_terms):
                        return info
                        
        return None
        
    def analyze_pk_fk_relationships(self):
        """Analyze Primary/Foreign Key relationships"""
        print(f"\n🔗 Analyzing Primary/Foreign Key Relationships")
        print("=" * 60)
        
        if not self.reporting_dataframes:
            print("❌ No tables loaded for relationship analysis")
            return
            
        # Look for common key patterns
        key_patterns = [
            'id', 'key', 'code', 'number', 'hcp', 'prescriber', 
            'territory', 'product', 'call', 'sample'
        ]
        
        potential_keys = {}
        for table_key, info in self.reporting_dataframes.items():
            df = info['dataframe']
            table_keys = []
            
            for col in df.columns:
                col_lower = col.lower()
                if any(pattern in col_lower for pattern in key_patterns):
                    # Check uniqueness
                    distinct_count = df.select(col).distinct().count()
                    total_count = df.count()
                    uniqueness_ratio = distinct_count / total_count if total_count > 0 else 0
                    
                    table_keys.append({
                        'column': col,
                        'distinct_count': distinct_count,
                        'total_count': total_count,
                        'uniqueness_ratio': uniqueness_ratio,
                        'is_potential_pk': uniqueness_ratio > 0.95,
                        'is_potential_fk': 0.1 < uniqueness_ratio < 0.95
                    })
                    
            potential_keys[table_key] = table_keys
            
        # Display findings
        for table_key, keys in potential_keys.items():
            if keys:
                table_name = self.reporting_dataframes[table_key]['table_name']
                print(f"\n📋 {table_name} ({table_key}):")
                
                pk_candidates = [k for k in keys if k['is_potential_pk']]
                fk_candidates = [k for k in keys if k['is_potential_fk']]
                
                if pk_candidates:
                    print("  🔑 Potential Primary Keys:")
                    for key in pk_candidates:
                        print(f"     • {key['column']}: {key['distinct_count']:,} unique values ({key['uniqueness_ratio']:.1%})")
                        
                if fk_candidates:
                    print("  🔗 Potential Foreign Keys:")
                    for key in fk_candidates:
                        print(f"     • {key['column']}: {key['distinct_count']:,} unique values ({key['uniqueness_ratio']:.1%})")
        
        return potential_keys
        
    def perform_comprehensive_eda(self):
        """Perform comprehensive EDA analysis"""
        print(f"\n📊 Comprehensive EDA Analysis")
        print("=" * 60)
        
        if not self.reporting_dataframes:
            print("❌ No tables loaded for EDA")
            return
            
        eda_results = {}
        
        for table_key, info in self.reporting_dataframes.items():
            print(f"\n🔍 Analyzing: {info['table_name']}")
            print("-" * 40)
            
            df = info['dataframe']
            
            # Basic statistics
            print(f"📏 Shape: {info['row_count']:,} rows × {info['column_count']} columns")
            
            # Column analysis
            print(f"📋 Columns:")
            for i, col in enumerate(df.columns[:10], 1):  # Show first 10
                col_type = dict(df.dtypes)[col]
                print(f"   {i:2d}. {col} ({col_type})")
            if len(df.columns) > 10:
                print(f"   ... and {len(df.columns) - 10} more columns")
                
            # Sample data - Pure Spark only
            print(f"📝 Sample data (first 3 rows):")
            sample_rows = df.limit(3).collect()
            for i, row in enumerate(sample_rows, 1):
                # Show first 5 columns only for readability
                cols_to_show = df.columns[:5]
                row_data = []
                for col in cols_to_show:
                    val = str(row[col])[:20] if row[col] is not None else "NULL"
                    row_data.append(f"{col}: {val}")
                print(f"   Row {i}: {' | '.join(row_data)}...")
                
            eda_results[table_key] = {
                'shape': (info['row_count'], info['column_count']),
                'columns': df.columns,
                'dtypes': dict(df.dtypes)
            }
            
        return eda_results
        
    def run_complete_analysis(self):
        """Run the complete IBSA EDA analysis pipeline"""
        print("🎯 IBSA Pharmaceutical EDA Analysis")
        print("=" * 60)
        print("Replicating IBSA_PoC_EDA.ipynb functionality with better performance")
        print()
        
        try:
            # Step 1: Setup Spark
            if not self.setup_spark():
                print("❌ Spark setup failed. Cannot proceed.")
                return False
            
            # Step 2: Discover CSV files
            csv_files = self.discover_csv_files()
            
            if not csv_files:
                print("❌ No CSV files found. Cannot proceed with analysis.")
                return False
                
            # Step 3: Load reporting tables
            if not self.load_reporting_tables(csv_files):
                print("❌ No tables loaded successfully. Cannot proceed with analysis.")
                return False
                
            # Step 4: PK/FK Analysis
            relationships = self.analyze_pk_fk_relationships()
            
            # Step 5: Comprehensive EDA
            eda_results = self.perform_comprehensive_eda()
            
            print(f"\n✅ IBSA EDA Analysis Complete!")
            print(f"   📊 Tables analyzed: {len(self.reporting_dataframes)}")
            print(f"   🔗 Relationships mapped: {len(relationships)}")
            print(f"   📈 Ready for feature engineering and modeling")
            
            return True
            
        except Exception as e:
            print(f"❌ Error during analysis: {str(e)}")
            return False
            
        finally:
            if self.spark:
                self.spark.stop()
                print(f"\n🔧 Spark session stopped")

def main():
    """Main entry point"""
    print("Starting IBSA Pharmaceutical EDA Analysis...")
    
    analyzer = IBSAEDAAnalysis()
    success = analyzer.run_complete_analysis()
    
    if success:
        print("\n🎉 Analysis completed successfully!")
        return 0
    else:
        print("\n❌ Analysis failed!")
        return 1

if __name__ == "__main__":
    exit(main())