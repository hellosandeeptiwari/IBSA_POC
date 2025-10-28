#!/usr/bin/env python3
"""
IBSA Spark Data Loader - Simple & Direct
"""
import os, sys
from pathlib import Path

# Setup Spark
os.environ["SPARK_LOCAL_IP"] = "127.0.0.1"
os.environ["PYSPARK_PYTHON"] = sys.executable 
os.environ["PYSPARK_DRIVER_PYTHON"] = sys.executable

try:
    import findspark
    findspark.init()
except: 
    pass

from pyspark.sql import SparkSession

def main():
    # Database details
    server = "odsproduction.database.windows.net"
    database = "DWHPRODIBSA"
    username = "odsjobsuser"
    password = "DwHIBSAOD$J0bs!1"
    jdbc_url = f"jdbc:sqlserver://{server}:1433;databaseName={database}"

    # Setup Spark
    print("🚀 Setting up Spark...")
    spark = SparkSession.builder \
        .appName("IBSA_Loader") \
        .master("local[*]") \
        .config("spark.jars.packages", "com.microsoft.sqlserver:mssql-jdbc:9.4.1.jre8") \
        .config("spark.ui.enabled", "false") \
        .getOrCreate()
    
    spark.sparkContext.setLogLevel("ERROR")

    # IBSA Products
    products = ["Tirosint Caps", "Tirosint Sol", "Tirosint AG", "Flector", "Licart", "Synthroid", "Levoxyl", "Voltaren"]
    product_filter = " OR ".join([f"UPPER(ProductName) LIKE '%{p.upper()}%'" for p in products])

    # Tables to load
    tables = {
        "Reporting_BI_CallActivity": "Call_Activity",
        "Reporting_BI_PrescriberOverview": "Prescriber_Overview",
        "Reporting_BI_TerritoryPerformanceOverview": "Territory_Performance", 
        "Reporting_Live_HCP_Universe": "HCP_Universe",
        "Reporting_BI_NGD": "NGD_Analysis",
        "Reporting_BI_Trx_SampleSummary": "Trx_Samples",
        "Reporting_BI_Nrx_SampleSummary": "Nrx_Samples"
    }

    data_dir = Path("../data")
    data_dir.mkdir(exist_ok=True)

    print(f"📊 Loading {len(tables)} IBSA tables...")

    success_count = 0
    for table, name in tables.items():
        try:
            print(f"\n🔄 Loading {table}...")
            
            # Smart query - apply product filter only to relevant tables
            if any(term in table.upper() for term in ["HCP", "TERRITORY"]) and "PERFORMANCE" not in table.upper():
                query = f"(SELECT * FROM [{table}]) AS data"
                print("   📋 Loading all records (no product filter)")
            else:
                query = f"(SELECT * FROM [{table}] WHERE {product_filter}) AS data"
                print("   🎯 Applying IBSA product filter")
            
            df = spark.read.format("jdbc") \
                .option("url", jdbc_url) \
                .option("dbtable", query) \
                .option("user", username) \
                .option("password", password) \
                .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver") \
                .load()
            
            count = df.count()
            if count > 0:
                # Save as CSV
                temp_path = data_dir / f"temp_{name}"
                df.coalesce(1).write.mode("overwrite").option("header", "true").csv(str(temp_path))
                
                # Find the generated CSV file and rename it
                csv_files = list(temp_path.glob("part-*.csv"))
                if csv_files:
                    final_csv = data_dir / f"IBSA_{name}.csv"
                    csv_files[0].rename(final_csv)
                    
                    # Clean up temp directory
                    import shutil
                    shutil.rmtree(temp_path)
                    
                    size_mb = final_csv.stat().st_size / (1024*1024)
                    print(f"   ✅ Success: {count:,} rows × {len(df.columns)} columns ({size_mb:.1f} MB)")
                    success_count += 1
                else:
                    print(f"   ❌ Failed to create CSV file")
            else:
                print(f"   ⚠️ No data returned")
                
        except Exception as e:
            print(f"   ❌ Error: {e}")

    spark.stop()
    print(f"\n🎉 Complete! Successfully loaded {success_count}/{len(tables)} tables")
    return success_count

if __name__ == "__main__":
    main()