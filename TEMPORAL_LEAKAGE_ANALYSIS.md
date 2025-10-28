# TEMPORAL LEAKAGE ANALYSIS
**Pharma-Grade ML Validation Report**  
Date: 2025-01-22  
Status: 🚨 CRITICAL ISSUE IDENTIFIED

---

## EXECUTIVE SUMMARY

After removing 24 features with direct/indirect data leakage, models **STILL show 97.98% accuracy** (down from 100% but still suspiciously high). Root cause identified: **TEMPORAL LEAKAGE** - using data from the outcome period to predict that same period.

---

## THE PROBLEM

### What We're Trying to Predict
**"Will this HCP increase prescriptions after our sales call?"**  
- This is a **FORWARD-LOOKING prediction** for pre-call planning
- Sales reps need to know BEFORE the call who to prioritize

### What We're Actually Doing ❌
**Using data FROM THE OUTCOME PERIOD to predict that period's results**

```
Timeline:
├─ Previous Quarter (P QTD) ✅ PAST - Can use for prediction
├─ [SALES CALLS HAPPEN HERE]
└─ Current Quarter (C QTD) ❌ OUTCOME - This is what we're predicting!
```

### The Leakage Chain

| Feature | Calculated From | Time Period | Issue |
|---------|----------------|-------------|-------|
| `call_success` (TARGET) | `TRX(C QTD) > TRX(P QTD)` | Current Quarter | The outcome we're predicting |
| `trx_current_qtd` | `TRX(C QTD)` | Current Quarter | ❌ From outcome period! |
| `nrx_current_qtd` | `NRX(C QTD)` | Current Quarter | ❌ From outcome period! |
| `growth_opportunity` | `trx_current_ytd / max(trx_current_ytd)` | Current Period | ❌ Uses current data! |
| `trx_prior_qtd` | `TRX(P QTD)` | Previous Quarter | ✅ Historical - OK to use |
| `nrx_prior_qtd` | `NRX(P QTD)` | Previous Quarter | ✅ Historical - OK to use |

---

## EVIDENCE OF TEMPORAL LEAKAGE

### 1. Suspiciously High Accuracy
```
Cross-Validation Results:
  Fold 1: 98.24%
  Fold 2: 97.84%
  Fold 3: 98.38%
  Fold 4: 97.68%
  Fold 5: 97.77%
  Mean: 97.98% ± 0.28%
```

**For comparison**, industry-standard churn prediction models achieve 70-85% accuracy.

### 2. Feature Importance Analysis
```
Top Features:
1. growth_opportunity: 48.48% importance
   - Calculated from trx_current_ytd (current period!)
   
2. trx_prior_qtd: 41.13% importance
   - This is OK (historical data)
   
3. comp_sit_not_using_ibsa: 7.85% importance
   - This is OK (static data)
```

The model is learning from `growth_opportunity` which contains information from the outcome period.

### 3. Distribution Analysis
```
Growth Opportunity by Call Success:
  Class 0 (Failed): mean=47.3, std=11.3
  Class 1 (Success): mean=46.4, std=13.1
```

While not perfectly separated, the model finds subtle patterns in current-period data that shouldn't be available pre-call.

---

## ROOT CAUSE: PHASE 4 FEATURE ENGINEERING

**File**: `phase4_feature_engineering.py`  
**Line**: 856-860

```python
# Calculate from volume and competitive pressure
if 'trx_current_ytd' in self.features_df.columns:
    trx_norm = (self.features_df['trx_current_ytd'] / 
                self.features_df['trx_current_ytd'].max()).fillna(0)
    comp_norm = (self.features_df.get('competitive_pressure', 100) / 100.0)
    self.features_df['growth_opportunity'] = ((trx_norm * 50) + (comp_norm * 50)).clip(0, 100)
    self.features_df['high_growth_opportunity'] = (self.features_df['growth_opportunity'] > 70).astype(int)
```

**Issue**: `trx_current_ytd` is year-to-date through the **current period**, which includes the outcome quarter!

---

## SOLUTION OPTIONS

### Option 1: Use ONLY Prior Period Features ✅ RECOMMENDED
**Approach**: Strict temporal cutoff - only features from BEFORE outcome period

**Changes Needed**:
1. Add to leakage list in Phase 5:
   - `growth_opportunity` (uses trx_current_ytd)
   - `high_growth_opportunity` (derived from growth_opportunity)
   - Any YTD metrics that include current quarter
   
2. Recreate `growth_opportunity` using ONLY prior period:
   ```python
   trx_norm = (df['trx_prior_qtd'] / df['trx_prior_qtd'].max()).fillna(0)
   growth_opportunity_prior = ((trx_norm * 50) + (comp_norm * 50)).clip(0, 100)
   ```

3. Expected accuracy after fix: **70-85%** (realistic for this task)

**Pros**: 
- ✅ Zero temporal leakage
- ✅ Model can be deployed for real pre-call planning
- ✅ Meets pharma-grade validation standards
- ✅ Explainable to regulators

**Cons**:
- ⚠️ Lower accuracy (but more honest!)
- ⚠️ May require additional feature engineering from historical data

---

### Option 2: Shift Target to FUTURE Period (Advanced)
**Approach**: Predict NEXT quarter's performance using current quarter features

```
Timeline:
├─ Previous Quarter (P QTD) - Historical features
├─ Current Quarter (C QTD) - All features available ✅
└─ Next Quarter (N QTD) - TARGET to predict
```

**Changes Needed**:
1. Modify Phase 5 to calculate:
   ```python
   call_success = TRX(N QTD) > TRX(C QTD)  # Predict NEXT quarter
   ```
   
2. Requires time-series data with 3+ quarters per HCP
3. Much more complex data preparation

**Pros**:
- ✅ True forward-looking prediction
- ✅ Can use all current period features legitimately
- ✅ More data (don't exclude 73.6% of HCPs)

**Cons**:
- ⚠️ Requires data restructuring (may not have N QTD for all HCPs)
- ⚠️ More complex to implement
- ⚠️ May have data availability issues

---

### Option 3: Hybrid - Use Lag Features
**Approach**: Create lag features from prior periods for model training

**Example**:
```python
# Instead of trx_current_qtd
df['trx_lag1'] = df.groupby('PrescriberId')['TRX(C QTD)'].shift(1)  # Previous quarter
df['trx_lag2'] = df.groupby('PrescriberId')['TRX(C QTD)'].shift(2)  # 2 quarters ago
df['trx_momentum'] = df['trx_lag1'] / df['trx_lag2']  # Growth rate
```

**Pros**:
- ✅ Captures temporal dynamics
- ✅ No leakage if done correctly
- ✅ Can use multiple historical periods

**Cons**:
- ⚠️ Requires longitudinal data (multiple time points per HCP)
- ⚠️ May lose HCPs without enough history
- ⚠️ Complex to implement correctly

---

## RECOMMENDATION

**Implement Option 1** for immediate deployment:

1. **Phase 1** (Quick Fix - 30 minutes):
   - Add `growth_opportunity` and `high_growth_opportunity` to LEAKAGE list
   - Remove from features
   - Retrain models
   - Expected accuracy: 70-85%

2. **Phase 2** (Enhanced - 2 hours):
   - Create `growth_opportunity_prior` using ONLY trx_prior_qtd
   - Test if this improves model without leakage
   - Expected accuracy: 75-88%

3. **Phase 3** (Future Enhancement):
   - Consider Option 2 (future period prediction) if client wants higher accuracy
   - Requires data availability analysis first

---

## VALIDATION CHECKLIST ✅

For pharma-grade deployment, verify:

- [ ] **Temporal Cutoff**: All features are from BEFORE outcome period
- [ ] **Cross-Validation**: Accuracy < 95% (realistic)
- [ ] **Feature Importance**: No single feature > 40% importance
- [ ] **Class Separability**: No perfect separation by any feature
- [ ] **Correlation Analysis**: No features > 0.95 correlation with target
- [ ] **Documentation**: All features explainable and justified
- [ ] **Regulatory Review**: Model logic reviewable by FDA/regulators
- [ ] **Deployment Test**: Can model run with ONLY data available at decision time?

---

## CURRENT STATUS

**Files Affected**:
- `phase4_feature_engineering.py` - Creates leaky features
- `phase5_target_engineering_ENHANCED.py` - Needs to remove 2 more features
- `phase6_model_training_COMPLETE.py` - Will automatically improve after fix

**Features to Remove** (bringing total to 26):
24. `growth_opportunity` (uses trx_current_ytd)
25. `high_growth_opportunity` (derived from growth_opportunity)

**Next Action**: Update Phase 5 leakage list and regenerate

---

## SUCCESS METRICS POST-FIX

| Metric | Before Fix | Expected After Fix | Status |
|--------|------------|-------------------|--------|
| Call Success Accuracy | 99.62% | 70-85% | ✅ Realistic |
| Prescription Lift R² | 0.7585 | 0.60-0.75 | ✅ Realistic |
| NGD Classification Accuracy | 92.67% | 85-92% | ✅ Already good |
| Cross-Validation Std Dev | ±0.0028 | ±0.02-0.05 | ✅ More variation |
| Top Feature Importance | 48.5% | <35% | ✅ Distributed |

---

**APPROVAL REQUIRED**: Choose solution option and proceed with implementation.
