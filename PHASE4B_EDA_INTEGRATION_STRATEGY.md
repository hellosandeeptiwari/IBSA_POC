# PHASE 4B: EDA-DRIVEN FEATURE ENGINEERING STRATEGY
## **Integration of Phase 3 EDA Insights into Feature Engineering**

**Date:** October 29, 2025  
**Purpose:** Translate pharmaceutical EDA insights into intelligent feature engineering for pre-call planning model

---

## 🎯 **CRITICAL EDA INSIGHTS FOR PHASE 4B**

### **1. DECILE ANALYSIS (Pareto 80/20 Rule)**
**Finding:** Top 10% HCPs = 63.6% of TRx, Top 20% = 79.2% of TRx

**Phase 4B Action:**
```python
# CREATE DECILE-BASED FEATURES
- hcp_decile: 1-10 ranking by TRx volume
- is_top_10_pct: Binary flag for top 10% HCPs
- is_top_20_pct: Binary flag for top 20% HCPs
- decile_avg_trx: Average TRx for HCP's decile
- decile_penetration: HCP TRx / Decile Average (% vs peers)
- decile_stability: Coefficient of variation within decile
```

**Why Important:** Models should prioritize top decile HCPs differently. Top 10% require retention strategies, bottom 90% require growth strategies.

---

### **2. PHARMACEUTICAL STANDARD SEGMENTATION**
**Finding:** 
- **Active Writers:** 65,306 (65.3%) | 466,231 TRx (98.6%)
- **Lapsed Writers:** 4,642 (4.6%) | 6,690 TRx | Historical potential: 20,465 TRx
- **Potential Writers:** 29,630 (29.6%) | 0 TRx
- **Aware Non-Writers:** 197 (0.2%) | 317 calls invested, 0 TRx
- **Unaware Non-Writers:** 225 (0.2%) | Never engaged

**Phase 4B Action:**
```python
# CREATE WRITER STATUS FEATURES
- writer_status: Categorical (Active/Lapsed/Potential/Aware/Unaware)
- is_active_writer: Binary flag
- is_lapsed_writer: Binary flag (HIGH PRIORITY - win-back opportunity)
- lapsed_decline_rate: % decline from historical peak
- potential_writer_score: Engagement level (calls + samples) without TRx
- time_since_last_trx: Days since last prescription
- historical_peak_trx: Maximum historical TRx (for lapsed writers)
- reactivation_potential: Historical TRx - Current TRx
```

**Why Important:** Different strategies needed:
- Active Writers: Retain & grow
- Lapsed Writers: Win-back campaigns
- Potential Writers: Convert with education
- Aware Non-Writers: Change approach (samples not working)

---

### **3. REACH & FREQUENCY ANALYSIS**
**Finding:**
- **Reach: 1.4%** (98.6% UNREACHED) ⚠️ CRITICAL GAP
- **Frequency: 2.3 calls/HCP** (below optimal 3-4)
- **Call Productivity:** 
  - 1 Call: 3.40 TRx/Call
  - 2-3 Calls: 2.58 TRx/Call
  - 4+ Calls: 2.78 TRx/Call

**Phase 4B Action:**
```python
# CREATE REACH & FREQUENCY FEATURES
- is_reached: Binary (has any calls)
- call_frequency_13wk: Number of calls in 13 weeks
- call_frequency_segment: Low/Medium/High touch
- days_since_last_call: Recency of last call
- call_consistency: Std dev of time between calls
- optimal_frequency_gap: Distance from optimal 3-4 calls
- call_saturation_flag: >6 calls (diminishing returns)
- unreached_high_potential: High TRx potential + 0 calls
```

**Why Important:** 98.6% unreached HCPs = massive opportunity. Model needs to:
1. Identify WHO to reach in unreached 98.6%
2. Optimize frequency for reached 1.4%
3. Predict ROI of additional calls

---

### **4. CALL PRODUCTIVITY INSIGHTS**
**Finding:** 
- **Lunch & Learn:** 90% TRx lift (4.7 → 9.0 avg TRx)
- **Overall:** 2.96 TRx per call
- **Frequency paradox:** More calls doesn't always = more TRx per call

**Phase 4B Action:**
```python
# CREATE CALL PRODUCTIVITY FEATURES
- had_lunch_learn_13wk: Binary
- lunch_learn_count_13wk: Count of L&L events
- trx_per_call_ratio: TRx / Calls (efficiency)
- call_to_trx_velocity: Rate of TRx increase per call
- lunch_learn_lift_estimate: Expected lift from L&L
- call_effectiveness_score: (Current TRx/Call) / (Peer Avg TRx/Call)
- marginal_call_return: TRx gain from last call vs previous
```

**Why Important:** Not all calls are equal. Model should:
1. Recommend Lunch & Learn for high-potential HCPs (90% lift!)
2. Identify when additional calls have diminishing returns
3. Predict optimal call type (detail, L&L, sample drop)

---

### **5. PRESCRIPTION VELOCITY & MOMENTUM**
**Finding:**
- **Rising Stars:** 9,227 HCPs | +101.6% acceleration | 113,521 TRx potential
- **Falling Stars:** 5,795 HCPs | -53.5% deceleration | 108,240 TRx at risk
- **Stable:** 66.4%
- **Mean velocity:** -6.8% (overall declining market)

**Phase 4B Action:**
```python
# CREATE VELOCITY & MOMENTUM FEATURES
- trx_velocity_13wk: % change in TRx (current vs prior 13wk)
- trx_acceleration: Change in velocity (momentum)
- momentum_segment: Rising Star/Stable/Falling Star/Freefall
- is_rising_star: Binary (high growth + high volume)
- is_falling_star: Binary (declining + high historical volume)
- velocity_percentile: HCP velocity vs all HCPs
- momentum_stability: Consistency of growth pattern
- trend_reversal_flag: Recent change in trajectory direction
```

**Why Important:** 
- Rising Stars (9,227): Double down on winners
- Falling Stars (5,795): Urgent intervention needed
- Velocity predicts future TRx better than static TRx

---

### **6. TARGET TIER ALIGNMENT**
**Finding:**
- **Tier 1 (Top):** 47.6 avg TRx/HCP, 542.80 TRx/Call
- **Tier 4 (Bottom):** 3.2 avg TRx/HCP, 20.04 TRx/Call
- **98.1% NON-TARGET:** Only 1.9% are targeted (Tier 1-4)

**Phase 4B Action:**
```python
# CREATE TIER-BASED FEATURES
- target_tier: 1/2/3/4/NON-TARGET
- is_targeted: Binary (Tier 1-4)
- tier_expected_trx: Average TRx for tier
- tier_performance_vs_expected: (Actual TRx - Tier Avg) / Tier Avg
- tier_call_efficiency: TRx/Call vs tier average
- tier_underperformer: Below tier average TRx
- tier_overperformer: Above tier average TRx
- untargeted_high_performer: NON-TARGET but high TRx (mis-targeted?)
```

**Why Important:** Tier 1 HCPs are 14.9x more valuable than Tier 4. Model needs to:
1. Validate tier assignments
2. Identify mis-targeted HCPs (high performers in NON-TARGET)
3. Optimize resource allocation by tier

---

### **7. SAMPLE ROI ANALYSIS**
**Finding:**
- **Sample Black Holes:** 48.5% (12,324 HCPs) - samples given, 0 TRx ROI
- **High-ROI HCPs:** 18.5% (4,699 HCPs) - ROI > 0.5
- **Mean ROI:** 0.43 TRx per sample

**Phase 4B Action:**
```python
# CREATE SAMPLE ROI FEATURES
- sample_roi: TRx / Samples (effectiveness)
- is_sample_black_hole: Binary (samples > 0, ROI < 0.05)
- is_high_sample_roi: Binary (ROI > 0.5)
- samples_per_trx: Efficiency (inverse of ROI)
- sample_responsiveness: Change in TRx after sample
- optimal_sample_quantity: Predicted best sample count
- sample_waste_flag: High samples, low TRx
- sample_to_call_ratio: Samples / Calls (intensity)
```

**Why Important:** 48.5% sample waste = $millions wasted. Model should:
1. Stop sampling black holes
2. Increase samples to high-ROI HCPs
3. Predict optimal sample quantity

---

### **8. COMPETITIVE INTELLIGENCE**
**Finding:**
- **IBSA Dominant:** 93.5% (54,544 HCPs)
- **At-Risk:** 722 HCPs | High volume + declining share | 3,073 TRx at risk
- **Opportunity:** 285 HCPs | High volume + low IBSA share | 1,702 TRx opportunity
- **Mean IBSA Share:** 92.2%

**Phase 4B Action:**
```python
# CREATE COMPETITIVE FEATURES
- ibsa_market_share_4wk: % of HCP's TRx from IBSA
- ibsa_market_share_13wk: Longer-term share
- share_trend: Change in share (4wk vs 13wk)
- is_at_risk: High volume + declining share
- is_opportunity: High volume + low IBSA share
- competitive_intensity: 100 - IBSA Share (competitor strength)
- share_volatility: Std dev of share over time
- share_loss_velocity: Rate of share decline
```

**Why Important:**
- At-Risk HCPs (722): Prevent churn with competitive defense
- Opportunity HCPs (285): Growth targets with offensive strategy
- Share trends predict future losses

---

### **9. SPECIALTY PERFORMANCE**
**Finding:**
- **Top 3 by Volume:**
  - Family Medicine: 115,129 TRx (26,321 HCPs)
  - Nurse Practitioner: 105,624 TRx (26,447 HCPs)
  - Endocrinology: 84,072 TRx (4,812 HCPs) - **17.5 avg TRx/HCP!**

**Phase 4B Action:**
```python
# CREATE SPECIALTY FEATURES
- specialty: Categorical (187 specialties)
- specialty_avg_trx: Average TRx for specialty
- specialty_performance_vs_peers: (HCP TRx - Specialty Avg) / Specialty Avg
- is_high_volume_specialty: Top 10 specialties by total TRx
- specialty_penetration: % of specialty HCPs prescribing
- specialty_growth_rate: Specialty-level TRx trend
- specialty_call_response: Specialty-specific call effectiveness
```

**Why Important:** Endocrinologists prescribe 17.5 TRx vs 4.4 for Family Medicine. Specialty-specific strategies needed.

---

### **10. DISCONTINUATION RISK**
**Finding:**
- **Declining Prescribers:** 26,609 (26.6%) | -26.6% avg drop | 59,671 TRx at risk
- **Call-Resistant:** 24 HCPs | High potential but declining despite calls
- **Sample Non-Responders:** 206 HCPs | 4,282 wasted samples

**Phase 4B Action:**
```python
# CREATE CHURN RISK FEATURES
- is_declining_prescriber: Binary (>20% TRx drop)
- trx_decline_rate: % decline from prior period
- is_call_resistant: High potential + declining + called
- is_sample_non_responder: Samples given but no TRx lift
- churn_risk_score: Multi-factor risk score
- months_to_churn_estimate: Predicted time to 0 TRx
- intervention_urgency: Priority level for win-back
```

**Why Important:** 26.6% declining = urgent intervention needed. Early warning system to prevent churn.

---

## 📊 **PHASE 4B FEATURE ENGINEERING ARCHITECTURE**

### **Feature Categories (EDA-Driven)**

#### **1. BEHAVIORAL FEATURES (From Segmentation)**
- RFM scores (Recency, Frequency, Monetary)
- Writer status (Active/Lapsed/Potential/Aware/Unaware)
- Decile ranking (1-10 by volume)
- Momentum segment (Rising Star/Stable/Falling Star)

#### **2. ENGAGEMENT FEATURES (From Reach & Frequency)**
- Call frequency & recency
- Call consistency & patterns
- Lunch & Learn participation
- Sample receipt & timing
- Last call date

#### **3. PERFORMANCE FEATURES (From Velocity & ROI)**
- TRx velocity & acceleration
- Sample ROI & effectiveness
- Call-to-TRx conversion
- Share trends & volatility
- Tier performance vs expected

#### **4. COMPETITIVE FEATURES (From Market Analysis)**
- IBSA market share (4wk, 13wk)
- Share trends & losses
- At-risk vs opportunity flags
- Competitive intensity

#### **5. CONTEXTUAL FEATURES (From Specialty & Territory)**
- Specialty performance metrics
- Territory benchmarks
- Peer comparisons
- Geographic factors

#### **6. RISK FEATURES (From Discontinuation Analysis)**
- Churn risk scores
- Decline rates
- Call resistance flags
- Sample non-response

---

## 🎯 **FEATURE SELECTION STRATEGY**

### **HIGH PRIORITY FEATURES (Must Include)**
Based on EDA statistical significance:

1. **Decile Features** - 63.6% of value in top 10%
2. **Writer Status** - 98.6% of TRx from active writers
3. **Velocity/Momentum** - Best predictor of future TRx
4. **Sample ROI** - 48.5% waste to optimize
5. **Lunch & Learn** - 90% lift proven
6. **At-Risk Flags** - 722 HCPs with 3,073 TRx at risk
7. **Tier Performance** - 14.9x difference between tiers
8. **Specialty** - 17.5x difference between specialties

### **MEDIUM PRIORITY FEATURES**
Useful but less critical:

- Call frequency segments
- Territory benchmarks
- Share volatility
- Product mix

### **LOW PRIORITY / REMOVE**
Based on EDA redundancy analysis:

- Highly correlated pairs (correlation > 0.90)
- Zero variance features
- High missing (>80%) features

---

## 🚀 **PHASE 4B EXECUTION PLAN**

### **Step 1: Load EDA Insights**
```python
# Load EDA recommendations
eda_recommendations = json.load('eda_recommendations.json')
hcp_segmentation = json.load('hcp_segmentation_analysis.json')
velocity_analysis = json.load('prescription_velocity_analysis.json')
call_effectiveness = json.load('call_effectiveness_analysis.json')
sample_roi = json.load('sample_roi_analysis.json')
competitive = json.load('competitive_intelligence_analysis.json')
```

### **Step 2: Create EDA-Driven Features**
For each insight category, create corresponding features using the patterns above.

### **Step 3: Feature Selection**
Apply EDA recommendations:
- Keep 260 features marked as "KEEP"
- Remove 80 features marked as "REMOVE"
- Prioritize 110 HIGH PRIORITY features

### **Step 4: Validate with EDA Metrics**
Ensure features align with EDA findings:
- Decile distributions match EDA
- Writer status distributions match EDA
- Velocity segments match EDA
- Sample ROI thresholds match EDA

---

## 💡 **KEY TAKEAWAYS FOR PHASE 4B**

1. **Not all HCPs are equal** - Top 10% drive 63.6% of value
2. **Writer status matters** - Active/Lapsed/Potential need different strategies
3. **Velocity beats volume** - Rising Stars > High volume stable
4. **Samples are wasteful** - 48.5% black holes need to be stopped
5. **Lunch & Learn works** - 90% lift is massive
6. **Reach is broken** - 98.6% unreached is the #1 problem
7. **Churn is real** - 26.6% declining need intervention
8. **Tiers work** - 14.9x difference validates targeting

---

## 📈 **EXPECTED OUTCOMES**

With EDA-driven feature engineering:
- **Better targeting:** Focus on top 20% HCPs (79.2% of value)
- **Churn prevention:** Early warning for 26.6% declining HCPs
- **Sample optimization:** Stop 48.5% waste, increase high-ROI
- **Call optimization:** Reach 98.6% unreached, optimize frequency
- **Revenue growth:** Convert 29,630 potential writers
- **Win-back:** Re-engage 4,642 lapsed writers (20,465 TRx potential)

---

**Next Step:** Run Phase 4B with this EDA-driven strategy! 🚀
