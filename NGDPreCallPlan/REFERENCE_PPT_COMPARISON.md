# Reference Presentation Comparison & Temporal Analysis

**Date:** November 3, 2025  
**Reference File:** `Quarterly Business Summary 7.2025 v3-forConexus 1.pptx`

---

## 📊 Reference Presentation Analysis

### Structure
- **Total Slides:** 23
- **Focus:** Quarterly business performance (Q2 2025 vs Q2 2024, Q1 2025 vs Q4 2024)
- **Primary Metrics:** TQTY volume, TRx trends, regional attainment, market share

### Key Content Themes

#### 1. **Temporal Comparisons (QoQ & YoY)**
The reference presentation heavily emphasizes quarter-over-quarter (QoQ) and year-over-year (YoY) comparisons:

- **Q2 2025 vs Q2 2024:**
  - Tirosint Caps TQTY volume: **-2.7%**
  - Tirosint AG volume: **-33.9%** (due to Medicaid 340-B withdrawal October 2024)
  
- **Q1 2025 vs Q4 2024:**
  - Tirosint Branded Caps: **Lost 203 prescribers**
  - Tirosint-SOL: **Added 74 new prescribers**
  - New-to-brand prescriptions: **+2.7%** (slow but positive trend)

- **Regional Attainment Q1 2025:**
  - Southeast Region: **99% of Plan**
  - DHEP patches West Region: **115%**

#### 2. **Market Share Trends**
- Branded levothyroxine products losing share to generics (18-month pattern)
- Tirosint + Tirosint-SOL: **4.5% of branded LT4 TQTY**
- Synthroid erosion benefiting Unithroid, Levoxyl, and generic LT4

#### 3. **Copay & Access Intelligence**
- Coupon program shifts from Relay Health → Apollo Care
- Average copay benefit tracking by quarter
- Out-of-pocket costs increasing Q4 2024 → Q1 2025
- Medicare TRx increase due to new formulary wins

#### 4. **Specialty Pharmacy Growth**
- SP utilization % growing across all IBSA brands vs Q4 2024
- Highland leading SP dispenser
- Regional variation: West region highest SP usage

#### 5. **Data Sources Mentioned**
- IQVIA Xponent PlanTrak TQTY (normalized units)
- Eversana X-Factory units
- Fingertip Formulary usage (muted, flat March-April)

---

## 🔍 Our Data vs Reference Presentation

### What We Have (Static Snapshot)
Our `IBSA_Features_CLEANED_20251030_035304.csv` appears to be an **aggregated point-in-time snapshot** (likely Oct 2025), containing:

✅ **Cross-sectional data:**
- HCP demographics (Specialty, State, Territory)
- Current TRx volumes (tirosint_trx, flector_trx, licart_trx)
- Wallet share calculations (IBSA share vs total prescriptions)
- Call activity aggregates (total calls, L&L attendance)
- Sample allocation aggregates (total samples given)
- Competitive positioning (HCP tier: High/Medium/Low)

✅ **Temporal lag features (Phase 4B engineered):**
- `trx_lag_1/2/3period` - Historical prescription snapshots
- `trx_growth_recent` - Velocity proxy
- `is_lapsed_writer` - Binary flag for churn
- `trx_trending_up/down` - Momentum indicators
- `was_writer` - Historical activity flag

❌ **What we DON'T have:**
- **Quarterly time-series data** (Q1 2024, Q2 2024, Q3 2024, Q4 2024, Q1 2025, Q2 2025)
- **Longitudinal prescriber behavior** across multiple quarters
- **QoQ growth rates** (e.g., Q2 2025 vs Q1 2025)
- **YoY comparisons** (e.g., Q2 2025 vs Q2 2024)
- **Regional performance trends** over time
- **Market share evolution** quarter-by-quarter

---

## 🤔 Why No QoQ Analysis in Our EDA?

### Root Cause: Data Structure Mismatch

**Reference Presentation Data:**
```
PrescriberId | Quarter | Product | TRx | New_Prescribers | Market_Share
12345        | Q1_2024 | Tirosint| 45  | 1               | 12.3%
12345        | Q2_2024 | Tirosint| 52  | 0               | 13.1%
12345        | Q3_2024 | Tirosint| 48  | 0               | 12.8%
12345        | Q4_2024 | Tirosint| 50  | 0               | 13.0%
12345        | Q1_2025 | Tirosint| 55  | 0               | 13.5%
```
↑ **Longitudinal structure** - enables QoQ/YoY calculations

**Our Data:**
```
PrescriberId | Specialty | tirosint_trx | trx_lag_1 | trx_lag_2 | is_lapsed | Wallet_Share
12345        | Endo      | 55          | 50        | 48        | 0         | 87.3%
```
↑ **Cross-sectional snapshot with engineered lag features** - snapshot at Oct 2025

### What Phase 4B Did

The `phase4b_temporal_lag_features.py` script created **engineered proxies** for temporal dynamics:

1. **Lag Features:** `trx_lag_1, trx_lag_2, trx_lag_3` capture historical values
2. **Growth Proxies:** `trx_growth_recent = (current - lag_1) / lag_1`
3. **Momentum Flags:** `trx_trending_up`, `trx_trending_down`
4. **Churn Detection:** `is_lapsed_writer` (prescription velocity turned negative)

**These are DERIVED from a single snapshot, NOT true time-series data.**

### Implications for EDA

Our Phase 3 EDA (`phase3_comprehensive_eda_enterprise.py`) could NOT produce:
- ❌ Quarterly sales trend charts (line graphs showing Q1→Q2→Q3→Q4)
- ❌ YoY comparisons (Q2 2025 vs Q2 2024)
- ❌ Seasonal patterns (e.g., Q4 holidays impact on prescribing)
- ❌ New prescriber acquisition rates by quarter
- ❌ Market share erosion/growth trajectories

Instead, we produced:
- ✅ **Decile analysis** (Pareto 80/20 at a single point in time)
- ✅ **HCP segmentation** (High/Medium/Low tier based on current TRx)
- ✅ **Competitive positioning** (IBSA wallet share vs competitors NOW)
- ✅ **Sample ROI** (black holes vs high-ROI at current state)
- ✅ **Lapsed writer detection** (4,642 HCPs with negative velocity proxy)

---

## 🎯 Recommendations for Future Enhancements

### Option 1: Add Historical Quarterly Data
**If IQVIA/Eversana provides quarterly exports:**

1. **Data Structure:**
   ```sql
   CREATE TABLE hcp_quarterly_performance (
       PrescriberId VARCHAR(20),
       Quarter DATE,  -- '2024-Q1', '2024-Q2', etc.
       Product VARCHAR(50),
       TRx_Volume INT,
       New_Prescriber_Flag BOOLEAN,
       Market_Share_Pct FLOAT,
       Cumulative_Calls INT,
       Samples_Given INT
   )
   ```

2. **New EDA Capabilities:**
   - **Quarterly trend charts** (line graphs)
   - **YoY growth calculations** (Q2 2025 vs Q2 2024)
   - **Cohort analysis** (HCPs who started Q1 2024 → track through Q2 2025)
   - **Seasonal decomposition** (trend, seasonality, residual)
   - **Intervention impact** (e.g., brand campaign launch Q1 2025 effect)

3. **New Presentation Slides:**
   - "Quarterly TRx Trends: 6-Quarter View"
   - "New Prescriber Acquisition by Quarter"
   - "Market Share Evolution: IBSA vs Competitors"
   - "Regional Performance: QoQ Comparison"
   - "Lapsed Writer Trend: Are we improving?"

### Option 2: Enhance Lag Feature Engineering
**Work with existing snapshot data:**

1. **Pseudo-Time Series from Lags:**
   ```python
   # Reconstruct approximate quarterly values
   df['approx_q_minus_3'] = df['trx_lag_3']
   df['approx_q_minus_2'] = df['trx_lag_2']
   df['approx_q_minus_1'] = df['trx_lag_1']
   df['current_quarter'] = df['tirosint_trx']
   
   # Calculate QoQ-like growth
   df['qoq_growth_q1_to_q2'] = (df['approx_q_minus_2'] - df['approx_q_minus_3']) / df['approx_q_minus_3']
   df['qoq_growth_q2_to_q3'] = (df['approx_q_minus_1'] - df['approx_q_minus_2']) / df['approx_q_minus_2']
   df['qoq_growth_q3_to_current'] = (df['current_quarter'] - df['approx_q_minus_1']) / df['approx_q_minus_1']
   ```

2. **Add to EDA:**
   - Aggregate growth rates across all HCPs
   - Distribution of QoQ changes (histogram)
   - Segment HCPs: Accelerating (3 consecutive positive QoQ) vs Decelerating

3. **Limitation:**
   - Still cannot show absolute quarter labels (Q1 2024, Q2 2024, etc.)
   - Cannot match external market events to specific quarters

### Option 3: Integrate IQVIA Xponent Data
**If accessible:**

1. **Request quarterly extracts** from IQVIA Xponent PlanTrak
2. **Match PrescriberId** to our internal data
3. **Create hybrid dataset:**
   - Internal: Call activity, samples, copay program usage
   - External: Market-level TRx, share, competitor volumes BY QUARTER

4. **Benefits:**
   - True time-series analysis
   - Benchmark against category trends
   - Isolate IBSA-specific interventions from market forces

---

## ✅ Current Presentation Updates (Nov 3, 2025)

### Changes Made:
1. ✅ **SHAP Analysis:** Expanded from Top 5 → **Top 6 drivers**
   - Added 6th feature: "Competitor TRx Share" (8% influence)
   - Layout now 3×2 grid (3 cards per row)

2. ✅ **Monetary References Removed:**
   - Model performance cards: Replaced "$2M revenue protected" → "4,642 lapsed writers identified"
   - Share capture: "$4.9M opportunity" → "98K TRx cultivation opportunity"
   - Call success: "$1.2M savings/year" → "180K fewer wasted calls/year"
   - Phase 5 targets: Removed all dollar amounts, kept metrics
   - Executive summary: Removed "$2M lost revenue", "$616K waste", "$5M gap"
   - EDA descriptions: Replaced "$" with HCP counts, TRx volumes, percentages

3. ✅ **Focus on Metrics, Not Money:**
   - Client will determine financial value
   - Presentation emphasizes: HCP counts, TRx volumes, efficiency gains, conversion rates

### File Generated:
📄 `IBSA_PreCallPlanning_Enterprise_Deck_20251103_122218.pptx`  
📊 36 slides | 7.86 MB

---

## 🔬 Temporal Analysis We DID Include

Even without true time-series, our presentation DOES discuss temporal dynamics:

### Slide Content with Temporal Context:

1. **Lapsed Writers Detection:**
   - "4,642 'lapsed writers' identified - HCPs who were active but have stopped"
   - "Prescription velocity turned negative over past 6 months"
   - "Deploy win-back campaigns within 90-day window"

2. **SHAP Feature #1:**
   - "TRx 6-Month Lag" (24% influence)
   - "Prescriber momentum - increasing trend = 3x response rate"

3. **SHAP Feature #4:**
   - "Days Since Last Call" (12% influence)
   - "Recency effect - optimal 3-4 weeks for actives"

4. **Feature Engineering Slide:**
   - "Temporal Lag Features (8 features) - HIGHEST PREDICTIVE POWER"
   - "3/6/12-month Rx trends, prescriber lifecycle stage"

5. **NGD Model Priority:**
   - "Catch DECLINERS before they churn completely"
   - "90-day early intervention window"
   - "Temporal lag features enable proactive action"

### Key Difference:
- **Reference Presentation:** Shows ACTUAL quarter labels, YoY percentages, specific time periods
- **Our Presentation:** Discusses temporal CONCEPTS (trends, momentum, recency, velocity) using engineered proxies

---

## 📝 Summary: Reference vs Our Data

| Aspect | Reference Presentation | Our Analysis |
|--------|----------------------|--------------|
| **Data Structure** | Longitudinal (quarterly time-series) | Cross-sectional snapshot with lag features |
| **Time Periods** | Q1 2024 → Q2 2025 (6 quarters) | Single snapshot (Oct 2025) |
| **QoQ Analysis** | ✅ Explicit (e.g., Q2 vs Q1: +2.7%) | ❌ Not possible with current data |
| **YoY Analysis** | ✅ Explicit (e.g., Q2 2025 vs Q2 2024: -2.7%) | ❌ Not possible |
| **Temporal Proxies** | ❌ No need (has real quarters) | ✅ Engineered (lag features, velocity flags) |
| **Trend Charts** | ✅ Line graphs over 6 quarters | ❌ Point-in-time distributions |
| **Lapsed Writer Tracking** | ✅ "Lost 203 prescribers Q1 2025" | ✅ "4,642 lapsed writers" (velocity proxy) |
| **Market Share Trends** | ✅ "18-month pattern of brand erosion" | ✅ "4.5% current market share" (static) |
| **New Prescriber Rates** | ✅ "+2.7% NTB Q1 2025 vs Q4 2024" | ✅ "NEW category in NGD model" (flag) |
| **Regional Attainment** | ✅ "SE Region: 99% of Plan Q1 2025" | ✅ "10x territory performance gap" (variance) |

---

## 🎯 Conclusion

**Does our data match the reference presentation?**

**Partially.** We have:
- ✅ Same HCP identifiers (PrescriberId)
- ✅ Same products (Tirosint, Flector, Licart)
- ✅ Similar metrics (TRx, wallet share, specialty, territory)
- ✅ Temporal proxies that **approximate** trends (lag features, velocity, momentum)

But we lack:
- ❌ **True quarterly panel data** for QoQ/YoY analysis
- ❌ **Explicit quarter labels** (Q1 2024, Q2 2024, etc.)
- ❌ **Longitudinal tracking** of same HCPs over 6+ quarters

**Our analysis is enterprise-grade for ML modeling** (NGD prediction, prescription lift, share capture) but **cannot replicate the quarterly business review format** shown in the reference presentation without acquiring time-series data.

---

**Next Steps:**
1. **Request quarterly historical data** from IQVIA/Eversana if available
2. **Add QoQ slides** to presentation once time-series data is integrated
3. **Current presentation remains valid** for ML explainability and targeting strategy (no QoQ required for model predictions)
