#!/usr/bin/env python3
"""
IBSA Hybrid Data Loader
=======================
Smart downloader using Spark for heavy lifting and Pandas for metadata
"""

import argparse
import math
import os
import sys
from pathlib import Path
import logging
from typing import Dict, List, Optional, Tuple
import warnings

# Setup Spark environment
def setup_spark_environment():
    try:
        import findspark
        findspark.init()
    except:
        pass
    os.environ['SPARK_LOCAL_IP'] = '127.0.0.1'
    os.environ['PYSPARK_PYTHON'] = sys.executable
    os.environ['PYSPARK_DRIVER_PYTHON'] = sys.executable

setup_spark_environment()

# Imports
try:
    from pyspark.sql import SparkSession
    SPARK_AVAILABLE = True
except ImportError:
    SPARK_AVAILABLE = False

try:
    import pandas as pd
    import pyodbc
    PANDAS_AVAILABLE = True
except ImportError:
    PANDAS_AVAILABLE = False

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Product universe (defaults - will be auto-discovered when DB is available)
DEFAULT_IBSA_PRODUCTS: List[str] = [
    "Tirosint Caps",
    "Tirosint-SOL",
    "Tirosint Sol",
    "Tirosint AG",
    "Tirosint",
    "Flector",
    "Flector Patch",
    "Licart",
    "Licart Patch",
]

DEFAULT_COMPETITOR_PRODUCTS: List[str] = [
    # Thyroid
    "Synthroid",
    "Levoxyl",
    "Unithroid",
    "Armour Thyroid",
    "Nature-Throid",
    "Cytomel",
    "Triostat",
    "Levothyroxine",
    "Liothyronine",
    # Topical pain
    "Voltaren",
    "Voltaren Gel",
    "Pennsaid",
    "Diclofenac",
    "Aspercreme",
    "Bengay",
    "Icy Hot",
    "Menthol",
    "Capsaicin",
    # Cardiovascular transdermal
    "Nitro-Dur",
    "Nitrek",
    "Minitran",
    "Nitroglycerin",
    "Isosorbide",
]

DEFAULT_IBSA_KEYWORDS: List[str] = [
    "TIROSINT",
    "FLECTOR",
    "LICART",
]

# Engine heuristics / chunking thresholds
SPARK_ROW_COUNT_THRESHOLD = 250_000
SPARK_PARTITION_ROW_TARGET = 500_000
SPARK_MAX_PARTITIONS = 48
SPARK_MIN_PARTITIONS = 4
SPARK_DEFAULT_FETCHSIZE = 50_000

PANDAS_CHUNK_SIZE = 100_000
PANDAS_CHUNK_LOG_EVERY = 5

TABLE_CONFIG: Dict[str, Dict[str, object]] = {
    'Reporting_BI_CallActivity': {
        'output': 'Call_Activity_Overview',
        'description': 'Sales Call Activity Data',
        'schema': 'Reporting',
        'filter_products': True,
        'filter_dates': True,
        'spark_preferred': True,
        'expected_product_cols': ['ProductName', 'Product', 'BrandName'],
        'expected_date_cols': ['CallDate', 'Date', 'TimePeriod', 'Period', 'Month']
    },
    'Reporting_BI_PrescriberOverview': {
        'output': 'Prescriber_Overview',
        'description': 'Prescriber Overview Dashboard',
        'schema': 'Reporting',
        'filter_products': True,
        'filter_dates': True,
        'spark_preferred': True,
        'expected_product_cols': ['ProductGroupName', 'ProductName', 'PrimaryProduct'],
        'expected_date_cols': ['LastCallDate', 'Period', 'TimePeriod', 'Month']
    },
    'Reporting_BI_TerritoryPerformanceOverview': {
        'output': 'Territory_Performance_Overview',
        'description': 'Territory Performance Dashboard',
        'schema': 'Reporting',
        'filter_products': False,
        'filter_dates': False,
        'spark_preferred': True,
        'expected_product_cols': [],
        'expected_date_cols': ['Period', 'TimePeriod', 'Month']
    },
    'Reporting_Live_HCP_Universe': {
        'output': 'HCP_Universe_Live',
        'description': 'Live HCP Universe Data',
        'schema': 'Reporting',
        'filter_products': False,
        'filter_dates': False,
        'spark_preferred': True,
        'expected_product_cols': [],
        'expected_date_cols': []
    },
    'Reporting_BI_NGD': {
        'output': 'NGD_Overview',
        'description': 'New / Growth / Decliner Metrics',
        'schema': 'Reporting',
        'filter_products': True,
        'filter_dates': True,
        'spark_preferred': True,
        'expected_product_cols': ['Product', 'ProductName', 'Brand'],
        'expected_date_cols': ['StartDateTqty', 'Period', 'Month']
    },
    'Reporting_BI_Trx_SampleSummary': {
        'output': 'Trx_Sample_Summary',
        'description': 'TRx & Sample Summary',
        'schema': 'Reporting',
        'filter_products': True,
        'filter_dates': True,
        'spark_preferred': True,
        'expected_product_cols': ['ProductName', 'Product', 'BrandName'],
        'expected_date_cols': ['Period', 'TimePeriod', 'Month']
    },
    'Reporting_BI_Nrx_SampleSummary': {
        'output': 'Nrx_Sample_Summary',
        'description': 'NRx & Sample Summary',
        'schema': 'Reporting',
        'filter_products': True,
        'filter_dates': True,
        'spark_preferred': True,
        'expected_product_cols': ['ProductName', 'Product', 'BrandName'],
        'expected_date_cols': ['Period', 'TimePeriod', 'Month']
    },
    'Reporting_BI_CallAttainment_Summary_TerritoryLevel': {
        'output': 'Call_Attainment_Territory',
        'description': 'Territory Call Attainment Summary',
        'schema': 'Reporting',
        'filter_products': False,
        'filter_dates': True,
        'spark_preferred': False,
        'expected_product_cols': [],
        'expected_date_cols': ['TimeIn', 'Period', 'TimePeriod', 'Month']
    },
    'Reporting_BI_PrescriberProfile': {
        'output': 'Prescriber_Profile',
        'description': 'Prescriber Profile level details',
        'schema': 'Reporting',
        'filter_products': True,
        'filter_dates': True,
        'spark_preferred': True,
        'expected_product_cols': ['ProductName', 'Product', 'BrandName'],
        'expected_date_cols': ['Period', 'TimePeriod', 'Month']
    },
    'Reporting_BI_Sample_LL_DTP': {
        'output': 'Territory_Samples_LL_DTP',
        'description': 'Samples & Lunch-and-Learn summary',
        'schema': 'Reporting',
        'filter_products': True,
        'filter_dates': True,
        'spark_preferred': False,
        'expected_product_cols': ['ProductName', 'Product'],
        'expected_date_cols': ['Period', 'TimePeriod', 'Month']
    },
    'Reporting_BI_CallActivity_Summary_TerritoryLevel': {
        'output': 'Call_Activity_Territory',
        'description': 'Aggregated call activity by territory',
        'schema': 'Reporting',
        'filter_products': False,
        'filter_dates': True,
        'spark_preferred': False,
        'expected_product_cols': [],
        'expected_date_cols': ['Period', 'TimePeriod', 'Month']
    },
    'Reporting_BI_CallAttainment_Summary_Tier': {
        'output': 'Call_Attainment_Tiers',
        'description': 'Call attainment by tier',
        'schema': 'Reporting',
        'filter_products': False,
        'filter_dates': True,
        'spark_preferred': False,
        'expected_product_cols': [],
        'expected_date_cols': ['Period', 'TimePeriod', 'Month']
    },
    'Reporting_Bi_Territory_CallSummary': {
        'output': 'Territory_Call_Summary',
        'description': 'Territory call summary',
        'schema': 'Reporting',
        'filter_products': False,
        'filter_dates': True,
        'spark_preferred': False,
        'expected_product_cols': [],
        'expected_date_cols': ['Period', 'TimePeriod', 'Month']
    }
}

class IBSAHybridLoader:
    """IBSA Hybrid Data Loader - Spark + Pandas"""
    
    def __init__(self, output_dir: Optional[str] = None, engine_preference: str = "auto"):
        # Database credentials
        self.server = 'odsproduction.database.windows.net'
        self.database = 'DWHPRODIBSA'
        self.username = 'odsjobsuser'
        self.password = 'DwHIBSAOD$J0bs!1'
        self.driver = '{ODBC Driver 17 for SQL Server}'
        
        # Connections
        self.spark = None
        self.connection = None
        self.tables_config = TABLE_CONFIG
        self.engine_preference = engine_preference.lower()
        if self.engine_preference not in {"auto", "spark", "pandas"}:
            raise ValueError("engine_preference must be one of: auto, spark, pandas")

        # Product filters (auto-discovered when connection available)
        self.ibsa_products: List[str] = sorted({p.upper() for p in DEFAULT_IBSA_PRODUCTS})
        self.competitor_products: List[str] = sorted({p.upper() for p in DEFAULT_COMPETITOR_PRODUCTS})
        self.all_products: List[str] = sorted({*self.ibsa_products, *self.competitor_products})
        self.ibsa_keywords: List[str] = sorted({kw.upper() for kw in DEFAULT_IBSA_KEYWORDS})
        self.product_catalog_ready: bool = False

        # Performance knobs
        self.spark_fetchsize: int = SPARK_DEFAULT_FETCHSIZE
        self.spark_partition_row_target: int = SPARK_PARTITION_ROW_TARGET
        self.spark_max_partitions: int = SPARK_MAX_PARTITIONS
        self.spark_min_partitions: int = SPARK_MIN_PARTITIONS
        self.pandas_chunk_size: int = PANDAS_CHUNK_SIZE
        self.pandas_chunk_log_every: int = PANDAS_CHUNK_LOG_EVERY
        
        # Output directory
        self.data_dir = Path(output_dir) if output_dir else Path("../data")
        self.data_dir.mkdir(exist_ok=True)
        
        logger.info("🎯 IBSA Hybrid Loader initialized")

    def setup_spark(self):
        """Setup Spark session"""
        if not SPARK_AVAILABLE:
            logger.warning("⚠️ Spark not available")
            return False

        if sys.platform.startswith("win"):
            hadoop_home = os.environ.get("HADOOP_HOME")
            if not hadoop_home:
                bundled_winutils = Path(__file__).resolve().parent.parent / "winutils"
                if bundled_winutils.exists():
                    os.environ["HADOOP_HOME"] = str(bundled_winutils)
                    logger.info("🪟 Set HADOOP_HOME to bundled winutils at %s", bundled_winutils)
                else:
                    logger.warning(
                        "⚠️ HADOOP_HOME not set on Windows. Install winutils (https://github.com/steveloughran/winutils) "
                        "and set HADOOP_HOME to the extracted directory (suggested path: %s).",
                        bundled_winutils,
                    )
                    logger.warning("ℹ️ Skipping Spark init until HADOOP_HOME is configured")
                    return False
            
        try:
            self.spark = SparkSession.builder \
                .appName("IBSA_Hybrid_Loader") \
                .master("local[*]") \
                .config("spark.ui.enabled", "false") \
                .config("spark.driver.memory", "4g") \
                .config("spark.jars.packages", "com.microsoft.sqlserver:mssql-jdbc:9.4.1.jre8") \
                .getOrCreate()
                
            self.spark.sparkContext.setLogLevel("ERROR")
            logger.info("✅ Spark session created")
            return True
        except Exception as e:
            logger.error(f"❌ Spark setup failed: {e}")
            return False

    def setup_pandas(self) -> bool:
        """Setup pandas connection backed by SQLAlchemy."""
        if not PANDAS_AVAILABLE:
            logger.warning("⚠️ Pandas not available")
            return False

        if self.connection and not self.connection.closed:
            return True

        try:
            odbc_str = (
                f"DRIVER={self.driver};"
                f"SERVER={self.server};"
                f"DATABASE={self.database};"
                f"UID={self.username};"
                f"PWD={self.password};"
                "Encrypt=yes;"
                "TrustServerCertificate=no;"
            )

            connect_args = quote_plus(odbc_str)
            engine_url = f"mssql+pyodbc:///?odbc_connect={connect_args}"

            self.engine = create_engine(engine_url, fast_executemany=True)
            self.connection = self.engine.connect()

            logger.info("✅ SQLAlchemy engine established for pandas access")
            self.refresh_product_catalog()
            return True
        except SQLAlchemyError as e:
            logger.error(f"❌ SQLAlchemy connection failed: {e}")
        except Exception as e:
            logger.error(f"❌ Pandas connection failed: {e}")

        if self.engine is not None:
            self.engine.dispose()
            self.engine = None
        self.connection = None
        return False

    def refresh_product_catalog(self, discovery_limit: int = 500) -> None:
        """Discover IBSA and competitor products dynamically from source tables."""

        if self.product_catalog_ready or not self.connection:
            return

        candidates = [
            name for name, cfg in self.tables_config.items()
            if cfg.get('filter_products')
        ]

        for table_name in candidates:
            config = self.tables_config.get(table_name, {})

            try:
                table_info = self.analyze_table(table_name, config)
            except Exception as e:
                logger.debug(f"Product discovery: analyze_table failed for {table_name}: {e}")
                continue

            qualified_name = table_info.get('qualified_name')
            if not qualified_name:
                continue

            product_columns = table_info.get('product_columns', [])
            preferred = config.get('expected_product_cols', [])
            product_column = None

            for candidate in preferred:
                if candidate in product_columns:
                    product_column = candidate
                    break

            if not product_column:
                continue

            query = text(
                f"SELECT DISTINCT TOP {discovery_limit} "
                f"UPPER(TRY_CAST([{product_column}] AS NVARCHAR(255))) AS product "
                f"FROM {qualified_name} "
                f"WHERE TRY_CAST([{product_column}] AS NVARCHAR(255)) IS NOT NULL"
            )

            try:
                df = pd.read_sql(query, self.connection)
            except Exception as e:
                logger.debug(f"Product discovery: query failed for {table_name}: {e}")
                continue

            if df.empty or 'product' not in df:
                continue

            discovered = sorted({
                value.strip().upper()
                for value in df['product'].dropna().astype(str)
                if value and value.strip()
            })

            if not discovered:
                continue

            ibsa_discovered = sorted({
                product for product in discovered
                if any(keyword in product for keyword in self.ibsa_keywords)
            })

            competitor_discovered = sorted(set(discovered) - set(ibsa_discovered))

            if ibsa_discovered:
                self.ibsa_products = ibsa_discovered
            if competitor_discovered:
                self.competitor_products = competitor_discovered

            self.all_products = sorted({*self.ibsa_products, *self.competitor_products})
            self.product_catalog_ready = True

            logger.info(
                "🔍 Product catalog discovered: %d IBSA products, %d competitor products (source: %s)",
                len(self.ibsa_products),
                len(self.competitor_products),
                table_name,
            )
            return

        self.product_catalog_ready = True
        logger.info("ℹ️ Using default product catalog (dynamic discovery unavailable)")

    def get_output_path(self, table_name: str) -> Path:
        config = self.tables_config.get(table_name, {})
        output_name = config.get('output', table_name.replace('Reporting_', ''))
        return self.data_dir / f"IBSA_{output_name}.csv"

    def _resolve_table_key(self, name: str) -> Optional[str]:
        normalized = name.lower()
        for table_key, config in self.tables_config.items():
            if table_key.lower() == normalized:
                return table_key
            if config.get('output', '').lower() == normalized:
                return table_key
        logger.warning(f"⚠️ Unknown table identifier '{name}' - skipping")
        return None

    def resolve_tables(self, selection: Optional[List[str]] = None, retry_missing: bool = False) -> List[str]:
        if selection:
            resolved = [self._resolve_table_key(name) for name in selection]
            resolved = [name for name in resolved if name]
        else:
            resolved = list(self.tables_config.keys())

        if retry_missing:
            resolved = [name for name in resolved if not self.get_output_path(name).exists()]

        return resolved

    def discover_table_schema(self, raw_table_name: str) -> Optional[str]:
        if not self.connection:
            return None

        for base_query in (
            text(
                """
                SELECT TOP 1 s.name AS schema_name
                FROM sys.tables t
                JOIN sys.schemas s ON t.schema_id = s.schema_id
                WHERE t.name = :table_name
                ORDER BY t.create_date DESC
                """
            ),
            text(
                """
                SELECT TOP 1 s.name AS schema_name
                FROM sys.views v
                JOIN sys.schemas s ON v.schema_id = s.schema_id
                WHERE v.name = :table_name
                ORDER BY v.create_date DESC
                """
            ),
            text(
                """
                SELECT TOP 1 s.name AS schema_name
                FROM sys.synonyms sy
                JOIN sys.schemas s ON sy.schema_id = s.schema_id
                WHERE sy.name = :table_name
                ORDER BY sy.create_date DESC
                """
            ),
            text(
                """
                SELECT TOP 1 s.name AS schema_name
                FROM sys.objects o
                JOIN sys.schemas s ON o.schema_id = s.schema_id
                WHERE o.name = :table_name
                ORDER BY o.create_date DESC
                """
            ),
        ):
            result = self.connection.execute(base_query, {"table_name": raw_table_name}).fetchone()
            if result and result[0]:
                return result[0]
        return None

    def analyze_table(self, table_name: str, table_config: Optional[Dict] = None) -> Dict:
        """Analyze table structure using INFORMATION_SCHEMA metadata and lightweight sampling"""
        if not self.connection:
            return {}

        config = table_config or self.tables_config.get(table_name, {})

        raw_table_name = table_name
        initial_schema = config.get('schema')
        if '.' in table_name:
            parts = table_name.split('.', 1)
            initial_schema, raw_table_name = parts[0], parts[1]

        candidate_schemas: List[str] = []
        if initial_schema:
            candidate_schemas.append(initial_schema)

        discovered_schema = self.discover_table_schema(raw_table_name)
        if discovered_schema:
            candidate_schemas.append(discovered_schema)

        candidate_schemas.extend(['Reporting', 'dbo'])

        schema_name = None
        qualified_name = None
        object_id_target = None

        for candidate in dict.fromkeys([c for c in candidate_schemas if c]):
            test_qualified = f"[{candidate}].[{raw_table_name}]"
            try:
                # Lightweight existence check
                self.connection.execute(text(f"SELECT 1 FROM {test_qualified} WHERE 1 = 0"))
                schema_name = candidate
                qualified_name = test_qualified
                object_id_target = f"{candidate}.{raw_table_name}"
                break
            except Exception as exc:
                logger.debug(f"Schema candidate '{candidate}' invalid for {table_name}: {exc}")
                continue

        if not schema_name:
            logger.error(f"❌ Unable to resolve schema for {table_name}")
            return {}

        try:
            schema_query = text(
                """
                SELECT COLUMN_NAME, DATA_TYPE
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = :schema AND TABLE_NAME = :table
                ORDER BY ORDINAL_POSITION
                """
            )
            schema_df = pd.read_sql(
                schema_query,
                self.connection,
                params={"schema": schema_name, "table": raw_table_name},
            )

            if schema_df.empty:
                discovered_schema = self.discover_table_schema(raw_table_name)
                if discovered_schema and discovered_schema.lower() != schema_name.lower():
                    logger.info(
                        "   ℹ️ Auto-detected schema '%s' for %s",
                        discovered_schema,
                        table_name,
                    )
                    schema_name = discovered_schema
                    qualified_name = f"[{schema_name}].[{raw_table_name}]"
                    object_id_target = f"{schema_name}.{raw_table_name}"
                    schema_df = pd.read_sql(
                        schema_query,
                        self.connection,
                        params={"schema": schema_name, "table": raw_table_name},
                    )

            if schema_df.empty:
                sys_columns_query = text(
                    """
                    SELECT c.name AS column_name, t.name AS data_type
                    FROM sys.columns c
                    JOIN sys.types t ON c.user_type_id = t.user_type_id
                    WHERE c.object_id = OBJECT_ID(:qualified)
                    ORDER BY c.column_id
                    """
                )
                sys_columns_df = pd.read_sql(
                    sys_columns_query,
                    self.connection,
                    params={"qualified": object_id_target},
                )

                if not sys_columns_df.empty:
                    sys_columns_df = sys_columns_df.rename(
                        columns={"column_name": "COLUMN_NAME", "data_type": "DATA_TYPE"}
                    )
                    schema_df = sys_columns_df

            if schema_df.empty:
                try:
                    preview_df = pd.read_sql(text(f"SELECT TOP 0 * FROM {qualified_name}"), self.connection)
                    if len(preview_df.columns) > 0:
                        schema_df = pd.DataFrame({
                            "COLUMN_NAME": preview_df.columns,
                            "DATA_TYPE": [str(preview_df[col].dtype) for col in preview_df.columns],
                        })
                except Exception as preview_err:
                    logger.debug(f"Preview metadata fetch failed for {table_name}: {preview_err}")

            metadata_available = True
            if schema_df.empty:
                metadata_available = False
                logger.warning(f"⚠️ No metadata discovered for {table_name}; proceeding with limited introspection")
                schema_df = pd.DataFrame(columns=["COLUMN_NAME", "DATA_TYPE"])

            column_types = {row.COLUMN_NAME: row.DATA_TYPE.lower() for row in schema_df.itertuples()}
            text_like_types = {'varchar', 'nvarchar', 'char', 'nchar', 'text', 'ntext'}
            date_like_types = {'date', 'datetime', 'datetime2', 'smalldatetime', 'time'}
            numeric_types = {'int', 'bigint', 'smallint', 'tinyint', 'decimal', 'numeric', 'float', 'real', 'money', 'smallmoney'}
            integer_types = {'int', 'bigint', 'smallint', 'tinyint'}

            row_count = None
            try:
                row_count_query = text(
                    """
                    SELECT SUM(p.rows) AS row_count
                    FROM sys.objects o
                    JOIN sys.partitions p ON o.object_id = p.object_id
                    WHERE o.object_id = OBJECT_ID(:qualified) AND p.index_id IN (0,1)
                    """
                )
                row_df = pd.read_sql(
                    row_count_query,
                    self.connection,
                    params={"qualified": object_id_target},
                )
                if not row_df.empty:
                    raw_count = row_df.iloc[0]['row_count']
                    if pd.notna(raw_count):
                        row_count = int(raw_count)
            except Exception as row_err:
                logger.debug(f"Row count lookup failed for {table_name}: {row_err}")

            # Light sample (optional) to refine heuristics
            sample_columns = list(column_types.keys())
            sample_df = pd.DataFrame()
            sample_query = text(f"SELECT TOP 10 * FROM {qualified_name}")
            try:
                sample_df = pd.read_sql(sample_query, self.connection)
            except Exception:
                # Sampling failure shouldn't block loading
                pass

            def _matches_any(column_name: str, keywords: List[str]) -> bool:
                lower_name = column_name.lower()
                return any(keyword in lower_name for keyword in keywords)

            product_candidates = []
            date_candidates = []
            for col in sample_columns:
                dtype = column_types.get(col, '').lower()
                if _matches_any(col, ['product', 'brand', 'drug', 'ndc']) or dtype in text_like_types:
                    product_candidates.append(col)
                if dtype in date_like_types or _matches_any(col, ['date', 'month', 'year', 'period', 'time']):
                    date_candidates.append(col)

            partition_column: Optional[str] = None
            partition_bounds: Optional[Tuple[float, float]] = None

            partition_candidates = [col for col in sample_columns if column_types.get(col, '').lower() in integer_types]

            for candidate in partition_candidates:
                bounds_query = text(
                    f"SELECT MIN([{candidate}]) AS min_value, MAX([{candidate}]) AS max_value "
                    f"FROM {qualified_name} WHERE [{candidate}] IS NOT NULL"
                )
                try:
                    bounds_df = pd.read_sql(bounds_query, self.connection)
                except Exception as bounds_err:
                    logger.debug(f"Partition bounds lookup failed for {table_name}.{candidate}: {bounds_err}")
                    continue

                if bounds_df.empty:
                    continue

                min_value = bounds_df.iloc[0]['min_value']
                max_value = bounds_df.iloc[0]['max_value']

                if pd.isna(min_value) or pd.isna(max_value):
                    continue

                if float(min_value) == float(max_value):
                    continue

                partition_column = candidate
                partition_bounds = (float(min_value), float(max_value))
                break

            return {
                'columns': sample_columns,
                'column_types': column_types,
                'product_columns': product_candidates,
                'date_columns': date_candidates,
                'numeric_columns': [col for col, dtype in column_types.items() if dtype in numeric_types],
                'sample': sample_df,
                'row_count': row_count,
                'partition_column': partition_column,
                'partition_bounds': partition_bounds,
                'schema': schema_name,
                'raw_table_name': raw_table_name,
                'qualified_name': qualified_name,
                'object_id': object_id_target,
                'metadata_available': metadata_available,
            }
        except Exception as e:
            logger.error(f"Error analyzing {table_name}: {e}")
            return {}

    def build_filter_clauses(self, table_name: str, table_info: Dict, table_config: Dict) -> List[str]:
        """Return a list of WHERE clauses (from most selective to broad)"""
        clauses: List[str] = []

        column_types = table_info.get('column_types', {})

        def pick_first(existing: List[str], preferred: List[str]) -> Optional[str]:
            if preferred:
                for candidate in preferred:
                    if candidate in existing:
                        return candidate
            return existing[0] if existing else None

        product_clause: Optional[str] = None
        if table_config.get('filter_products') and self.all_products:
            product_columns = table_info.get('product_columns', [])
            preferred_products = table_config.get('expected_product_cols', [])
            product_column = pick_first(product_columns, preferred_products)

            if product_column:
                product_dtype = column_types.get(product_column, '')
                preferred_match = product_column in preferred_products
                keyword_match = any(token in product_column.lower() for token in ['product', 'brand', 'drug', 'ndc', 'sku'])
                if not preferred_match and not keyword_match:
                    logger.info(
                        "   ⚠️ Product filter skipped for %s (candidate '%s' deemed non-product column)",
                        table_name,
                        product_column,
                    )
                    product_column = None

            if product_column:
                product_dtype = column_types.get(product_column, '')
                if product_dtype in {'ntext', 'text'}:
                    expression = f"TRY_CAST([{product_column}] AS NVARCHAR(4000))"
                else:
                    expression = f"TRY_CAST([{product_column}] AS NVARCHAR(255))"

                product_conditions = []
                for prod in self.all_products:
                    safe_prod = prod.replace("'", "''")
                    product_conditions.append(
                        f"UPPER({expression}) LIKE '%{safe_prod}%'"
                    )
                product_clause = f"({' OR '.join(product_conditions)})"
            else:
                logger.info(f"   ⚠️ No product column identified for {table_name}; skipping product filter")

        date_clause: Optional[str] = None
        if table_config.get('filter_dates'):
            date_columns = table_info.get('date_columns', [])
            preferred_dates = table_config.get('expected_date_cols', [])
            date_column = pick_first(date_columns, preferred_dates)

            if date_column:
                date_dtype = column_types.get(date_column, '')
                if date_dtype in {'date', 'datetime', 'datetime2', 'smalldatetime'}:
                    cast_expr = f"TRY_CAST([{date_column}] AS DATE)"
                elif date_dtype in {'varchar', 'nvarchar', 'char', 'nchar'}:
                    cast_expr = f"TRY_CAST([{date_column}] AS DATE)"
                else:
                    # Numeric or unsupported type - skip date filtering
                    cast_expr = None
                    logger.info(f"   ⚠️ Date filter skipped for [{date_column}] (type: {date_dtype})")

                if cast_expr:
                    period_expr = f"FORMAT(DATEADD(year, -1, GETDATE()), 'yyyyMM')"
                    fallback_expr = f"TRY_CAST([{date_column}] AS NVARCHAR(10))"
                    date_clause = (
                        f"(({cast_expr} >= DATEADD(year, -1, GETDATE())) "
                        f"OR ({fallback_expr} >= {period_expr}))"
                    )
            else:
                logger.info(f"   ⚠️ No date column identified for {table_name}; skipping date filter")

        candidate_clauses: List[Tuple[str, ...]] = []
        if product_clause and date_clause:
            candidate_clauses.append((product_clause, date_clause))
        if product_clause:
            candidate_clauses.append((product_clause,))
        if date_clause:
            candidate_clauses.append((date_clause,))

        # Always include final "no filter" fallback
        candidate_clauses.append(tuple())

        seen = set()
        for combo in candidate_clauses:
            where_clause = " AND ".join(combo)
            normalized = where_clause.strip()
            if normalized in seen:
                continue
            seen.add(normalized)
            if normalized:
                clauses.append(f" WHERE {normalized}")
            else:
                clauses.append("")

        return clauses

    def load_with_spark(
        self,
        query: str,
        output_name: str,
        partition_column: Optional[str] = None,
        lower_bound: Optional[float] = None,
        upper_bound: Optional[float] = None,
        num_partitions: Optional[int] = None,
    ) -> bool:
        """Load using Spark with optional partitioned JDBC reads."""
        try:
            jdbc_url = f"jdbc:sqlserver://{self.server}:1433;databaseName={self.database}"

            reader = self.spark.read.format("jdbc") \
                .option("url", jdbc_url) \
                .option("dbtable", f"({query}) AS filtered_data") \
                .option("user", self.username) \
                .option("password", self.password) \
                .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver") \
                .option("fetchsize", self.spark_fetchsize)

            if (
                partition_column
                and lower_bound is not None
                and upper_bound is not None
                and num_partitions
                and num_partitions > 1
            ):
                reader = reader.option("partitionColumn", partition_column) \
                    .option("lowerBound", int(lower_bound)) \
                    .option("upperBound", int(upper_bound)) \
                    .option("numPartitions", int(num_partitions))
                logger.info(
                    "   🪵 Spark JDBC partitioning enabled (col=%s, bounds=%s-%s, partitions=%s)",
                    partition_column,
                    int(lower_bound),
                    int(upper_bound),
                    int(num_partitions),
                )

            df = reader.load()
            
            count = df.count()
            if count == 0:
                logger.warning("No data returned")
                return False
            
            # Save as CSV
            temp_path = self.data_dir / f"temp_{output_name}"
            df.coalesce(1).write.mode("overwrite").option("header", "true").csv(str(temp_path))
            
            # Move to final location
            csv_files = list(temp_path.glob("part-*.csv"))
            if csv_files:
                final_csv = self.data_dir / f"IBSA_{output_name}.csv"
                csv_files[0].rename(final_csv)
                
                import shutil
                shutil.rmtree(temp_path)
                
                size_mb = final_csv.stat().st_size / (1024*1024)
                logger.info(f"✅ Spark: {count:,} rows ({size_mb:.1f} MB)")
                return True
            logger.error("Spark write completed but output file not found")
            return False

        except Exception as e:
            logger.error(f"Spark loading failed: {e}")
            return False

    def load_with_pandas(self, query: str, output_name: str, row_count: Optional[int] = None) -> bool:
        """Load using pandas with optional chunked streaming."""
        try:
            output_file = self.data_dir / f"IBSA_{output_name}.csv"
            temp_file = output_file.with_suffix(output_file.suffix + ".tmp")

            if temp_file.exists():
                temp_file.unlink()

            use_chunks = self.pandas_chunk_size and (
                row_count is None or row_count > self.pandas_chunk_size
            )

            total_rows = 0
            chunk_count = 0

            if use_chunks:
                logger.info(
                    "   🪵 Pandas chunking enabled (chunksize=%s rows)",
                    self.pandas_chunk_size,
                )
                chunk_iter = pd.read_sql(query, self.connection, chunksize=self.pandas_chunk_size)
                for chunk_index, chunk in enumerate(chunk_iter, start=1):
                    if chunk.empty:
                        continue
                    mode = 'w' if chunk_index == 1 else 'a'
                    header = chunk_index == 1
                    chunk.to_csv(temp_file, mode=mode, header=header, index=False)
                    total_rows += len(chunk)
                    chunk_count += 1
                    if (
                        chunk_index == 1
                        or chunk_index % self.pandas_chunk_log_every == 0
                    ):
                        logger.info(
                            "      • Chunk %s written (%s rows, total %s)",
                            chunk_index,
                            len(chunk),
                            total_rows,
                        )

            else:
                df = pd.read_sql(query, self.connection)
                if df.empty:
                    logger.warning("No data returned")
                    return False
                df.to_csv(temp_file, index=False)
                total_rows = len(df)
                chunk_count = 1

            if total_rows == 0:
                if temp_file.exists():
                    try:
                        temp_file.unlink()
                    except FileNotFoundError:
                        pass
                logger.warning("No data returned")
                return False

            if output_file.exists():
                output_file.unlink()
            temp_file.rename(output_file)

            size_mb = output_file.stat().st_size / (1024 * 1024)
            logger.info(
                "✅ Pandas: %s rows (%0.1f MB) across %s chunk(s)",
                f"{total_rows:,}",
                size_mb,
                chunk_count,
            )
            return True

        except Exception as e:
            logger.error(f"Pandas loading failed: {e}")
            try:
                if 'temp_file' in locals() and temp_file.exists():
                    temp_file.unlink()
            except FileNotFoundError:
                pass
            return False

    def load_table(self, table_name: str, output_name: str, engine_override: Optional[str] = None) -> bool:
        """Load single table using hybrid approach with staged fallbacks"""
        logger.info(f"\n🔄 Loading {table_name}...")

        table_config = self.tables_config.get(table_name, {
            'output': output_name,
            'filter_products': True,
            'filter_dates': True,
            'expected_product_cols': [],
            'expected_date_cols': [],
            'spark_preferred': True
        })

        table_info = self.analyze_table(table_name, table_config)
        if not table_info:
            logger.error(f"Cannot analyze {table_name}")
            return False

        logger.info(f"📋 Found {len(table_info['columns'])} columns")

        base_query = f"SELECT * FROM {table_info['qualified_name']}"
        filter_clauses = self.build_filter_clauses(table_name, table_info, table_config)

        spark_allowed = self.spark is not None
        pandas_allowed = self.connection is not None

        effective_engine = (engine_override or self.engine_preference or "auto").lower()

        heavy_table = False
        row_count = table_info.get('row_count')
        if row_count:
            heavy_table = row_count >= SPARK_ROW_COUNT_THRESHOLD
            logger.info(f"   ℹ️ Estimated row count: {row_count:,}")
            if heavy_table and spark_allowed:
                logger.info(f"   🚚 Row count exceeds {SPARK_ROW_COUNT_THRESHOLD:,}; prioritising Spark")

        prefer_spark = table_config.get('spark_preferred', False) or heavy_table
        if prefer_spark and not heavy_table and spark_allowed:
            logger.info("   ✅ Spark preferred via table configuration")

        partition_column = table_info.get('partition_column')
        lower_bound: Optional[float] = None
        upper_bound: Optional[float] = None
        spark_partitions: Optional[int] = None

        partition_bounds = table_info.get('partition_bounds')
        if partition_bounds:
            lower_bound, upper_bound = partition_bounds

        if partition_column and lower_bound is not None and upper_bound is not None:
            logger.info(
                "   🔢 Partition candidate: %s (min=%s, max=%s)",
                partition_column,
                int(lower_bound),
                int(upper_bound),
            )

        if row_count and row_count > 0 and spark_allowed:
            raw_partitions = math.ceil(row_count / self.spark_partition_row_target) if self.spark_partition_row_target else 0
            if raw_partitions > 1:
                spark_partitions = max(self.spark_min_partitions, min(self.spark_max_partitions, raw_partitions))

        if spark_partitions and not partition_column:
            # Without a partition column we can't parallelise; reset to None
            spark_partitions = None
        elif spark_partitions:
            logger.info("   🧩 Target Spark partitions: %s", spark_partitions)

        def build_engine_sequence() -> List[str]:
            if effective_engine == "spark":
                return [engine for engine in ("spark", "pandas") if (engine == "spark" and spark_allowed) or (engine == "pandas" and pandas_allowed)]
            if effective_engine == "pandas":
                return ["pandas"] if pandas_allowed else []
            sequence: List[str] = []
            if spark_allowed and prefer_spark:
                sequence.append("spark")
            if pandas_allowed:
                sequence.append("pandas")
            if spark_allowed and "spark" not in sequence:
                sequence.append("spark")
            return sequence

        engine_sequence = build_engine_sequence()
        if not engine_sequence:
            logger.error("❌ No valid engines available for loading this table")
            return False
        logger.info(f"   ⚙️ Engine order: {engine_sequence}")

        for attempt, clause in enumerate(filter_clauses, start=1):
            full_query = base_query + clause
            clause_description = clause.strip() or "no filters"
            logger.info(f"   ▶️ Attempt {attempt}: {clause_description or 'no filters'}")

            for engine in engine_sequence:
                if engine == "spark":
                    logger.info("🚀 Trying Spark load")
                    success = self.load_with_spark(
                        full_query,
                        output_name,
                        partition_column=partition_column,
                        lower_bound=lower_bound,
                        upper_bound=upper_bound,
                        num_partitions=spark_partitions,
                    )
                elif engine == "pandas":
                    logger.info("🐼 Trying pandas load")
                    success = self.load_with_pandas(
                        full_query,
                        output_name,
                        row_count=row_count,
                    )
                else:
                    logger.error(f"Unknown engine '{engine}'")
                    success = False

                if success:
                    return True

                logger.warning(f"   ↻ {engine} failed for clause; evaluating next engine")

            logger.warning(f"   ↻ Attempt {attempt} exhausted all engines, moving to next filter clause")

        logger.error(f"❌ All attempts failed for {table_name}")
        return False

    def load_all_tables(
        self,
        tables: Optional[List[str]] = None,
        force: bool = False,
        retry_missing: bool = False,
        engine: Optional[str] = None
    ) -> Dict[str, str]:
        """Load IBSA tables with optional targeting and retry semantics.

        Returns a dict mapping table name to status: 'success', 'failed', or 'skipped'.
        Engine preference can be controlled globally via the CLI/constructor or per call.
        """

        logger.info("🚀 Starting IBSA Hybrid Data Loading")

        spark_ready = self.setup_spark()
        pandas_ready = self.setup_pandas()

        if not pandas_ready:
            logger.error("❌ Pandas connection required for metadata analysis - aborting")
            return {}

        if not spark_ready:
            logger.info("ℹ️ Proceeding without Spark; pandas-only mode")

        targets = self.resolve_tables(tables, retry_missing=retry_missing)

        if not targets:
            if retry_missing:
                logger.info("✅ No missing tables detected - nothing to retry")
            else:
                logger.warning("⚠️ No tables resolved to load")
            return {}

        statuses: Dict[str, str] = {}

        try:
            for table_name in targets:
                output_path = self.get_output_path(table_name)
                output_name = self.tables_config.get(table_name, {}).get('output', table_name)

                if output_path.exists() and not force and not retry_missing:
                    logger.info(f"⏭️  Skipping {table_name} (output already exists). Use --force to reload.")
                    statuses[table_name] = 'skipped'
                    continue

                success = self.load_table(table_name, output_name, engine_override=engine)
                statuses[table_name] = 'success' if success else 'failed'

        finally:
            if self.spark:
                self.spark.stop()
                logger.info("🔌 Spark stopped")
            if self.connection:
                try:
                    self.connection.close()
                finally:
                    logger.info("🔌 Connection closed")
                self.connection = None
            if self.engine:
                self.engine.dispose()
                self.engine = None
                logger.info("🧹 SQLAlchemy engine disposed")

        total = len(targets)
        successes = sum(1 for status in statuses.values() if status == 'success')
        failures = [name for name, status in statuses.items() if status == 'failed']

        logger.info(f"\n📊 Loading Summary: {successes}/{total} tables loaded successfully")
        if failures:
            logger.error(f"❌ Failed tables: {', '.join(failures)}")
        else:
            logger.info("🎉 All requested tables processed successfully")

        return statuses

def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="IBSA hybrid Spark+pandas data loader",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "-t",
        "--table",
        dest="tables",
        action="append",
        help="Table name or output alias to load (can be used multiple times). Defaults to all tables."
    )
    parser.add_argument(
        "--retry-missing",
        action="store_true",
        help="Only load tables whose output CSV is missing"
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Force reload even if output CSV already exists"
    )
    parser.add_argument(
        "--output-dir",
        default=None,
        help="Custom directory for exported CSV files"
    )
    parser.add_argument(
        "--engine",
        choices=["auto", "spark", "pandas"],
        default="auto",
        help="Engine preference for loading (auto chooses Spark for heavy tables when available)"
    )
    return parser.parse_args(argv)


def main(argv: Optional[List[str]] = None) -> bool:
    """Main entry point"""
    args = parse_args(argv)

    loader = IBSAHybridLoader(output_dir=args.output_dir, engine_preference=args.engine)

    statuses = loader.load_all_tables(
        tables=args.tables,
        force=args.force,
        retry_missing=args.retry_missing,
        engine=args.engine
    )

    failed = [name for name, status in statuses.items() if status == 'failed']
    success = len(failed) == 0

    if success:
        print("\n🎉 IBSA data loading completed!")
        print(f"📁 Files in: {loader.data_dir.absolute()}")
        print("🚀 Ready for EDA with: python scripts/ibsa_eda_main.py")
    else:
        print("\n❌ Loading finished with failures - see log for details")
        for name in failed:
            print(f"   • {name}")

    return success

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)