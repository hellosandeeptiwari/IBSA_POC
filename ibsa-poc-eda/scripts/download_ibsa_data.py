#!/usr/bin/env python3
"""
IBSA Data Downloader - Schema-Aware & Robust
============================================
Intelligent downloader that analyzes schema first, then downloads data
with proper filtering for IBSA products and competitors
"""

import os
import sys
from pathlib import Path
import logging
from datetime import datetime, timedelta
import re
from typing import Dict, List, Optional, Tuple

# Setup Spark environment first
def setup_spark_environment():
    try:
        import findspark
        findspark.init()
    except Exception:
        pass
    os.environ['SPARK_LOCAL_IP'] = '127.0.0.1' 
    os.environ['PYSPARK_PYTHON'] = sys.executable
    os.environ['PYSPARK_DRIVER_PYTHON'] = sys.executable

setup_spark_environment()

# Import both Spark and pandas for hybrid approach
try:
    from pyspark.sql import SparkSession
    from pyspark.sql.functions import *
    SPARK_AVAILABLE = True
except ImportError:
    SPARK_AVAILABLE = False

try:
    import pandas as pd
    import pyodbc
    PANDAS_AVAILABLE = True
except ImportError:
    PANDAS_AVAILABLE = False

# Setup detailed logging
logging.basicConfig(
    level=logging.INFO, 
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('ibsa_download.log')
    ]
)
logger = logging.getLogger(__name__)

class IBSASparkDataLoader:
    def __init__(self):
        """Initialize IBSA Spark Data Loader with pure Spark approach"""
        
        # Database connection details
        self.server = 'odsproduction.database.windows.net'
        self.database = 'DWHPRODIBSA'
        self.username = 'odsjobsuser'
        self.password = 'DwHIBSAOD$J0bs!1'
        
        # Spark session (for heavy lifting)
        self.spark = None
        
        # Connection (for metadata/small operations)
        self.connection = None
        self.username = 'odsjobsuser'
        self.password = 'DwHIBSAOD$J0bs!1'
        self.driver = '{ODBC Driver 17 for SQL Server}'
        
        # IBSA Target Products (exact matches)
        self.ibsa_products = [
            'Tirosint Caps', 'Tirosint-Sol', 'Tirosint AG', 'Tirosint',
            'Flector', 'Flector Patch', 
            'Licart', 'Licart Patch'
        ]
        
        # Competitor identification patterns (broader approach)
        self.competitor_patterns = {
            # Thyroid market (Tirosint competitors)
            'thyroid': ['Synthroid', 'Levoxyl', 'Unithroid', 'Armour', 'Nature', 'Cytomel', 'Triostat', 'Levothyroxine', 'Liothyronine'],
            # Topical pain (Flector competitors)  
            'topical_pain': ['Voltaren', 'Pennsaid', 'Diclofenac', 'Aspercreme', 'Bengay', 'Icy Hot', 'Capsaicin', 'Menthol'],
            # Cardiovascular (Licart competitors)
            'cardiovascular': ['Nitro', 'Minitran', 'Nitrek', 'Nitroglycerin', 'Isosorbide', 'Imdur', 'Monoket']
        }
        
        # Data directory
        self.data_dir = Path("../data")
        self.data_dir.mkdir(exist_ok=True)
        
        # Schema cache
        self.table_schemas = {}
        
        # Reporting tables configuration
        self.reporting_tables = {
            'Reporting_BI_CallActivity': {
                'name': 'Call_Activity_Overview',
                'description': 'Sales Call Activity Data',
                'expected_product_cols': ['ProductName', 'Product', 'BrandName', 'DrugName'],
                'expected_date_cols': ['CallDate', 'Date', 'TimePeriod', 'Period', 'Month'],
                'filter_products': True,
                'filter_dates': True
            },
            'Reporting_BI_CallAttainment_Summary_TerritoryLevel': {
                'name': 'Call_Attainment_Territory',
                'description': 'Territory Call Attainment Summary',
                'expected_product_cols': ['Product', 'ProductName'],
                'expected_date_cols': ['Period', 'TimePeriod', 'Month'],
                'filter_products': False,  # Territory-level, might not have product
                'filter_dates': True
            },
            'Reporting_BI_Trx_SampleSummary': {
                'name': 'Trx_Sample_Summary',
                'description': 'TRx and Sample Summary',
                'expected_product_cols': ['ProductName', 'Product', 'BrandName'],
                'expected_date_cols': ['Period', 'TimePeriod', 'Month', 'Date'],
                'filter_products': True,
                'filter_dates': True
            },
            'Reporting_BI_Nrx_SampleSummary': {
                'name': 'Nrx_Sample_Summary', 
                'description': 'NRx and Sample Summary',
                'expected_product_cols': ['ProductName', 'Product', 'BrandName'],
                'expected_date_cols': ['Period', 'TimePeriod', 'Month', 'Date'],
                'filter_products': True,
                'filter_dates': True
            },
            'Reporting_Bi_Territory_CallSummary': {
                'name': 'Territory_Call_Summary',
                'description': 'Territory Call Summary',
                'expected_product_cols': [],
                'expected_date_cols': ['Period', 'TimePeriod', 'Month'],
                'filter_products': False,
                'filter_dates': True
            },
            'Reporting_BI_Sample_LL_DTP': {
                'name': 'Territory_Samples_LL_DTP',
                'description': 'Territory Samples and Lunch & Learn',
                'expected_product_cols': ['ProductName', 'Product'],
                'expected_date_cols': ['Period', 'TimePeriod', 'Month'],
                'filter_products': True,
                'filter_dates': True
            },
            'Reporting_BI_CallAttainment_Summary_Tier': {
                'name': 'Call_Attainment_Tiers',
                'description': 'Call Attainment by Tier',
                'expected_product_cols': [],
                'expected_date_cols': ['Period', 'TimePeriod', 'Month'],
                'filter_products': False,
                'filter_dates': True
            },
            'Reporting_BI_NGD': {
                'name': 'NGD_Overview',
                'description': 'New Growth Decliner Analysis',
                'expected_product_cols': ['ProductName', 'Product', 'BrandName'],
                'expected_date_cols': ['Period', 'TimePeriod', 'Month'],
                'filter_products': True,
                'filter_dates': True
            },
            'Reporting_BI_PrescriberProfile': {
                'name': 'Prescriber_Profile',
                'description': 'HCP Prescriber Profiles',
                'expected_product_cols': ['ProductName', 'Product', 'BrandName'],
                'expected_date_cols': ['Period', 'TimePeriod', 'Month'],
                'filter_products': True,
                'filter_dates': True
            },
            'Reporting_BI_PrescriberOverview': {
                'name': 'Prescriber_Overview',
                'description': 'Prescriber Overview Dashboard',
                'expected_product_cols': ['ProductName', 'Product', 'PrimaryProduct'],
                'expected_date_cols': ['Period', 'TimePeriod', 'Month'],
                'filter_products': True,
                'filter_dates': True
            },
            'Reporting_BI_PrescriberPaymentPlanSummary': {
                'name': 'Prescriber_Payment_Plans',
                'description': 'Prescriber Payment Plan Analysis',
                'expected_product_cols': ['PrimaryProduct', 'ProductName', 'Product'],
                'expected_date_cols': ['Period', 'TimePeriod', 'Month'],
                'filter_products': True,
                'filter_dates': True
            },
            'Reporting_BI_TerritoryPerformanceSummary': {
                'name': 'Territory_Performance_Summary',
                'description': 'Territory Performance Metrics',
                'expected_product_cols': [],
                'expected_date_cols': ['Period', 'TimePeriod', 'Month'],
                'filter_products': False,
                'filter_dates': True
            },
            'Reporting_BI_TerritoryPerformanceOverview': {
                'name': 'Territory_Performance_Overview',
                'description': 'Territory Performance Dashboard',
                'expected_product_cols': [],
                'expected_date_cols': ['Period', 'TimePeriod', 'Month'],
                'filter_products': False,
                'filter_dates': False  # This worked without date filter before
            },
            'Reporting_Live_HCP_Universe': {
                'name': 'HCP_Universe_Live',
                'description': 'Live HCP Universe Data',
                'expected_product_cols': [],
                'expected_date_cols': [],
                'filter_products': False,
                'filter_dates': False
            }
        }

    def setup_spark(self):
        """Setup Spark session with JDBC support"""
        if not SPARK_AVAILABLE:
            logger.warning("⚠️ Spark not available, will use pandas only")
            return False
            
        try:
            self.spark = SparkSession.builder \
                .appName("IBSA_Data_Loader_Hybrid") \
                .master("local[*]") \
                .config("spark.ui.enabled", "false") \
                .config("spark.driver.memory", "4g") \
                .config("spark.sql.execution.arrow.pyspark.enabled", "false") \
                .config("spark.jars.packages", "com.microsoft.sqlserver:mssql-jdbc:9.4.1.jre8") \
                .getOrCreate()
                
            self.spark.sparkContext.setLogLevel("ERROR")
            logger.info("✅ Spark session created - Hybrid mode (Spark + Pandas)")
            return True
        except Exception as e:
            logger.error(f"❌ Spark setup failed: {e}")
            return False

    def get_pandas_connection(self):
        """Get pandas/pyodbc connection for metadata operations"""
        if not PANDAS_AVAILABLE:
            return None
            
        try:
            connection_string = f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={self.server};DATABASE={self.database};UID={self.username};PWD={self.password};Encrypt=yes;TrustServerCertificate=no;"
            self.connection = pyodbc.connect(connection_string)
            logger.info("✅ Pandas connection established")
            return self.connection
        except Exception as e:
            logger.error(f"❌ Pandas connection failed: {e}")
            return None

    def get_table_info_pandas(self, table_name: str) -> Dict:
        """Get table info using pandas for quick metadata analysis"""
        if not self.connection:
            return {}
            
        try:
            # Get column info
            query = f"SELECT TOP 1 * FROM [{table_name}]"
            df_sample = pd.read_sql(query, self.connection)
            
            # Analyze columns
            columns = list(df_sample.columns)
            product_cols = [col for col in columns if any(term in col.lower() for term in ['product', 'brand', 'drug', 'ndc'])]
            date_cols = [col for col in columns if any(term in col.lower() for term in ['date', 'month', 'year', 'period', 'time'])]
            
            return {
                'total_columns': len(columns),
                'columns': columns,
                'product_columns': product_cols,
                'date_columns': date_cols
            }
        except Exception as e:
            logger.error(f"Error analyzing {table_name}: {e}")
            return {}

    def load_table_hybrid(self, table_name: str, output_name: str) -> bool:
        """Hybrid loading: Use Spark for large tables, pandas for small ones"""
        logger.info(f"\n🔄 Loading {table_name} (Hybrid Mode)...")
        
        try:
            # First, get table info with pandas
            table_info = self.get_table_info_pandas(table_name)
            
            if not table_info:
                logger.error(f"   ❌ Cannot analyze table {table_name}")
                return False
                
            logger.info(f"   📋 Table has {table_info['total_columns']} columns")
            
            # Build smart filter
            where_conditions = []
            
            # Product filter
            if table_info['product_columns']:
                product_col = table_info['product_columns'][0]
                ibsa_products = ['Tirosint Caps', 'Tirosint Sol', 'Tirosint AG', 'Flector', 'Licart']
                competitor_products = ['Synthroid', 'Levoxyl', 'Voltaren', 'Diclofenac']
                all_products = ibsa_products + competitor_products
                
                product_conditions = []
                for product in all_products:
                    product_conditions.append(f"UPPER([{product_col}]) LIKE '%{product.upper()}%'")
                
                if product_conditions:
                    where_conditions.append(f"({' OR '.join(product_conditions)})")
                    logger.info(f"   🎯 Applied product filter on [{product_col}]")
            else:
                logger.info(f"   ⚠️ No product column found - loading all data")
            
            # Date filter (last 12 months)
            if table_info['date_columns']:
                date_col = table_info['date_columns'][0]
                # Flexible date filter for different formats
                date_condition = f"(TRY_CAST([{date_col}] AS DATE) >= DATEADD(year, -1, GETDATE()) OR [{date_col}] >= FORMAT(DATEADD(year, -1, GETDATE()), 'yyyyMM'))"
                where_conditions.append(date_condition)
                logger.info(f"   📅 Applied date filter on [{date_col}] (last 12 months)")
            
            # Build query
            base_query = f"SELECT * FROM [{table_name}]"
            if where_conditions:
                full_query = f"{base_query} WHERE {' AND '.join(where_conditions)}"
            else:
                full_query = base_query
            
            # Determine loading method based on table size estimation
            use_spark = self.spark is not None and any(term in table_name.upper() for term in ['TERRITORY', 'HCP', 'PRESCRIBER']) and not any(term in table_name.upper() for term in ['SUMMARY'])
            
            if use_spark:
                logger.info(f"   🚀 Using Spark for large table...")
                return self.load_with_spark(full_query, table_name, output_name)
            else:
                logger.info(f"   🐼 Using Pandas for manageable table...")
                return self.load_with_pandas(full_query, output_name)
                
        except Exception as e:
            logger.error(f"   ❌ Hybrid loading failed for {table_name}: {e}")
            return False

    def load_with_spark(self, query: str, table_name: str, output_name: str) -> bool:
        """Load using Spark for heavy lifting"""
        try:
            jdbc_url = f"jdbc:sqlserver://{self.server}:1433;databaseName={self.database}"
            
            df = self.spark.read.format("jdbc") \
                .option("url", jdbc_url) \
                .option("dbtable", f"({query}) AS filtered_data") \
                .option("user", self.username) \
                .option("password", self.password) \
                .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver") \
                .option("fetchsize", "10000") \
                .load()
            
            count = df.count()
            if count == 0:
                logger.warning(f"   ⚠️ No data returned")
                return False
            
            # Save as CSV
            temp_path = self.data_dir / f"temp_{output_name}"
            df.coalesce(1).write.mode("overwrite").option("header", "true").csv(str(temp_path))
            
            # Rename to final CSV
            csv_files = list(temp_path.glob("part-*.csv"))
            if csv_files:
                final_csv = self.data_dir / f"IBSA_{output_name}.csv"
                csv_files[0].rename(final_csv)
                
                import shutil
                shutil.rmtree(temp_path)
                
                size_mb = final_csv.stat().st_size / (1024*1024)
                logger.info(f"   ✅ Spark success: {count:,} rows × {len(df.columns)} columns ({size_mb:.1f} MB)")
                return True
            
        except Exception as e:
            logger.error(f"   ❌ Spark loading failed: {e}")
            return False

    def load_with_pandas(self, query: str, output_name: str) -> bool:
        """Load using pandas for smaller datasets"""
        try:
            df = pd.read_sql(query, self.connection)
            
            if len(df) == 0:
                logger.warning(f"   ⚠️ No data returned")
                return False
            
            # Save as CSV
            output_file = self.data_dir / f"IBSA_{output_name}.csv"
            df.to_csv(output_file, index=False)
            
            size_mb = output_file.stat().st_size / (1024*1024)
            logger.info(f"   ✅ Pandas success: {len(df):,} rows × {len(df.columns)} columns ({size_mb:.1f} MB)")
            return True
            
        except Exception as e:
            logger.error(f"   ❌ Pandas loading failed: {e}")
            return False

    def load_all_tables_hybrid(self):
        """Load all tables using hybrid approach"""
        logger.info("🚀 Starting IBSA Hybrid Data Loading (Spark + Pandas)")
        logger.info(f"📁 Output directory: {self.data_dir.absolute()}")
        
        # Setup connections
        spark_ready = self.setup_spark() if SPARK_AVAILABLE else False
        pandas_ready = self.get_pandas_connection() if PANDAS_AVAILABLE else False
        
        if not (spark_ready or pandas_ready):
            logger.error("❌ Neither Spark nor Pandas connections available")
            return False
        
        # Tables to load
        tables = {
            'Reporting_BI_CallActivity': 'Call_Activity_Overview',
            'Reporting_BI_PrescriberOverview': 'Prescriber_Overview',
            'Reporting_BI_TerritoryPerformanceOverview': 'Territory_Performance_Overview',
            'Reporting_Live_HCP_Universe': 'HCP_Universe_Live',
            'Reporting_BI_NGD': 'NGD_Overview',
            'Reporting_BI_Trx_SampleSummary': 'Trx_Sample_Summary',
            'Reporting_BI_Nrx_SampleSummary': 'Nrx_Sample_Summary',
            'Reporting_BI_CallAttainment_Summary_TerritoryLevel': 'Call_Attainment_Territory',
            'Reporting_BI_PrescriberProfile': 'Prescriber_Profile',
            'Reporting_BI_Sample_LL_DTP': 'Territory_Samples_LL_DTP'
        }
        
        success_count = 0
        total_tables = len(tables)
        
        try:
            for table_name, output_name in tables.items():
                if self.load_table_hybrid(table_name, output_name):
                    success_count += 1
                    
        finally:
            if self.spark:
                self.spark.stop()
                logger.info("🔌 Spark session stopped")
            if self.connection:
                self.connection.close()
                logger.info("🔌 Pandas connection closed")
        
        logger.info(f"\n📊 Hybrid Loading Summary:")
        logger.info(f"   ✅ Successfully loaded: {success_count}/{total_tables} tables")
        logger.info(f"   📁 Files saved to: {self.data_dir.absolute()}")
        
        if success_count > 0:
            logger.info(f"\n🎉 Hybrid data loading completed!")
            return True
        else:
            logger.error(f"❌ No tables loaded successfully")
            return False

    def analyze_table_schema(self, conn: pyodbc.Connection, table_name: str) -> Dict:
        """Analyze table schema comprehensively"""
        logger.info(f"🔍 Analyzing schema for {table_name}")
        
        try:
            # Get detailed column information
            schema_query = f"""
            SELECT 
                COLUMN_NAME,
                DATA_TYPE,
                IS_NULLABLE,
                CHARACTER_MAXIMUM_LENGTH,
                NUMERIC_PRECISION,
                NUMERIC_SCALE,
                COLUMN_DEFAULT,
                ORDINAL_POSITION
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_NAME = '{table_name}'
            ORDER BY ORDINAL_POSITION
            """
            
            columns_df = pd.read_sql(schema_query, conn)
            
            if len(columns_df) == 0:
                logger.warning(f"⚠️  Table {table_name} not found or no access")
                return None
                
            # Analyze columns
            schema_info = {
                'table_name': table_name,
                'total_columns': len(columns_df),
                'columns': columns_df.to_dict('records'),
                'product_columns': [],
                'date_columns': [],
                'key_columns': [],
                'numeric_columns': [],
                'text_columns': []
            }
            
            # Categorize columns
            for _, col in columns_df.iterrows():
                col_name = col['COLUMN_NAME']
                data_type = col['DATA_TYPE'].lower()
                
                # Product-related columns
                if any(term in col_name.lower() for term in ['product', 'brand', 'drug', 'medication', 'ndc']):
                    schema_info['product_columns'].append(col_name)
                
                # Date-related columns
                if any(term in col_name.lower() for term in ['date', 'time', 'period', 'month', 'year']) or 'date' in data_type:
                    schema_info['date_columns'].append({
                        'name': col_name, 
                        'type': data_type,
                        'is_date_type': 'date' in data_type or 'time' in data_type
                    })
                
                # Key columns (potential primary/foreign keys)
                if any(term in col_name.lower() for term in ['id', 'key', 'code', 'number']) and 'int' in data_type:
                    schema_info['key_columns'].append(col_name)
                
                # Numeric columns
                if any(t in data_type for t in ['int', 'float', 'decimal', 'numeric', 'money']):
                    schema_info['numeric_columns'].append(col_name)
                
                # Text columns
                if any(t in data_type for t in ['char', 'text', 'string']):
                    schema_info['text_columns'].append(col_name)
            
            # Get sample data for product column analysis
            if schema_info['product_columns']:
                try:
                    sample_query = f"SELECT TOP 100 DISTINCT [{schema_info['product_columns'][0]}] FROM [{table_name}] WHERE [{schema_info['product_columns'][0]}] IS NOT NULL"
                    sample_products = pd.read_sql(sample_query, conn)
                    schema_info['sample_products'] = sample_products.iloc[:,0].tolist()
                except:
                    schema_info['sample_products'] = []
            else:
                schema_info['sample_products'] = []
            
            # Cache schema
            self.table_schemas[table_name] = schema_info
            
            logger.info(f"   📊 {len(columns_df)} columns analyzed")
            logger.info(f"   🎯 Product columns: {len(schema_info['product_columns'])}")
            logger.info(f"   📅 Date columns: {len(schema_info['date_columns'])}")
            
            return schema_info
            
        except Exception as e:
            logger.error(f"❌ Schema analysis failed for {table_name}: {e}")
            return None

    def build_smart_product_filter(self, schema_info: Dict) -> str:
        """Build intelligent product filter based on actual data"""
        if not schema_info or not schema_info['product_columns']:
            return ""
        
        product_col = schema_info['product_columns'][0]
        sample_products = schema_info.get('sample_products', [])
        
        # Find IBSA and competitor products in the actual data
        relevant_products = []
        
        # Add IBSA products (exact and partial matches)
        for ibsa_product in self.ibsa_products:
            # Exact matches
            if ibsa_product in sample_products:
                relevant_products.append(ibsa_product)
            
            # Partial matches
            for sample in sample_products:
                if sample and ibsa_product.lower() in sample.lower():
                    relevant_products.append(sample)
        
        # Add competitor products (pattern matching)
        for category, patterns in self.competitor_patterns.items():
            for pattern in patterns:
                for sample in sample_products:
                    if sample and pattern.lower() in sample.lower():
                        relevant_products.append(sample)
        
        # Remove duplicates and None values
        relevant_products = list(set([p for p in relevant_products if p]))
        
        if not relevant_products:
            logger.info(f"   ⚠️  No IBSA/competitor products found in sample data")
            return ""
        
        logger.info(f"   🎯 Found {len(relevant_products)} relevant products")
        
        # Create IN clause
        products_quoted = "', '".join(relevant_products)
        return f"[{product_col}] IN ('{products_quoted}')"

    def build_smart_date_filter(self, schema_info: Dict) -> str:
        """Build robust date filter (1 year) based on column type"""
        if not schema_info or not schema_info['date_columns']:
            return ""
        
        # Find the best date column
        date_col_info = schema_info['date_columns'][0]
        date_col = date_col_info['name']
        is_date_type = date_col_info['is_date_type']
        
        # Calculate 1 year ago
        one_year_ago = datetime.now() - timedelta(days=365)
        
        if is_date_type:
            # Native date column
            filter_clause = f"[{date_col}] >= '{one_year_ago.strftime('%Y-%m-%d')}'"
        else:
            # String date column - try multiple formats
            year_month = one_year_ago.strftime('%Y%m')  # YYYYMM format
            iso_date = one_year_ago.strftime('%Y-%m-%d')
            
            filter_clause = f"""(
                TRY_CAST([{date_col}] AS DATE) >= '{iso_date}' OR
                [{date_col}] >= '{year_month}' OR
                [{date_col}] >= '{one_year_ago.year}'
            )"""
        
        logger.info(f"   📅 Applied 1-year date filter on [{date_col}]")
        return filter_clause

    def download_table_with_schema(self, conn: pyodbc.Connection, table_name: str, table_config: Dict) -> bool:
        """Download table using schema-aware approach"""
        logger.info(f"\n{'='*60}")
        logger.info(f"🔄 Processing: {table_config['description']}")
        
        try:
            # Analyze schema first
            schema_info = self.analyze_table_schema(conn, table_name)
            if not schema_info:
                return False
            
            # Build filters
            filters = []
            
            # Product filter
            if table_config.get('filter_products', False):
                product_filter = self.build_smart_product_filter(schema_info)
                if product_filter:
                    filters.append(product_filter)
            
            # Date filter  
            if table_config.get('filter_dates', False):
                date_filter = self.build_smart_date_filter(schema_info)
                if date_filter:
                    filters.append(date_filter)
            
            # Build query
            base_query = f"SELECT * FROM [{table_name}]"
            if filters:
                query = f"{base_query} WHERE {' AND '.join(filters)}"
            else:
                query = base_query
            
            logger.info(f"   🔍 Executing query with {len(filters)} filters...")
            
            # Execute with retry logic
            max_retries = 2
            for attempt in range(max_retries):
                try:
                    df = pd.read_sql(query, conn)
                    break
                except Exception as e:
                    if attempt < max_retries - 1:
                        logger.warning(f"   ⚠️  Attempt {attempt + 1} failed, retrying...")
                        # Try without filters on retry
                        if filters and attempt == 0:
                            query = base_query
                            filters = []
                        continue
                    else:
                        raise e
            
            if len(df) == 0:
                logger.warning(f"   ⚠️  No data returned")
                return False
            
            # Save to CSV
            output_file = self.data_dir / f"IBSA_{table_config['name']}.csv"
            df.to_csv(output_file, index=False, encoding='utf-8')
            
            file_size = output_file.stat().st_size / (1024*1024)
            
            logger.info(f"   ✅ SUCCESS: {len(df):,} rows × {len(df.columns)} columns")
            logger.info(f"   💾 Saved: {output_file.name} ({file_size:.1f} MB)")
            
            return True
            
        except Exception as e:
            logger.error(f"   ❌ FAILED: {str(e)}")
            return False

    def download_all_tables(self) -> bool:
        """Download all tables with comprehensive error handling"""
        logger.info("🚀 IBSA Schema-Aware Data Download Starting")
        logger.info(f"📁 Output Directory: {self.data_dir.absolute()}")
        logger.info(f"🎯 Target Products: {len(self.ibsa_products)} IBSA products")
        logger.info(f"🏢 Competitor Categories: {len(self.competitor_patterns)} categories")
        logger.info(f"📅 Date Filter: Last 1 year")
        
        conn = self.get_connection()
        if not conn:
            return False
        
        success_count = 0
        total_tables = len(self.reporting_tables)
        results = []
        
        try:
            for table_name, table_config in self.reporting_tables.items():
                success = self.download_table_with_schema(conn, table_name, table_config)
                if success:
                    success_count += 1
                    results.append(f"✅ {table_config['name']}")
                else:
                    results.append(f"❌ {table_config['name']}")
                    
        finally:
            conn.close()
            logger.info("\n🔌 Database connection closed")
        
        # Final summary
        logger.info("\n" + "="*70)
        logger.info("📊 DOWNLOAD SUMMARY")
        logger.info("="*70)
        logger.info(f"✅ Successfully downloaded: {success_count}/{total_tables} tables")
        logger.info(f"📁 Files location: {self.data_dir.absolute()}")
        
        logger.info("\n📋 Detailed Results:")
        for result in results:
            logger.info(f"   {result}")
        
        if success_count > 0:
            logger.info(f"\n🎉 Download completed! Ready for Spark EDA analysis")
            logger.info(f"🎯 {success_count} CSV files ready for processing")
            return True
        else:
            logger.error(f"\n❌ No tables downloaded successfully")
            return False

def main():
    """Main entry point for hybrid data loading"""
    loader = IBSASparkDataLoader()
    
    # Run hybrid loading
    success = loader.load_all_tables_hybrid()
    
    if success:
        print("\n🎉 IBSA hybrid data loading completed successfully!")
        print(f"📁 Check the 'data' folder for your CSV files")
        print(f"🚀 Ready for Spark EDA analysis with ibsa_eda_main.py")
        return True
    else:
        print("\n❌ Hybrid data loading failed")
        print("Check the logs above for details")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
        
        # Database connection details
        self.server = 'odsproduction.database.windows.net'
        self.database = 'DWHPRODIBSA'
        self.username = 'odsjobsuser'
        self.password = 'DwHIBSAOD$J0bs!1'
        self.driver = '{ODBC Driver 17 for SQL Server}'
        
        # IBSA Products to filter
        self.ibsa_products = [
            'Tirosint Caps',
            'Tirosint Sol', 
            'Tirosint AG',
            'Flector',
            'Licart'
        ]
        
        # Competitor products (by therapeutic area)
        self.competitor_products = [
            # Thyroid competitors (for Tirosint products)
            'Synthroid',
            'Levoxyl', 
            'Unithroid',
            'Armour Thyroid',
            'Nature-Throid',
            'WP Thyroid',
            'Cytomel',
            'Triostat',
            # Pain management competitors (for Flector)
            'Voltaren Gel',
            'Pennsaid',
            'Aspercreme',
            'Bengay',
            'Icy Hot',
            # Cardiovascular competitors (for Licart)
            'Nitro-Dur',
            'Minitran',
            'Nitrek'
        ]
        
        # All products for filtering
        self.all_products = self.ibsa_products + self.competitor_products
        
        # Data directory
        self.data_dir = Path("../data")
        self.data_dir.mkdir(exist_ok=True)
        
        # IBSA Reporting Tables with their filtering needs
        self.reporting_tables = {
            'Reporting_BI_CallActivity': {
                'name': 'Call_Activity_Overview',
                'description': 'Call Activity Overview',
                'product_filter': True,
                'date_filter': True
            },
            'Reporting_BI_CallAttainment_Summary_TerritoryLevel': {
                'name': 'Call_Attainment_Territory',
                'description': 'Call Attainment Summary Territory Level',
                'product_filter': True,
                'date_filter': True
            },
            'Reporting_BI_Trx_SampleSummary': {
                'name': 'Trx_Sample_Summary',
                'description': 'Samples/Trx Summary',
                'product_filter': True,
                'date_filter': True
            },
            'Reporting_BI_Nrx_SampleSummary': {
                'name': 'Nrx_Sample_Summary', 
                'description': 'Samples/Nrx Summary',
                'product_filter': True,
                'date_filter': True
            },
            'Reporting_Bi_Territory_CallSummary': {
                'name': 'Territory_Call_Summary',
                'description': 'Territory Calls Summary',
                'product_filter': False,  # Territory level data
                'date_filter': True
            },
            'Reporting_BI_Sample_LL_DTP': {
                'name': 'Territory_Samples_LL_DTP',
                'description': 'Territory Samples and L&L Summary',
                'product_filter': True,
                'date_filter': True
            },
            'Reporting_BI_CallAttainment_Summary_Tier': {
                'name': 'Call_Attainment_Tiers',
                'description': 'Call Attainment Summary (Tiers)',
                'product_filter': True,
                'date_filter': True
            },
            'Reporting_BI_NGD': {
                'name': 'NGD_Overview',
                'description': 'New Growth Decliner Overview',
                'product_filter': True,
                'date_filter': True
            },
            'Reporting_BI_PrescriberProfile': {
                'name': 'Prescriber_Profile',
                'description': 'Prescriber Profile',
                'product_filter': True,
                'date_filter': True
            },
            'Reporting_BI_PrescriberOverview': {
                'name': 'Prescriber_Overview',
                'description': 'Prescriber Overview',
                'product_filter': True,
                'date_filter': True
            },
            'Reporting_BI_PrescriberPaymentPlanSummary': {
                'name': 'Prescriber_Payment_Plans',
                'description': 'Prescriber Product Payer Plan Summary',
                'product_filter': True,
                'date_filter': True
            },
            'Reporting_BI_TerritoryPerformanceSummary': {
                'name': 'Territory_Performance_Summary',
                'description': 'Territory Performance Summary',
                'product_filter': False,  # Territory performance is not product-specific
                'date_filter': True
            },
            'Reporting_BI_TerritoryPerformanceOverview': {
                'name': 'Territory_Performance_Overview',
                'description': 'Territory Performance Overview',
                'product_filter': False,  # Territory overview is not product-specific
                'date_filter': True
            },
            'Reporting_Live_HCP_Universe': {
                'name': 'HCP_Universe_Live',
                'description': 'HCP Universe (Live Data)',
                'product_filter': False,  # HCP Universe is provider-centric
                'date_filter': False
            }
        }

    def get_connection(self):
        """Create database connection"""
        try:
            connection_string = f"DRIVER={self.driver};SERVER={self.server};DATABASE={self.database};UID={self.username};PWD={self.password}"
            conn = pyodbc.connect(connection_string)
            logger.info("✅ Database connection established")
            return conn
        except Exception as e:
            logger.error(f"❌ Database connection failed: {e}")
            return None

    def get_table_columns(self, conn, table_name):
        """Get column names for a table to build smart filters"""
        try:
            query = f"""
            SELECT COLUMN_NAME, DATA_TYPE 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_NAME = '{table_name}'
            ORDER BY ORDINAL_POSITION
            """
            columns_df = pd.read_sql(query, conn)
            return columns_df
        except Exception as e:
            logger.warning(f"Could not get columns for {table_name}: {e}")
            return None

    def build_product_filter(self, columns_df):
        """Build product filter based on available columns"""
        if columns_df is None:
            return ""
        
        column_names = columns_df['COLUMN_NAME'].str.lower().tolist()
        
        # Look for product-related columns
        product_columns = []
        for col in column_names:
            if any(term in col for term in ['product', 'brand', 'drug', 'medication', 'generic', 'ndc']):
                product_columns.append(columns_df[columns_df['COLUMN_NAME'].str.lower() == col]['COLUMN_NAME'].iloc[0])
        
        if not product_columns:
            return ""
        
        # Use the first product column found
        product_col = product_columns[0]
        
        # Create IN clause for products
        products_list = "', '".join(self.all_products)
        return f"WHERE UPPER([{product_col}]) IN ('{products_list.upper()}')"

    def build_date_filter(self, columns_df, existing_where=False):
        """Build date filter for recent data (last 24 months) - handle string dates"""
        if columns_df is None:
            return ""
            
        column_names = columns_df['COLUMN_NAME'].str.lower().tolist()
        
        # Look for date columns
        date_columns = []
        for col in column_names:
            if any(term in col for term in ['date', 'month', 'year', 'period', 'time']):
                date_columns.append(columns_df[columns_df['COLUMN_NAME'].str.lower() == col]['COLUMN_NAME'].iloc[0])
        
        if not date_columns:
            return ""
        
        # Use the first date column found
        date_col = date_columns[0]
        
        # Filter for last 24 months - handle both string and date formats
        connector = "AND" if existing_where else "WHERE"
        
        # Try different date filter approaches
        if 'period' in date_col.lower():
            # For period columns that might be YYYYMM format
            return f" {connector} (TRY_CAST([{date_col}] AS DATE) >= DATEADD(month, -24, GETDATE()) OR [{date_col}] >= FORMAT(DATEADD(month, -24, GETDATE()), 'yyyyMM'))"
        else:
            # For other date columns
            return f" {connector} (TRY_CAST([{date_col}] AS DATE) >= DATEADD(month, -24, GETDATE()) OR [{date_col}] >= CONVERT(VARCHAR, DATEADD(month, -24, GETDATE()), 120))"

    def download_table(self, conn, table_name, table_info):
        """Download a specific table with appropriate filters"""
        logger.info(f"\n🔄 Processing: {table_info['description']}")
        
        try:
            # Get table structure
            columns_df = self.get_table_columns(conn, table_name)
            
            if columns_df is None or len(columns_df) == 0:
                logger.warning(f"⚠️  Could not access table structure for {table_name}")
                return False
            
            logger.info(f"   📋 Table has {len(columns_df)} columns")
            
            # Build query with appropriate filters
            base_query = f"SELECT * FROM [{table_name}]"
            
            where_clause = ""
            
            # Add product filter if applicable
            if table_info.get('product_filter', False):
                product_filter = self.build_product_filter(columns_df)
                if product_filter:
                    where_clause = product_filter
                    logger.info(f"   🎯 Applied product filter for IBSA/competitor products")
                else:
                    logger.info(f"   ⚠️  No product column found - downloading all data")
            
            # Add date filter if applicable  
            if table_info.get('date_filter', False):
                date_filter = self.build_date_filter(columns_df, bool(where_clause))
                if date_filter:
                    where_clause += date_filter
                    logger.info(f"   📅 Applied date filter (last 24 months)")
            
            # Construct final query
            query = base_query + where_clause
            
            logger.info(f"   🔍 Executing query...")
            
            # Execute query
            df = pd.read_sql(query, conn)
            
            if len(df) == 0:
                logger.warning(f"   ⚠️  No data returned for {table_name}")
                return False
            
            # Save to CSV
            output_file = self.data_dir / f"IBSA_{table_info['name']}.csv"
            df.to_csv(output_file, index=False)
            
            file_size = output_file.stat().st_size / (1024*1024)  # MB
            
            logger.info(f"   ✅ Downloaded: {len(df):,} rows × {len(df.columns)} columns")
            logger.info(f"   💾 Saved to: {output_file.name} ({file_size:.1f} MB)")
            
            return True
            
        except Exception as e:
            logger.error(f"   ❌ Failed to download {table_name}: {e}")
            return False

    def download_all_tables(self):
        """Download all IBSA reporting tables"""
        logger.info("🚀 Starting IBSA Product-Filtered Data Download")
        logger.info(f"📁 Output directory: {self.data_dir.absolute()}")
        logger.info(f"🎯 IBSA Products: {', '.join(self.ibsa_products)}")
        logger.info(f"🏢 Competitor Products: {len(self.competitor_products)} products")
        logger.info("=" * 70)
        
        conn = self.get_connection()
        if not conn:
            return False
        
        success_count = 0
        total_tables = len(self.reporting_tables)
        
        try:
            for table_name, table_info in self.reporting_tables.items():
                if self.download_table(conn, table_name, table_info):
                    success_count += 1
                    
        finally:
            conn.close()
            logger.info("🔌 Database connection closed")
        
        logger.info("\n" + "=" * 70)
        logger.info(f"📊 Download Summary:")
        logger.info(f"   ✅ Successfully downloaded: {success_count}/{total_tables} tables")
        logger.info(f"   📁 Files saved to: {self.data_dir.absolute()}")
        
        if success_count > 0:
            logger.info(f"\n🎉 Product-filtered data download completed!")
            logger.info(f"🎯 Ready for Spark EDA analysis with IBSA focus")
            return True
        else:
            logger.error(f"❌ No tables downloaded successfully")
            return False

def main():
    """Main function"""
    print("🎯 IBSA Pharmaceutical Data Downloader (Product-Filtered)")
    print("=" * 60)
    print("Downloading IBSA products and competitors for EDA analysis...")
    
    downloader = IBSADataDownloader()
    success = downloader.download_all_tables()
    
    return 0 if success else 1

if __name__ == "__main__":
    exit(main())
        
    def connect_to_database(self):
        """Establish connection to IBSA SQL Server database"""
        print("🔗 Connecting to IBSA Database...")
        print(f"   Server: {self.server}")
        print(f"   Database: {self.database}")
        
        try:
            connection_string = (
                f'DRIVER={self.driver};'
                f'SERVER={self.server};'
                f'DATABASE={self.database};'
                f'UID={self.username};'
                f'PWD={self.password};'
                f'Encrypt=yes;'
                f'TrustServerCertificate=no;'
                f'Connection Timeout=30;'
            )
            
            self.connection = pyodbc.connect(connection_string)
            print("✅ Database connection established successfully")
            return True
            
        except Exception as e:
            print(f"❌ Database connection failed: {str(e)}")
            return False
            
    def test_connection(self):
        """Test database connection and show available tables"""
        if not self.connection:
            return False
            
        try:
            cursor = self.connection.cursor()
            
            # Test basic query
            cursor.execute("SELECT @@VERSION")
            version = cursor.fetchone()[0]
            print(f"📋 SQL Server Version: {version[:50]}...")
            
            # Check if our tables exist
            print(f"\n🔍 Checking IBSA reporting tables...")
            existing_tables = []
            missing_tables = []
            
            for table_key, table_name in self.IBSA_TABLES.items():
                cursor.execute("""
                    SELECT COUNT(*) as table_exists
                    FROM INFORMATION_SCHEMA.TABLES 
                    WHERE TABLE_NAME = ?
                """, table_name)
                
                result = cursor.fetchone()
                if result and result[0] > 0:
                    # Get row count
                    cursor.execute(f"SELECT COUNT(*) FROM [{table_name}]")
                    row_count = cursor.fetchone()[0]
                    existing_tables.append((table_key, table_name, row_count))
                    print(f"   ✅ {table_name}: {row_count:,} rows")
                else:
                    missing_tables.append((table_key, table_name))
                    print(f"   ❌ {table_name}: NOT FOUND")
            
            print(f"\n📊 Summary:")
            print(f"   ✅ Found: {len(existing_tables)} tables")
            print(f"   ❌ Missing: {len(missing_tables)} tables")
            
            cursor.close()
            return len(existing_tables) > 0
            
        except Exception as e:
            print(f"❌ Connection test failed: {str(e)}")
            return False
            
    def download_table(self, table_key, table_name):
        """Download a single table and save as CSV"""
        print(f"\n📥 Downloading: {table_key}")
        print(f"   Table: {table_name}")
        
        try:
            # Query the table
            query = f"SELECT * FROM [{table_name}]"
            df = pd.read_sql(query, self.connection)
            
            # Generate CSV filename
            csv_filename = f"IBSA_{table_key}.csv"
            csv_path = self.data_dir / csv_filename
            
            # Save to CSV
            df.to_csv(csv_path, index=False)
            
            file_size = csv_path.stat().st_size / (1024*1024)  # MB
            
            print(f"   ✅ Downloaded: {len(df):,} rows × {len(df.columns)} columns")
            print(f"   💾 Saved: {csv_filename} ({file_size:.1f} MB)")
            
            return True, len(df), len(df.columns)
            
        except Exception as e:
            print(f"   ❌ Download failed: {str(e)}")
            return False, 0, 0
            
    def download_all_tables(self):
        """Download all IBSA reporting tables"""
        print(f"\n🚀 Starting bulk download of IBSA reporting tables")
        print(f"   Target directory: {self.data_dir}")
        print("=" * 70)
        
        successful_downloads = 0
        failed_downloads = 0
        total_rows = 0
        
        start_time = datetime.now()
        
        for table_key, table_name in self.IBSA_TABLES.items():
            success, rows, cols = self.download_table(table_key, table_name)
            
            if success:
                successful_downloads += 1
                total_rows += rows
            else:
                failed_downloads += 1
                
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        print(f"\n" + "=" * 70)
        print(f"📊 DOWNLOAD SUMMARY")
        print(f"   ✅ Successful: {successful_downloads} tables")
        print(f"   ❌ Failed: {failed_downloads} tables")  
        print(f"   📈 Total rows: {total_rows:,}")
        print(f"   ⏱️  Duration: {duration:.1f} seconds")
        print(f"   📁 Files saved to: {self.data_dir}")
        
        return successful_downloads > 0
        
    def list_downloaded_files(self):
        """List all downloaded CSV files"""
        csv_files = list(self.data_dir.glob("IBSA_*.csv"))
        
        if csv_files:
            print(f"\n📋 Downloaded IBSA CSV Files:")
            print("-" * 60)
            
            total_size = 0
            for i, csv_file in enumerate(csv_files, 1):
                size_mb = csv_file.stat().st_size / (1024*1024)
                total_size += size_mb
                print(f"  {i:2d}. {csv_file.name:<35} ({size_mb:6.1f} MB)")
                
            print("-" * 60)
            print(f"      Total: {len(csv_files)} files ({total_size:.1f} MB)")
        else:
            print("❌ No IBSA CSV files found")
            
        return csv_files
        
    def close_connection(self):
        """Close database connection"""
        if self.connection:
            self.connection.close()
            print("🔌 Database connection closed")
            
    def run_download(self):
        """Main download process"""
        print("🎯 IBSA Pharmaceutical Data Downloader")
        print("=" * 60)
        print(f"📊 Downloading {len(self.IBSA_TABLES)} IBSA reporting tables")
        print()
        
        try:
            # Connect to database
            if not self.connect_to_database():
                return False
                
            # Test connection
            if not self.test_connection():
                return False
                
            # Download all tables
            success = self.download_all_tables()
            
            # List downloaded files
            csv_files = self.list_downloaded_files()
            
            if success and csv_files:
                print(f"\n🎉 SUCCESS: {len(csv_files)} IBSA tables downloaded!")
                print(f"   Ready for Spark EDA analysis")
                return True
            else:
                print(f"\n❌ FAILED: No tables downloaded successfully")
                return False
                
        except Exception as e:
            print(f"❌ Download process failed: {str(e)}")
            return False
            
        finally:
            self.close_connection()

def main():
    """Main entry point for hybrid data loading"""
    loader = IBSASparkDataLoader()
    
    # Run hybrid loading
    success = loader.load_all_tables_hybrid()
    
    if success:
        print("\n🎉 IBSA hybrid data loading completed successfully!")
        print(f"📁 Check the 'data' folder for your CSV files")
        print(f"🚀 Ready for Spark EDA analysis with ibsa_eda_main.py")
        return True
    else:
        print("\n❌ Hybrid data loading failed")
        print("Check the logs above for details")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)