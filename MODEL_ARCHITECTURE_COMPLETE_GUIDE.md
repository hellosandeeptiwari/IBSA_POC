# IBSA PoC - Complete Model Architecture & Data Flow Guide

## 📊 Executive Summary

**Your question**: "Where are models stored, how does blob read model output, where is the ensemble?"

**Answer**: 
- **Models**: 9 trained `.pkl` files stored locally in `ibsa-poc-eda/outputs/models/trained_models/`
- **Model Outputs**: Already executed offline and embedded in the 188MB CSV on Azure Blob Storage
- **"Ensemble"**: Not a stacked ensemble - it's **9 separate models** with outputs pre-computed and stored as columns in the CSV
- **Blob Storage**: Contains the **final dataset with all predictions**, not the raw models

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        OFFLINE TRAINING PHASE                        │
│                     (Runs once, outputs saved)                       │
└─────────────────────────────────────────────────────────────────────┘
         │
         │ Python Script: phase6_model_training.py
         ↓
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 1: Train 9 Models                                              │
│  ├─ Tirosint_call_success        → model_Tirosint_call_success.pkl  │
│  ├─ Tirosint_prescription_lift   → model_Tirosint_prescription_lift.pkl│
│  ├─ Tirosint_ngd_category        → model_Tirosint_ngd_category.pkl  │
│  ├─ Flector_call_success         → model_Flector_call_success.pkl   │
│  ├─ Flector_prescription_lift    → model_Flector_prescription_lift.pkl│
│  ├─ Flector_ngd_category         → model_Flector_ngd_category.pkl   │
│  ├─ Licart_call_success          → model_Licart_call_success.pkl    │
│  ├─ Licart_prescription_lift     → model_Licart_prescription_lift.pkl│
│  └─ Licart_ngd_category          → model_Licart_ngd_category.pkl    │
│                                                                       │
│  Location: c:\Users\SandeepT\IBSA PoC V2\ibsa-poc-eda\outputs\models\trained_models\
└─────────────────────────────────────────────────────────────────────┘
         │
         │ All 9 models run in batch mode
         ↓
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 2: Generate Predictions for All HCPs                           │
│  ├─ Load 887,367 HCPs from cleaned dataset                           │
│  ├─ For each HCP, run all 9 models                                   │
│  ├─ Create 9 new columns with predictions:                           │
│  │   • tirosint_call_success_prob (0.0-1.0)                          │
│  │   • tirosint_prescription_lift (numeric)                          │
│  │   • tirosint_ngd_category (NEW/GROWER/STABLE/DECLINER)            │
│  │   • flector_call_success_prob                                     │
│  │   • flector_prescription_lift                                     │
│  │   • flector_ngd_category                                          │
│  │   • licart_call_success_prob                                      │
│  │   • licart_prescription_lift                                      │
│  │   • licart_ngd_category                                           │
│  └─ Output: IBSA_ModelReady_Enhanced.csv (188MB)                     │
│                                                                       │
│  Script: create_ui_compatible_dataset.py                             │
└─────────────────────────────────────────────────────────────────────┘
         │
         │ Upload to Azure
         ↓
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 3: Store on Azure Blob Storage                                 │
│  ├─ Container: ngddatasets                                           │
│  ├─ File: IBSA_ModelReady_Enhanced.csv                               │
│  ├─ Size: 188MB                                                      │
│  ├─ Contains: Original features + 9 model outputs                    │
│  └─ URL: https://ibsangdpocdata.blob.core.windows.net/ngddatasets/  │
│         IBSA_ModelReady_Enhanced.csv                                 │
└─────────────────────────────────────────────────────────────────────┘
         │
         │ Next.js UI fetches CSV
         ↓
┌─────────────────────────────────────────────────────────────────────┐
│                        RUNTIME PHASE                                 │
│                   (UI reads pre-computed predictions)                │
└─────────────────────────────────────────────────────────────────────┘
         │
         │ lib/server/data-cache.ts
         ↓
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 4: Load CSV into Memory (Server-Side Cache)                    │
│  ├─ Download 188MB CSV from Azure Blob                               │
│  ├─ Parse with PapaParse                                             │
│  ├─ Store in global.__IBSA_DATA_CACHE__                              │
│  ├─ TTL: 1 hour                                                      │
│  └─ Serves all API requests from this cache                          │
│                                                                       │
│  Function: getDataCached()                                           │
└─────────────────────────────────────────────────────────────────────┘
         │
         │ API route: /api/hcps
         ↓
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 5: Transform Data for UI                                       │
│  ├─ lib/api/data-loader.ts                                           │
│  ├─ Map CSV columns to TypeScript types                              │
│  ├─ Calculate derived fields:                                        │
│  │   • priority (1-5 based on tier + ROI + growth)                   │
│  │   • competitive_intel (aggregate competitor data)                 │
│  │   • competitor_product_distribution (market share estimates)      │
│  └─ Return: Array<ModelReadyRow>                                     │
└─────────────────────────────────────────────────────────────────────┘
         │
         │ UI Components read data
         ↓
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 6: Display in Next.js UI                                       │
│  ├─ Dashboard: Shows all HCPs with predictions                       │
│  ├─ HCP Detail Page: Shows 9 model outputs per HCP                   │
│  │   • Tirosint: Call Success (73%), Lift (+15 TRX), NGD (GROWER)   │
│  │   • Flector: Call Success (45%), Lift (+3 TRX), NGD (STABLE)     │
│  │   • Licart: Call Success (12%), Lift (-2 TRX), NGD (DECLINER)    │
│  └─ All data comes from CSV columns, NO models run at runtime        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🤖 Model Details: No "Ensemble" - 9 Independent Models

### What You Expected:
- A single "ensemble model" that combines predictions

### What Actually Exists:
- **9 separate, independent models**
- Each model predicts ONE specific outcome for ONE product
- No model stacking or voting ensemble

### Model Breakdown:

#### **Product: Tirosint** (Thyroid Treatment)
1. **Call Success Model** (`model_Tirosint_call_success.pkl`)
   - Type: Binary Classification (RandomForest)
   - Predicts: Will call to this HCP be successful? (0 or 1)
   - Output Column: `tirosint_call_success_prob` (0.0 to 1.0)
   - Example: 0.73 = 73% chance of successful call

2. **Prescription Lift Model** (`model_Tirosint_prescription_lift.pkl`)
   - Type: Regression (XGBoost)
   - Predicts: How many additional TRX after successful call?
   - Output Column: `tirosint_prescription_lift` (numeric, can be negative)
   - Example: 15.3 = Expect +15 prescriptions

3. **NGD Category Model** (`model_Tirosint_ngd_category.pkl`)
   - Type: Multi-Class Classification (RandomForest)
   - Predicts: HCP's prescribing trajectory
   - Output Column: `tirosint_ngd_category` (NEW/GROWER/STABLE/DECLINER)
   - Example: "GROWER" = HCP is increasing Tirosint prescriptions

#### **Product: Flector** (Pain Management)
4. **Call Success** → `flector_call_success_prob`
5. **Prescription Lift** → `flector_prescription_lift`
6. **NGD Category** → `flector_ngd_category`

#### **Product: Licart** (Pain Patch)
7. **Call Success** → `licart_call_success_prob`
8. **Prescription Lift** → `licart_prescription_lift`
9. **NGD Category** → `licart_ngd_category`

---

## 📂 Where Everything Is Stored

### 1. **Trained Models** (Local Filesystem)
```
c:\Users\SandeepT\IBSA PoC V2\ibsa-poc-eda\outputs\models\trained_models\
├── model_Tirosint_call_success.pkl      (RandomForest, 150 trees)
├── model_Tirosint_prescription_lift.pkl (XGBoost, 200 estimators)
├── model_Tirosint_ngd_category.pkl      (RandomForest, 120 trees)
├── model_Flector_call_success.pkl
├── model_Flector_prescription_lift.pkl
├── model_Flector_ngd_category.pkl
├── model_Licart_call_success.pkl
├── model_Licart_prescription_lift.pkl
└── model_Licart_ngd_category.pkl
```

**Size**: Each model is ~50-150MB (total ~800MB)
**Format**: Python pickle files (`.pkl`)
**Status**: ✅ Trained, validated, frozen (not updated at runtime)

### 2. **Model Performance Reports** (Local)
```
ibsa-poc-eda\outputs\models\
├── feature_importance_Tirosint_call_success.csv
├── feature_importance_Tirosint_prescription_lift.csv
├── feature_importance_Tirosint_ngd_category.csv
├── ... (27 total feature importance files)
├── model_performance_report_20251027_191919.json
└── training_audit_log_20251027_191919.json
```

**Contains**:
- Accuracy metrics (ROC-AUC, F1, MAE, RMSE, R²)
- Top 50 features per model
- Hyperparameters used
- Training timestamps

### 3. **Dataset with Predictions** (Azure Blob Storage)
```
Azure Storage Account: ibsangdpocdata
Container: ngddatasets
File: IBSA_ModelReady_Enhanced.csv
Size: 188MB (197,253,632 bytes)
URL: https://ibsangdpocdata.blob.core.windows.net/ngddatasets/IBSA_ModelReady_Enhanced.csv
```

**Structure**:
```csv
PrescriberId,PrescriberName,Specialty,Territory,TierScore,
tirosint_call_success_prob,tirosint_prescription_lift,tirosint_ngd_category,
flector_call_success_prob,flector_prescription_lift,flector_ngd_category,
licart_call_success_prob,licart_prescription_lift,licart_ngd_category,
trx_current_qtd,nrx_current_qtd,ibsa_market_share,competitor_trx,...
```

**Key Point**: The CSV contains **pre-computed predictions** from all 9 models. The UI NEVER loads or runs the `.pkl` models.

---

## 🔄 How Predictions Were Generated

### Script: `create_ui_compatible_dataset.py`

```python
# Step 1: Load all 9 trained models
models = {
    'tirosint_call_success': pickle.load(open('model_Tirosint_call_success.pkl', 'rb')),
    'tirosint_prescription_lift': pickle.load(open('model_Tirosint_prescription_lift.pkl', 'rb')),
    # ... load all 9 models
}

# Step 2: Load HCP dataset with features
hcp_data = pd.read_csv('IBSA_Features_Enhanced.csv')  # 887,367 HCPs

# Step 3: For each HCP, run all 9 models
for index, hcp in hcp_data.iterrows():
    # Extract features for this HCP
    X = hcp[feature_columns].values.reshape(1, -1)
    
    # Run Tirosint models
    hcp['tirosint_call_success_prob'] = models['tirosint_call_success'].predict_proba(X)[0][1]
    hcp['tirosint_prescription_lift'] = models['tirosint_prescription_lift'].predict(X)[0]
    hcp['tirosint_ngd_category'] = models['tirosint_ngd_category'].predict(X)[0]
    
    # Run Flector models
    hcp['flector_call_success_prob'] = models['flector_call_success'].predict_proba(X)[0][1]
    # ... (repeat for all 9 models)

# Step 4: Save with predictions embedded
hcp_data.to_csv('IBSA_ModelReady_Enhanced.csv', index=False)
```

**Output**: 188MB CSV with 887,367 rows × ~150 columns (original features + 9 prediction columns)

---

## 🌐 How the UI Reads Predictions

### Server-Side Cache (`lib/server/data-cache.ts`)

```typescript
export async function getDataCached(): Promise<ModelReadyRow[]> {
  // Check if data already in memory
  if (global.__IBSA_DATA_CACHE__.data) {
    return global.__IBSA_DATA_CACHE__.data;
  }
  
  // Fetch 188MB CSV from Azure Blob
  const BLOB_URL = 'https://ibsangdpocdata.blob.core.windows.net/ngddatasets/IBSA_ModelReady_Enhanced.csv';
  const res = await fetch(BLOB_URL);
  const csvText = await res.text();
  
  // Parse CSV to JSON array
  const parsed = Papa.parse<ModelReadyRow>(csvText, {
    header: true,
    dynamicTyping: true
  });
  
  // Store in memory for 1 hour
  global.__IBSA_DATA_CACHE__ = {
    data: parsed.data,
    fetchedAt: Date.now(),
    ttlMs: 3600000  // 1 hour
  };
  
  return parsed.data;
}
```

### Data Transformation (`lib/api/data-loader.ts`)

```typescript
export async function getHCPs(params: FilterParams) {
  // Get cached CSV data
  const rows = await getDataCached();
  
  // Filter and transform
  const hcps = rows.map(row => ({
    npi: row.PrescriberId,
    name: row.PrescriberName,
    specialty: row.Specialty,
    
    // Tirosint predictions (already in CSV)
    tirosint: {
      call_success_prob: row.tirosint_call_success_prob,
      prescription_lift: row.tirosint_prescription_lift,
      ngd_category: row.tirosint_ngd_category
    },
    
    // Flector predictions
    flector: {
      call_success_prob: row.flector_call_success_prob,
      prescription_lift: row.flector_prescription_lift,
      ngd_category: row.flector_ngd_category
    },
    
    // Licart predictions
    licart: {
      call_success_prob: row.licart_call_success_prob,
      prescription_lift: row.licart_prescription_lift,
      ngd_category: row.licart_ngd_category
    }
  }));
  
  return hcps;
}
```

### UI Display (`app/hcp/[npi]/page.tsx`)

```tsx
// Extract predictions from props
const { tirosint, flector, licart } = hcp;

// Display in UI
<div>
  <h3>Tirosint Predictions</h3>
  <p>Call Success: {(tirosint.call_success_prob * 100).toFixed(0)}%</p>
  <p>Expected Lift: +{tirosint.prescription_lift} TRX</p>
  <p>NGD Category: {tirosint.ngd_category}</p>
  
  <h3>Flector Predictions</h3>
  <p>Call Success: {(flector.call_success_prob * 100).toFixed(0)}%</p>
  {/* ... */}
</div>
```

---

## ❓ Why No "Ensemble Model"?

### What You Might Have Been Thinking:
```
                    ┌─────────────┐
  All Features  →   │   Ensemble  │  →  Single Prediction
                    │   (Stacked) │
                    └─────────────┘
                           ↑
            ┌──────────────┼──────────────┐
            │              │              │
      Model 1        Model 2        Model 3
    (Random Forest) (XGBoost)      (LightGBM)
```

### What Actually Exists:
```
                    ┌─────────────────┐
  Tirosint Data  →  │  RandomForest   │  →  Call Success Prob
                    └─────────────────┘

                    ┌─────────────────┐
  Tirosint Data  →  │    XGBoost      │  →  Prescription Lift
                    └─────────────────┘

                    ┌─────────────────┐
  Tirosint Data  →  │  RandomForest   │  →  NGD Category
                    └─────────────────┘

  (Repeat for Flector and Licart)
```

### Why Separate Models?
1. **Different prediction targets**: Call success vs. prescription lift vs. NGD category
2. **Product-specific**: Tirosint models trained on Tirosint data only
3. **Interpretability**: Each model explains ONE clear outcome
4. **Pharma compliance**: Easier to validate individual models with domain experts

---

## 📊 CSV Column Mapping

### Original Features (Used for Training)
```
PrescriberId          → Unique HCP identifier
TierScore            → HCP value (1-5, 5 = highest)
trx_prior_qtd        → Historical prescriptions (previous quarter)
nrx_prior_qtd        → Historical new prescriptions
engagement_score     → Call history engagement
competitor_trx       → Competitor prescriptions
ibsa_market_share    → IBSA's % of HCP's prescriptions
trx_growth_3m        → 3-month prescription trend
specialty            → HCP specialty
territory_id         → Sales territory
```

### Model Outputs (Added by phase6_model_training.py)
```
tirosint_call_success_prob     → 0.73 (73% success chance)
tirosint_prescription_lift     → 15.3 (expect +15 TRX)
tirosint_ngd_category          → "GROWER"
flector_call_success_prob      → 0.45
flector_prescription_lift      → 3.2
flector_ngd_category           → "STABLE"
licart_call_success_prob       → 0.12
licart_prescription_lift       → -2.1 (declining)
licart_ngd_category            → "DECLINER"
```

### Display-Only Fields (Added by create_ui_compatible_dataset.py)
```
PrescriberName       → "Dr. Jane Smith"
Address              → "123 Main St"
City, State, Zipcode → Location info
Specialty            → "Endocrinology"
TerritoryName        → "Northeast Region"
LastCallDate         → "2025-10-15"
```

**Total Columns**: ~150 (80 features + 9 predictions + 60 display fields)

---

## 🔐 Model Performance Summary

### Training Results (from `model_performance_report_20251027_191919.json`)

#### **Tirosint Models**
| Model | Metric | Score |
|-------|--------|-------|
| Call Success | ROC-AUC | 0.959 (95.9% accuracy) |
| Call Success | Precision | 0.949 |
| Prescription Lift | RMSE | 0.578 TRX |
| Prescription Lift | R² | 0.253 |
| NGD Category | Accuracy | 0.905 (90.5% accurate) |
| NGD Category | F1-Score | 0.893 |

#### **Flector Models**
| Model | Metric | Score |
|-------|--------|-------|
| Call Success | ROC-AUC | 0.921 |
| Prescription Lift | RMSE | 0.612 TRX |
| NGD Category | Accuracy | 0.887 |

#### **Licart Models**
| Model | Metric | Score |
|-------|--------|-------|
| Call Success | ROC-AUC | 0.903 |
| Prescription Lift | RMSE | 0.489 TRX |
| NGD Category | Accuracy | 0.879 |

**Interpretation**: All models perform well (>88% accuracy for classification, low error for regression).

---

## 🚀 Why This Architecture?

### ✅ Advantages:
1. **Fast UI**: No model loading/inference at runtime (predictions pre-computed)
2. **Simple deployment**: Only need CSV file, not ML dependencies
3. **Predictable costs**: No GPU/compute needed for serving
4. **Easy updates**: Re-run models offline, upload new CSV
5. **Audit trail**: CSV shows exact predictions given to field reps

### ⚠️ Trade-offs:
1. **Stale predictions**: Must re-run models monthly to update
2. **Large file**: 188MB CSV (but cached in memory)
3. **No real-time learning**: Can't adapt to new data instantly

---

## 🔄 How to Update Predictions

### Monthly Batch Process:

```bash
# Step 1: Refresh raw data from NGD database
python phase3_enterprise_eda_FULL.py

# Step 2: Regenerate features with latest data
python phase4_feature_engineering.py

# Step 3: Re-train all 9 models (optional, if model drift detected)
python phase6_model_training.py

# Step 4: Generate new predictions for all HCPs
python create_ui_compatible_dataset.py

# Step 5: Upload to Azure Blob Storage
az storage blob upload \
  --container-name ngddatasets \
  --name IBSA_ModelReady_Enhanced.csv \
  --file ibsa_precall_ui\public\data\IBSA_ModelReady_Enhanced.csv \
  --overwrite

# Step 6: Clear cache (automatic after 1 hour)
# Or restart Azure App Service to force immediate refresh
```

**Time Required**: ~2-3 hours for full pipeline (mostly model training)

---

## 📖 Summary: Your Questions Answered

### Q1: "Where are models stored?"
**A**: `c:\Users\SandeepT\IBSA PoC V2\ibsa-poc-eda\outputs\models\trained_models\` (9 `.pkl` files, ~800MB total)

### Q2: "How does blob read model output?"
**A**: Blob doesn't read models. Blob stores the **CSV file with pre-computed predictions**. The CSV was generated offline by running all 9 models on 887K HCPs.

### Q3: "Where is the ensemble model?"
**A**: There is **no ensemble**. You have 9 independent models (3 per product). Each predicts a different outcome. They don't combine predictions - they each produce a separate column in the CSV.

### Q4: "How are predictions used in the UI?"
**A**: 
1. UI fetches 188MB CSV from Azure Blob
2. CSV already contains 9 prediction columns
3. UI reads columns directly (no model inference)
4. Displays predictions on dashboard and detail pages

---

## 🎯 Key Takeaway

**Your UI is NOT running ML models at runtime.**

Instead:
- Models were trained once (Phase 6)
- All 887K HCPs were scored offline
- Predictions saved to CSV
- CSV uploaded to Azure Blob
- UI reads CSV and displays pre-computed predictions

This is a **"batch inference"** architecture, common in pharma/healthcare where:
- Predictions don't need real-time updates
- Audit trail is critical (CSV shows exact scores)
- Deployment is simplified (no ML dependencies)
- Cost is low (no GPU/inference server needed)

If you need **real-time predictions** (e.g., scoring new HCPs instantly), you'd need to:
1. Deploy models as an API (FastAPI + pickle.load)
2. Change UI to call prediction API
3. Add model versioning and A/B testing
4. Set up MLOps pipeline

But for pre-call planning with monthly updates, the current batch approach is **ideal**.
