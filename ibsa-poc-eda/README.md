# IBSA Pharmaceutical ML Pipeline

🏥 **Production-ready Machine Learning pipeline for pharmaceutical sales analytics and prescriber intelligence**

A comprehensive, scalable solution for IBSA pharmaceutical data analysis, featuring automated EDA, feature engineering, and ML model training using Apache Spark.

## 🚀 **Quick Start**

### Prerequisites
- Python 3.8+
- Apache Spark 3.4+
- Java 8 or 11

### Installation

```bash
# Clone and install
git clone <repository-url>
cd ibsa-poc-eda
pip install -e .

# Install development dependencies (optional)
pip install -e ".[dev]"
```

### Basic Usage

```bash
# Run complete pipeline
ibsa-pipeline run-pipeline --data-path ../data --output ./results --target conversion_rate

# Or run individual steps
ibsa-pipeline eda --data-path ../data --output ./eda-results
ibsa-pipeline features --input ./eda-results --output ./features
ibsa-pipeline model --input ./features --output ./models
```

```bash
# Pull fresh source data with Spark-first hybrid loader (auto-detects heavy tables)
python scripts/ibsa_hybrid_loader.py --engine auto --output-dir ./data
```

## 📊 **Features**

### ✅ **Comprehensive EDA**
- **Automated Data Discovery**: Finds and loads all IBSA reporting tables
- **Pharmaceutical Intelligence**: HCP patterns, territory analysis, prescriber profiling
- **Data Quality Assessment**: Missing values, duplicates, outliers
- **Relationship Detection**: Automatic PK/FK identification
- **Interactive Visualizations**: Spark-optimized charts and reports

### ✅ **Production-Ready Architecture**
- **Spark-Based**: Handles large datasets without memory issues
- **Hybrid Chunked Loader**: JDBC partitioning + pandas streaming keeps downloads fast even for huge tables
- **Modular Design**: Reusable components for EDA, features, models
- **CLI Interface**: Easy command-line operations
- **Configuration Management**: YAML-based settings
- **Comprehensive Testing**: Unit and integration tests

### ✅ **Pharmaceutical Domain Expertise**
- **HCP Segmentation**: Tier-based prescriber classification
- **Territory Optimization**: Geographic performance analysis
- **Market Intelligence**: Competitive landscape insights
- **Pre-call Planning**: Sales optimization features
- **Automatic Competitor Discovery**: Dynamically identifies non-IBSA brands from source systems

## 🗂️ **Project Structure**

```
ibsa-poc-eda/
├── src/ibsa_pipeline/           # Main package
│   ├── data/                    # Data loading and processing
│   │   └── loaders.py          # DataLoader with relationship detection
│   ├── eda/                     # Exploratory Data Analysis
│   │   └── analyzer.py         # EDAAnalyzer with pharma insights
│   ├── features/                # Feature engineering
│   ├── models/                  # ML model training
│   ├── config/                  # Configuration management
│   └── utils/                   # Utilities (Spark session, helpers)
├── cli/                         # Command-line interface
├── notebooks/                   # Jupyter notebooks for exploration
├── tests/                       # Test suites
├── config/                      # Configuration files
├── docs/                        # Documentation
└── pyproject.toml              # Package configuration
```

## 📋 **IBSA Reporting Tables**

The pipeline automatically processes all IBSA reporting tables:

### 📞 **Call & Activity Tables**
- `Reporting_BI_CallActivity` - Call Activity Overview
- `Reporting_BI_CallAttainment_Summary_TerritoryLevel` - Territory Call Attainment
- `Reporting_Bi_Territory_CallSummary` - Territory Calls Summary
- `Reporting_BI_CallAttainment_Summary_Tier` - Call Attainment by Tiers

### 💊 **Prescription & Sample Tables**
- `Reporting_BI_Trx_SampleSummary` - Samples/Trx Summary
- `Reporting_BI_Nrx_SampleSummary` - Samples/Nrx Summary
- `Reporting_BI_Sample_LL_DTP` - Territory Samples and L&L Summary

### 👨‍⚕️ **HCP Intelligence Tables**
- `Reporting_Live_HCP_Universe` - Complete HCP Universe (Live)
- `Reporting_BI_PrescriberProfile` - Prescriber Profiles
- `Reporting_BI_PrescriberOverview` - Prescriber Overview
- `Reporting_BI_PrescriberPaymentPlanSummary` - Payment Plans

### 🏆 **Performance Tables**
- `Reporting_BI_TerritoryPerformanceSummary` - Territory Performance
- `Reporting_BI_TerritoryPerformanceOverview` - Performance Overview
- `Reporting_BI_NGD` - New/Growth/Decliner Analysis

## 🔧 **Configuration**

Edit `config/config.yaml` for your environment:

```yaml
spark:
  driver_memory: "4g"
  executor_memory: "4g"
  
database:
  host: "your-db-host"
  database: "ibsa_pharma"
  username: "your-username"
  
pharmaceutical:
  hcp_segments: ["Tier 1", "Tier 2", "Tier 3"]
  territory_types: ["Primary Care", "Specialty"]
```

## 📊 **Usage Examples**

### 1. **Complete EDA Analysis**

```bash
# Analyze all data with automatic template creation
ibsa-pipeline eda --data-path ../data --output ./results --create-templates

# View results
cat ./results/eda_report.md
```

### 2. **Relationship Analysis**

```python
from ibsa_pipeline import DataLoader

loader = DataLoader()
tables = loader.load_csv_data("../data")
relationships = loader.analyze_relationships()
print(relationships)
```

### 3. **Pharmaceutical Intelligence**

```python
from ibsa_pipeline import EDAAnalyzer

analyzer = EDAAnalyzer(spark)
analysis = analyzer.analyze_dataset(hcp_data, "hcp_universe")
print(analysis["pharmaceutical_insights"])
```

## 🧪 **Testing**

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=ibsa_pipeline

# Run specific test categories
pytest -m "not slow"          # Skip slow tests
pytest -m "spark"             # Run Spark tests only
pytest tests/integration/     # Integration tests only
```

## 📈 **Performance**

- **Memory Efficient**: Spark-based processing prevents OOM errors
- **Scalable**: Handles datasets from MB to TB scale
- **Optimized**: Adaptive query execution and Arrow integration
- **Cached**: Smart caching of frequently accessed data

## 🔄 **Development Workflow**

1. **EDA Phase**: Explore data, understand relationships
2. **Feature Engineering**: Create ML-ready features
3. **Model Development**: Train and evaluate models
4. **Production**: Deploy pipeline for regular execution

## 🤝 **Contributing**

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 **Support**

- **Documentation**: See `/docs` directory
- **Issues**: GitHub Issues
- **Email**: analytics@ibsa.com

---

**Built with ❤️ for IBSA Pharmaceutical Analytics Team**