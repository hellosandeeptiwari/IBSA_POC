# 🎯 IBSA Pre-Call Planning & Predictive Analytics Framework

## Overview

Comprehensive end-to-end analytics and machine learning framework for IBSA's sales operations, aligned with:
- **Quarterly Business Summary 7.2025 v3**
- **ODIA Precall Plan Veeva Integration**
- Executive presentation requirements

## 📊 Framework Components

### 1. **Pre-Call Planning Engine** (`precall_planning_engine.py`)
Core module for HCP targeting and call planning optimization.

**Key Features:**
- ✅ HCP Segmentation (Platinum/Gold/Silver/Bronze tiers)
- ✅ Whitespace Opportunity Identification
- ✅ HCP Potential Scoring
- ✅ Optimal Call Frequency Calculation
- ✅ Veeva CRM-Ready Output Format

**Classes:**
- `DataLoader`: Load all reporting tables from SQL exports
- `HCPTargetingEngine`: Segment and prioritize HCPs
- `CallPlanningEngine`: Generate optimized call plans

### 2. **Advanced Feature Engineering** (`features/feature_engineering_advanced.py`)
Comprehensive feature engineering for predictive modeling.

**Feature Categories** (100+ features):
1. **Demographic Features**
   - Specialty encoding (target vs non-target)
   - Geographic clustering (region, urban/rural)
   - Market size indicators

2. **Behavioral Features**
   - Prescribing volume and patterns
   - Product diversity scores
   - IBSA vs competitor prescribing
   - New patient acquisition rates

3. **Temporal Features**
   - Days since last call
   - Call frequency patterns
   - Seasonality indicators
   - Recency/stale call flags

4. **Engagement Features**
   - Sample acceptance rates
   - Call type diversity
   - Engagement composite score
   - Response patterns

5. **Competitive Features**
   - Competitor product usage
   - Market share per HCP
   - Brand switching patterns
   - Category leadership indicators

6. **Derived/Interaction Features**
   - Specialty × Volume interactions
   - Geography × Engagement
   - HCP Value Index
   - Target alignment scores

### 3. **Predictive Models** (`models/predictive_models.py`)
Machine learning models for sales optimization.

**Models:**

#### A. **Call Success Predictor**
- **Algorithm**: Random Forest Classifier
- **Target**: Probability of successful call outcome
- **Use Case**: Pre-call HCP prioritization
- **Metrics**: Accuracy, Precision, Recall, AUC-ROC

#### B. **Prescription Lift Forecaster**
- **Algorithm**: Gradient Boosting Regressor
- **Target**: Expected Rx increase post-call
- **Use Case**: ROI estimation, territory planning
- **Metrics**: RMSE, MAE, R²

#### C. **Sample Effectiveness Scorer**
- **Algorithm**: Random Forest Regressor
- **Target**: Rx generated per sample dropped
- **Use Case**: Sample allocation optimization
- **Metrics**: RMSE, R²

#### D. **Integrated Prediction Pipeline**
- Combines all models
- Generates Priority Score (0-100)
- Ranks all HCPs for targeting
- Saves trained models for deployment

### 4. **Main Pipeline** (`main_pipeline.py`)
End-to-end orchestration from data to deployment.

**Pipeline Steps:**
1. **Data Loading**: Load 13 reporting tables from SQL exports
2. **EDA**: Comprehensive exploratory analysis
3. **Feature Engineering**: Generate 100+ predictive features
4. **Modeling**: Train and evaluate all models
5. **Call Planning**: Generate Veeva-ready call plans
6. **Export**: Save all outputs and models

## 🚀 Quick Start

### Installation

```bash
cd "c:\Users\SandeepT\IBSA PoC V2\ibsa-poc-eda"

# Activate virtual environment
.\.venv\Scripts\Activate.ps1

# Install required packages (if not already installed)
pip install pandas numpy scikit-learn scipy matplotlib seaborn
```

### Running the Complete Pipeline

```bash
# Option 1: Run main pipeline (recommended)
python src\ibsa_poc_eda\main_pipeline.py

# Option 2: Run individual modules
python src\ibsa_poc_eda\precall_planning_engine.py
```

### Expected Runtime
- **Data Loading**: ~30 seconds
- **EDA**: ~2 minutes
- **Feature Engineering**: ~3-5 minutes
- **Model Training**: ~5-10 minutes
- **Total Pipeline**: ~10-15 minutes

## 📁 Output Files

All outputs are saved to: `c:\Users\SandeepT\IBSA PoC V2\ibsa-poc-eda\outputs\`

### Generated Files:

1. **Feature Engineered Data**
   - `IBSA_FeatureEngineered_YYYYMMDD_HHMM.csv`
   - Contains all 100+ engineered features
   - Ready for modeling or external use

2. **Model Predictions**
   - `IBSA_Predictions_YYYYMMDD_HHMM.csv`
   - Call success probabilities
   - Forecasted Rx lift
   - Priority scores and ranks

3. **Call Plan (Veeva-Ready)**
   - `IBSA_CallPlan_VeevaReady_YYYYMMDD_HHMM.csv`
   - HCP prioritization
   - Recommended call frequency
   - Next best actions
   - Veeva CRM field mapping

4. **Trained Models**
   - `models/call_success_model.pkl`
   - `models/rx_lift_model.pkl`
   - Reusable for scoring new HCPs

5. **Log File**
   - `ibsa_pipeline_YYYYMMDD_HHMM.log`
   - Complete execution log

## 📊 Key Metrics & KPIs

### Model Performance Targets:
- **Call Success Predictor**: AUC-ROC > 0.75
- **Rx Lift Forecaster**: R² > 0.60
- **Sample Effectiveness**: R² > 0.55

### Business Metrics:
- **HCP Universe**: ~250K-800K prescribers
- **Target Specialties**: 6 key specialties
- **IBSA Products**: 3 main brands (Tirosint, Flector, Licart)
- **Territories**: ~60-90 territories
- **Call Frequency**: 2-8 calls/quarter by tier

## 🎯 Business Use Cases

### 1. **Pre-Call Planning**
```python
from precall_planning_engine import HCPTargetingEngine, CallPlanningEngine

# Segment HCPs
targeting = HCPTargetingEngine(prescriber_df, trx_df)
segmented_hcps = targeting.segment_hcps()

# Generate call plan
planner = CallPlanningEngine(call_activity_df, segmented_hcps)
call_plan = planner.generate_call_plan(territory_id='T001')
```

### 2. **Feature Engineering**
```python
from features.feature_engineering_advanced import FeatureEngineer

engineer = FeatureEngineer()
feature_df = engineer.engineer_all_features(
    prescriber_df, call_activity_df, trx_df, nrx_df
)
```

### 3. **Predictive Scoring**
```python
from models.predictive_models import IBSAPredictionPipeline

pipeline = IBSAPredictionPipeline()
pipeline.train_all_models(feature_df, feature_list)
predictions = pipeline.predict_all(new_hcp_df, feature_list)
```

### 4. **Territory Optimization**
```python
# Identify top priority HCPs per territory
top_hcps = predictions_df.groupby('Territory').apply(
    lambda x: x.nlargest(50, 'Priority_Score')
)
```

## 📋 Data Requirements

### Required Tables (from SQL Server):
1. `Reporting_BI_PrescriberProfile` - HCP demographics & prescribing
2. `Reporting_BI_PrescriberOverview` - HCP summary metrics
3. `Reporting_BI_CallActivity` - Call history and details
4. `Reporting_BI_Trx_SampleSummary` - TRx data by product
5. `Reporting_BI_Nrx_SampleSummary` - NRx data by product
6. `Reporting_BI_TerritoryPerformanceSummary` - Territory-level metrics
7. `Reporting_BI_NGD` - National database reference
8. `Reporting_BI_PrescriberPaymentPlanSummary` - Payment preferences
9. `Reporting_BI_CallAttainment_Summary_Tier` - Call attainment by tier
10. `Reporting_BI_CallAttainment_Summary_TerritoryLevel` - Territory attainment

### Key Fields Expected:
- `HCP_NPI`, `HCP_Name`, `Specialty`, `State`, `Territory`
- TRx/NRx columns by product
- `Call_Date`, `Call_Type`, `Samples_Dropped`
- Geographic fields (State, City, ZIP)

## 🔧 Configuration

### Adjusting Thresholds

Edit `precall_planning_engine.py`:

```python
class IBSAConfig:
    THRESHOLDS = {
        'high_value_prescriber_trx': 50,     # Platinum tier threshold
        'medium_value_prescriber_trx': 20,   # Gold tier threshold
        'call_frequency_high': 8,            # Calls per quarter
        'call_frequency_medium': 4,
        'sample_effectiveness_threshold': 0.15
    }
```

### Target Specialties

```python
TARGET_SPECIALTIES = [
    'Endocrinology',
    'Family Practice',
    'Internal Medicine',
    'Pain Management',
    'Physical Medicine and Rehabilitation',
    'Rheumatology'
]
```

## 📈 Performance Optimization

### For Large Datasets (>1M rows):
1. Use chunking in data loading
2. Sample for initial model development
3. Use parallel processing for feature engineering
4. Implement incremental model updates

### Memory Management:
```python
# Process in batches
batch_size = 100000
for i in range(0, len(df), batch_size):
    batch = df.iloc[i:i+batch_size]
    process_batch(batch)
```

## 🐛 Troubleshooting

### Issue: Models not training
- **Check**: Verify target variables have sufficient positive cases
- **Fix**: Adjust target variable definitions in `TargetVariableCreator`

### Issue: Low model accuracy
- **Check**: Feature importance scores
- **Fix**: Add domain-specific features or remove noisy features

### Issue: Memory errors
- **Check**: Dataset size and available RAM
- **Fix**: Use data sampling or increase chunk size

### Issue: Missing data errors
- **Check**: Required columns in input CSVs
- **Fix**: Update column name mappings in code

## 📞 Veeva CRM Integration

### Output Format:
The call plan CSV is formatted for direct Veeva CRM import:

| Field | Description |
|-------|-------------|
| `HCP_NPI` | Unique identifier |
| `Next_Call_Action` | Recommended action (Detail + Sample, Detail Only, etc.) |
| `Recommended_Call_Frequency` | Calls per quarter |
| `Call_Priority` | Priority ranking (1 = highest) |
| `Priority_Score` | 0-100 composite score |

### Import to Veeva:
1. Save call plan CSV
2. Open Veeva CRM
3. Navigate to Account Planning
4. Import CSV using Veeva's bulk upload tool
5. Map fields to Veeva custom fields

## 🔮 Future Enhancements

### Planned Features:
- [ ] Real-time scoring API
- [ ] A/B test framework for call strategies
- [ ] Deep learning models for sequence prediction
- [ ] Automated model retraining pipeline
- [ ] Interactive dashboard (Power BI/Tableau)
- [ ] Mobile app integration
- [ ] Natural language insights generator

## 📚 References

### Business Context:
- **Quarterly Business Summary 7.2025 v3** - Executive metrics and KPIs
- **ODIA Precall Plan Veeva Integration** - System integration requirements
- **Executive Presentations** - Strategic priorities and focus areas

### Technical Documentation:
- [Scikit-learn Documentation](https://scikit-learn.org/)
- [Pandas User Guide](https://pandas.pydata.org/docs/)
- [Veeva CRM API Documentation](https://developer.veevacrm.com/)

## ✅ Testing

### Run Unit Tests:
```bash
pytest tests/
```

### Validate Pipeline:
```bash
python src\ibsa_poc_eda\main_pipeline.py --validate
```

## 📄 License

Internal IBSA use only. Confidential and proprietary.

## 👥 Support

For questions or issues:
- Technical: Contact Data Science Team
- Business: Contact Sales Operations
- Veeva Integration: Contact CRM Admin Team

---

**Last Updated**: October 2025  
**Version**: 1.0  
**Status**: Production Ready ✅
