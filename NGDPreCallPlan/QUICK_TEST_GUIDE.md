# Quick Testing Guide - HCP EDA Insights

## 🚀 Launch the UI

### Step 1: Start Next.js Dev Server
```powershell
cd ibsa_precall_ui
npm run dev
```

Expected output:
```
✓ Ready in 2.5s
○ Local:   http://localhost:3000
```

### Step 2: Open Browser
Navigate to: **http://localhost:3000**

---

## 🧪 Test Scenarios

### Scenario 1: View HCP with EDA Insights

1. **Dashboard loads** - see list of HCPs
2. **Click any HCP** from the list
3. **Check for EDA Insights section** at top of page (right after header, before location card)

**What to Look For:**
- 🧠 "Why This HCP?" header with Brain icon
- Color-coded alerts (red/green/amber/blue/purple)
- Evidence metrics grid showing:
  - TRx Trend
  - IBSA Share  
  - Volume
  - Sample ROI
  - Tier
  - Growth Potential
- Recommended Actions section
- EDA context text (e.g., "660 HCPs losing share, avg -10.8% decline")

---

### Scenario 2: Find At-Risk HCP

**Criteria**: TRx growth < -10% AND IBSA share > 30%

**What to Expect:**
```
⚠️ AT-RISK HCP
Declining TRx (-12.3%) despite high IBSA share (42%) - competitive threat detected

EDA: 660 HCPs losing share, avg -10.8% decline, 2,847 TRx at risk
```

**Evidence Metrics:**
- TRx Trend: 🔻 **-12.3%** Declining
- IBSA Share: ✓ **42%** Dominant Position
- Volume: 📊 **85 TRx** High Volume

**Recommended Actions:**
- 🎯 Immediate engagement required
- 📞 Schedule urgent call
- 🔍 Investigate competitor activities

---

### Scenario 3: Find Growth Opportunity HCP

**Criteria**: TRx volume > 50 AND IBSA share < 25%

**What to Expect:**
```
✨ GROWTH OPPORTUNITY
High prescribing volume (85 TRx) but low IBSA share (18%) - 82% growth potential

EDA: 264 opportunity HCPs, avg 12.9% share, 87.1% growth potential
```

**Evidence Metrics:**
- IBSA Share: 📉 **18%** Competitor Dominant
- Volume: 📊 **85 TRx** High Volume
- Growth Potential: 🎯 **82%** High Opportunity

**Recommended Actions:**
- 📈 High potential for IBSA growth
- 🎁 Increase sample allocation  
- 📅 Schedule regular touchpoints

---

### Scenario 4: Find Sample Black Hole

**Criteria**: Sample effectiveness < 5%

**What to Expect:**
```
⚠️ SAMPLE BLACK HOLE
Sample effectiveness 3.2% - samples not converting to TRx efficiently

EDA: 48.5% of HCPs are black holes, $616K potential waste
```

**Evidence Metrics:**
- Sample ROI: ❌ **Black Hole** 3% conversion rate
- EDA: "48.5% black holes, 18.5% high-ROI, $616K potential savings"

**Recommended Actions:**
- 💰 Redirect samples to high-ROI HCPs
- 📊 Monitor for improvement
- 🔍 Investigate root causes

---

### Scenario 5: Find High-ROI HCP

**Criteria**: Expected ROI > $50 OR sample effectiveness > 33%

**What to Expect:**
```
💡 HIGH-ROI HCP
Strong ROI potential: $85 per call with 42% sample conversion

EDA: 18.5% high-ROI HCPs, median ROI 5.6%, top performers 38x
```

**Evidence Metrics:**
- Sample ROI: ✅ **High ROI** 42% conversion rate
- EDA: "48.5% black holes, 18.5% high-ROI, $616K potential savings"

**Recommended Actions:**
- 🎁 Prioritize sample allocation
- 📈 Increase call frequency
- 🌟 Reward excellent performance

---

## 🎯 Test All Tabs

After viewing EDA Insights, scroll down to the tabbed section:

### Tab 1: "Overview & Insights"
- AI Key Messages (purple box)
- Quick Stats (blue box with call success, forecasted lift, etc.)

### Tab 2: "🤖 AI Call Script"
- CallScriptGenerator component
- "Generate Call Script" button
- "Generate with AI Enhancement" button

**Note**: FastAPI must be running for script generation to work!

### Tab 3: "Call History"
- Placeholder for now

---

## 🐛 Troubleshooting

### Issue: EDA Insights Not Showing

**Check:**
1. Component imported? `import { HCPEDAInsights } from '@/components/hcp-eda-insights'`
2. Component called? `<HCPEDAInsights hcp={hcp} />`
3. Browser console for errors? Press F12

### Issue: No Classifications Showing

**Possible Causes:**
- HCP doesn't meet any classification criteria
- Data values don't trigger thresholds
- Check HCP data: `trx_growth`, `ibsa_share`, `trx_current`, `predictions.sample_effectiveness`

**Test with these filters:**
- At-Risk: Find HCPs with negative TRx growth > 10%
- Opportunity: Find HCPs with low IBSA share < 25%
- Black Hole: Find HCPs with low expected ROI

### Issue: TypeScript Errors

**Run:**
```powershell
cd ibsa_precall_ui
npm run build
```

Check for compilation errors. All should be clear!

---

## ✅ Success Checklist

- [ ] Dev server running on localhost:3000
- [ ] Dashboard loads with HCP list
- [ ] Click HCP → Detail page loads
- [ ] EDA Insights visible at top (before location card)
- [ ] Classification alerts show (red/green/amber/blue)
- [ ] Evidence metrics grid displays 6 cards
- [ ] Recommended actions section appears
- [ ] EDA context text visible in alerts
- [ ] Tabs work (Overview, AI Call Script, History)
- [ ] AI Key Messages visible in Overview tab
- [ ] CallScriptGenerator visible in AI Call Script tab

---

## 📊 Expected Visual Layout

```
┌──────────────────────────────────────────────┐
│  Dr. John Smith                              │
│  NPI: 1234567890        [Gold Tier Badge]   │
│  [Back] [Schedule Call] [Add to Call Plan]  │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│  🧠 Why This HCP?                            │
├──────────────────────────────────────────────┤
│  ⚠️ AT-RISK HCP                              │
│  Declining TRx (-12.3%) despite high share   │
│  EDA: 660 HCPs losing share...              │
├──────────────────────────────────────────────┤
│  ✨ GROWTH OPPORTUNITY                        │
│  High volume (85 TRx) but low share (18%)   │
│  EDA: 264 opportunity HCPs...               │
├──────────────────────────────────────────────┤
│  Evidence That Drove This Classification:    │
│  ┌─────┐ ┌─────┐ ┌─────┐                    │
│  │ TRx │ │Share│ │ Vol │  ... 6 cards       │
│  │-12% │ │ 42% │ │ 85  │                    │
│  └─────┘ └─────┘ └─────┘                    │
├──────────────────────────────────────────────┤
│  ✅ Recommended Actions:                     │
│  • Immediate engagement required             │
│  • Schedule urgent call                      │
│  • Investigate competitors                   │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│  📍 Location    |    🎯 Specialty            │
│  City, State    |    Endocrinology           │
└──────────────────────────────────────────────┘

[Rest of page: 4 metric cards, charts, tabs...]
```

---

## 🎉 What Success Looks Like

When you click on an HCP, you should **immediately see**:

1. ✅ **Big brain icon** "Why This HCP?"
2. ✅ **Color-coded alerts** for classifications (1-5 possible)
3. ✅ **Evidence metrics** showing the data
4. ✅ **EDA context** connecting to Phase 3 findings
5. ✅ **Recommended actions** telling you what to do

**This is transparency** - not just showing predictions, but showing **WHY** with evidence from the 660 at-risk, 264 opportunity, 12,324 black hole HCPs discovered in EDA.

---

## 🚀 Next: Test Call Script Generation

Once EDA Insights are confirmed working:

1. Start FastAPI server: `python start_api.py`
2. Navigate to HCP detail
3. Click "🤖 AI Call Script" tab
4. Click "Generate with AI Enhancement"
5. Wait 5-10 seconds
6. Review generated script with MLR compliance

See `INTEGRATION_COMPLETE_GUIDE.md` for full FastAPI testing steps.
