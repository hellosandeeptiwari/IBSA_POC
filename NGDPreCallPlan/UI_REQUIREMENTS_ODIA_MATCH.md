# IBSA PRE-CALL PLANNING UI - REQUIREMENTS SPECIFICATION
## Based on ODIA Precall Plan Veeva Integration Screenshots

================================================================================
CRITICAL UI REQUIREMENTS - MATCH EXACT SCREENSHOTS
================================================================================

## PRIMARY SCREENS TO REPLICATE:

### SCREEN 1: HCP LIST VIEW (Main Dashboard)
Columns to display (exact match to ODIA screenshot):
- ☐ Checkbox (select HCP)
- Name (HCP full name)
- Specialty 
- City, State
- HCP Tier (Platinum/Gold/Silver/Bronze with color badges)
- TRx Total (current period)
- TRx Prior (previous period) 
- TRx Growth % (with trend arrows ↑↓)
- Last Call Date
- Days Since Call
- Next Recommended Call Date
- Call Priority (1, 2, 3...)
- Actions (View/Edit/Schedule buttons)

Filters (Left sidebar):
- Territory dropdown
- Specialty multi-select
- HCP Tier checkboxes
- TRx Range slider
- Last Call Date range
- Search by name/NPI

### SCREEN 2: HCP DETAIL VIEW (Right Panel/Modal)
Sections to replicate:

**A. HEADER SECTION:**
- HCP Name (large, bold)
- NPI Number
- Specialty (with icon)
- Address (street, city, state, zip)
- Phone
- Tier Badge (color-coded)

**B. PRESCRIBING METRICS (Card Grid):**
- Current TRx (big number with trend)
- Prior TRx (comparison)
- YTD TRx (year-to-date total)
- IBSA Market Share % (gauge chart)
- NRx Count (new prescriptions)
- Product Mix (horizontal bar chart)

**C. CALL HISTORY TIMELINE:**
- Chronological list of past calls
- Each entry shows:
  * Date & Time
  * Call Type (Detail, Sample Drop, Virtual)
  * Rep Name
  * Products Discussed
  * Samples Dropped
  * Call Notes (expandable)
  * Next Call Action assigned

**D. PREDICTIVE INSIGHTS (Highlighted Box):**
- Call Success Probability (0-100% with gauge)
- Forecasted Rx Lift ("+X TRx expected")
- Recommended Action (pill badge: "Detail + Sample")
- Best Call Window (day/time suggestion)
- Sample Allocation Suggestion

**E. COMPETITIVE INTEL:**
- Competitor Rx breakdown (pie chart)
- Brand switching patterns
- Market opportunity score

### SCREEN 3: CALL PLANNING CALENDAR VIEW
Layout:
- Monthly calendar grid
- HCPs scheduled on specific dates (draggable cards)
- Color coding by tier:
  * Platinum = Gold
  * Gold = Silver  
  * Silver = Light blue
  * Bronze = Gray
- Daily capacity meter (calls scheduled vs max)
- Territory filter at top
- Auto-optimize button

HCP Card on Calendar:
- Small profile photo/avatar
- Name
- Tier badge (mini)
- TRx total
- Drag handle icon

### SCREEN 4: TERRITORY PERFORMANCE DASHBOARD
Widgets:
1. KPI Cards (top row):
   - Total TRx (big number + trend)
   - Total Calls (count + target %)
   - Call Attainment (progress bar)
   - Sample Drops (count)
   - Avg TRx per Call (efficiency metric)

2. Territory Ranking Table:
   - Rank #
   - Territory Name
   - TRx Total
   - vs Target %
   - vs Prior Period %
   - Trend (sparkline)

3. HCP Tier Distribution (Donut Chart):
   - Platinum (count & %)
   - Gold (count & %)
   - Silver (count & %)
   - Bronze (count & %)

4. Geographic Heatmap:
   - State-level map
   - Color intensity = TRx volume
   - Click state to drill down

5. Product Performance (Stacked Bar Chart):
   - TIROSINT Caps
   - TIROSINT Sol
   - FLECTOR
   - LICART
   - By month/quarter

================================================================================
TECH STACK SPECIFICATIONS
================================================================================

## FRAMEWORK: Next.js 14 + TypeScript
```
Project Structure:
/app
  /dashboard               - Main dashboard (Screen 1)
  /hcp/[npi]              - HCP detail view (Screen 2)
  /call-planning          - Calendar view (Screen 3)
  /territory              - Territory dashboard (Screen 4)
  /api
    /hcps                 - HCP data endpoints
    /predictions          - Model predictions API
    /call-plans           - Call planning CRUD
  
/components
  /ui                     - shadcn/ui primitives
  /hcp-list              - HCP table component
  /hcp-card              - HCP profile card
  /calendar              - Call planning calendar
  /charts                - Recharts wrappers
  
/lib
  /api                   - API client functions
  /utils                 - Helper functions
  /types                 - TypeScript types
```

## UI COMPONENT LIBRARY: shadcn/ui
Components needed:
- ✅ Table (for HCP list)
- ✅ Card (for metrics)
- ✅ Badge (for tiers)
- ✅ Button 
- ✅ Dialog/Modal (HCP details)
- ✅ Select/Dropdown (filters)
- ✅ Checkbox (tier filters)
- ✅ Slider (TRx range)
- ✅ Calendar (scheduling)
- ✅ Tabs (detail view sections)
- ✅ Progress (call attainment)
- ✅ Avatar (HCP photos)
- ✅ Tooltip (metric explanations)

## CHARTS: Recharts
Chart types:
- Line Chart (TRx trends)
- Bar Chart (territory rankings, product mix)
- Donut Chart (tier distribution)
- Gauge Chart (call success probability)
- Sparkline (inline trends)
- Heatmap (geographic)
- Timeline (call history)

## DATA GRID: TanStack Table v8
Features:
- Sorting (all columns)
- Filtering (client + server side)
- Pagination (100 rows per page)
- Row selection (multi-select)
- Column resizing
- Fixed header
- Virtual scrolling (1M+ rows)
- Export to CSV/Excel

## STYLING: Tailwind CSS
Color Palette (match ODIA):
- Primary: Blue (#2563eb)
- Platinum: Gold (#fbbf24)
- Gold: Silver (#94a3b8)
- Silver: Light Blue (#60a5fa)
- Bronze: Gray (#6b7280)
- Success: Green (#10b981)
- Warning: Yellow (#f59e0b)
- Danger: Red (#ef4444)

Typography:
- Font: Inter (sans-serif)
- Heading: 600 weight
- Body: 400 weight
- Data: Tabular numbers

## STATE MANAGEMENT: Zustand + React Query
Stores:
- useFilterStore (HCP filters)
- useCallPlanStore (calendar state)
- useTerritoryStore (territory selection)

React Query:
- useHCPs() - Fetch HCP list
- useHCPDetail(npi) - Fetch single HCP
- usePredictions(npi) - Fetch ML predictions
- useCallPlan(territoryId) - Fetch call plan
- useTerritoryMetrics() - Fetch territory KPIs

## BACKEND API: Next.js API Routes + PostgreSQL
Database Schema:
```sql
-- Core tables
hcps (npi, name, specialty, city, state, tier, trx_current, trx_prior, ...)
call_history (call_id, hcp_npi, date, type, rep, products, samples, notes)
call_plans (plan_id, hcp_npi, scheduled_date, priority, action, status)
predictions (hcp_npi, call_success_prob, forecasted_lift, ngd_score, ...)
territories (territory_id, name, region, rep_name)

-- Aggregated views
hcp_metrics_v (pre-computed metrics for fast queries)
territory_performance_v (KPIs by territory)
```

API Endpoints:
```
GET  /api/hcps?territory=T001&tier=Platinum&page=1&limit=100
GET  /api/hcps/[npi]
GET  /api/hcps/[npi]/predictions
GET  /api/hcps/[npi]/call-history
POST /api/call-plans
PUT  /api/call-plans/[id]
GET  /api/territories/[id]/metrics
GET  /api/territories/[id]/rankings
```

================================================================================
SCREEN-BY-SCREEN COMPONENT BREAKDOWN
================================================================================

## SCREEN 1: HCP LIST VIEW (/dashboard)
File: app/dashboard/page.tsx

Components:
```tsx
<DashboardLayout>
  <FilterSidebar>
    <TerritorySelect />
    <SpecialtyMultiSelect />
    <TierCheckboxes />
    <TRxRangeSlider />
    <LastCallDatePicker />
    <SearchInput />
    <ApplyFiltersButton />
  </FilterSidebar>
  
  <MainContent>
    <PageHeader>
      <Title>HCP Targeting Dashboard</Title>
      <ActionButtons>
        <ExportButton />
        <BulkActionsDropdown />
      </ActionButtons>
    </PageHeader>
    
    <MetricCards>
      <KPICard title="Total HCPs" value={totalHCPs} />
      <KPICard title="Platinum Tier" value={platinumCount} />
      <KPICard title="Total TRx" value={totalTRx} />
      <KPICard title="Call Coverage" value={coverageRate} />
    </MetricCards>
    
    <HCPDataTable
      data={hcps}
      columns={columns}
      onRowClick={openHCPDetail}
      onSelectRows={handleBulkSelection}
      sorting={sorting}
      filters={appliedFilters}
      pagination={pagination}
    />
  </MainContent>
</DashboardLayout>
```

Table Columns Configuration:
```ts
const columns = [
  { id: 'select', header: Checkbox, cell: Checkbox, size: 40 },
  { id: 'name', header: 'Name', cell: HCPNameCell, sortable: true },
  { id: 'specialty', header: 'Specialty', sortable: true, filterable: true },
  { id: 'location', header: 'Location', cell: LocationCell },
  { id: 'tier', header: 'Tier', cell: TierBadge, sortable: true },
  { id: 'trx_current', header: 'Current TRx', cell: NumberCell, sortable: true },
  { id: 'trx_prior', header: 'Prior TRx', cell: NumberCell },
  { id: 'trx_growth', header: 'Growth %', cell: TrendCell, sortable: true },
  { id: 'last_call_date', header: 'Last Call', cell: DateCell, sortable: true },
  { id: 'days_since_call', header: 'Days Since', cell: NumberCell },
  { id: 'next_call_date', header: 'Next Call', cell: DateCell },
  { id: 'priority', header: 'Priority', cell: PriorityBadge, sortable: true },
  { id: 'actions', header: '', cell: ActionButtons, size: 120 }
];
```

## SCREEN 2: HCP DETAIL VIEW (/hcp/[npi])
File: app/hcp/[npi]/page.tsx

Components:
```tsx
<HCPDetailLayout>
  <HCPHeader
    name={hcp.name}
    npi={hcp.npi}
    specialty={hcp.specialty}
    address={hcp.address}
    tier={hcp.tier}
  />
  
  <TabsContainer>
    <Tab value="overview">
      <MetricsGrid>
        <MetricCard title="Current TRx" value={hcp.trx_current} trend={trend} />
        <MetricCard title="Prior TRx" value={hcp.trx_prior} />
        <MetricCard title="YTD TRx" value={hcp.trx_ytd} />
        <MetricCard title="IBSA Share" value={hcp.ibsa_share}>
          <GaugeChart value={hcp.ibsa_share} max={100} />
        </MetricCard>
        <MetricCard title="NRx Count" value={hcp.nrx_count} />
        <MetricCard title="Product Mix">
          <HorizontalBarChart data={hcp.product_mix} />
        </MetricCard>
      </MetricsGrid>
    </Tab>
    
    <Tab value="call-history">
      <CallHistoryTimeline
        calls={callHistory}
        renderItem={(call) => (
          <CallHistoryCard
            date={call.date}
            type={call.type}
            rep={call.rep}
            products={call.products}
            samples={call.samples}
            notes={call.notes}
          />
        )}
      />
    </Tab>
    
    <Tab value="insights">
      <PredictiveInsightsCard>
        <GaugeChart
          title="Call Success Probability"
          value={predictions.call_success_prob}
          threshold={75}
        />
        <ForecastMetric
          label="Forecasted Rx Lift"
          value={predictions.forecasted_lift}
          unit="TRx"
        />
        <RecommendedAction
          action={predictions.next_best_action}
          samples={predictions.sample_allocation}
        />
        <BestCallWindow
          day={predictions.best_day}
          time={predictions.best_time}
        />
      </PredictiveInsightsCard>
      
      <CompetitiveIntelCard>
        <PieChart data={competitorRx} />
        <BrandSwitchingTable data={brandSwitching} />
        <OpportunityScore score={opportunityScore} />
      </CompetitiveIntelCard>
    </Tab>
  </TabsContainer>
</HCPDetailLayout>
```

## SCREEN 3: CALL PLANNING CALENDAR (/call-planning)
File: app/call-planning/page.tsx

Components:
```tsx
<CallPlanningLayout>
  <PlanningHeader>
    <TerritorySelect value={selectedTerritory} />
    <MonthNavigator month={currentMonth} />
    <AutoOptimizeButton onClick={runOptimization} />
    <ExportToVeevaButton />
  </PlanningHeader>
  
  <PlanningStats>
    <StatCard label="Calls Scheduled" value={scheduledCalls} />
    <StatCard label="Capacity Used" value={capacityUsed} max={totalCapacity}>
      <ProgressBar value={capacityUsed} max={totalCapacity} />
    </StatCard>
    <StatCard label="Platinum HCPs" value={platinumScheduled} />
    <StatCard label="Samples Needed" value={samplesNeeded} />
  </PlanningStats>
  
  <DragDropContext onDragEnd={handleDrop}>
    <CalendarGrid>
      {daysInMonth.map(day => (
        <CalendarDay
          key={day}
          date={day}
          isToday={isToday(day)}
          capacity={dailyCapacity}
        >
          <Droppable droppableId={day}>
            {scheduledHCPs[day].map(hcp => (
              <Draggable key={hcp.npi} draggableId={hcp.npi}>
                <HCPCard
                  name={hcp.name}
                  tier={hcp.tier}
                  trx={hcp.trx}
                  priority={hcp.priority}
                  compact
                />
              </Draggable>
            ))}
          </Droppable>
        </CalendarDay>
      ))}
    </CalendarGrid>
    
    <Droppable droppableId="unscheduled">
      <UnscheduledHCPsPanel>
        {unscheduledHCPs.map(hcp => (
          <Draggable key={hcp.npi} draggableId={hcp.npi}>
            <HCPCard {...hcp} />
          </Draggable>
        ))}
      </UnscheduledHCPsPanel>
    </Droppable>
  </DragDropContext>
</CallPlanningLayout>
```

## SCREEN 4: TERRITORY PERFORMANCE (/territory)
File: app/territory/page.tsx

Components:
```tsx
<TerritoryDashboard>
  <DashboardHeader>
    <TerritorySelect />
    <DateRangePicker />
  </DashboardHeader>
  
  <KPIRow>
    <KPICard
      title="Total TRx"
      value={metrics.total_trx}
      trend={metrics.trx_trend}
      vsTarget={metrics.trx_vs_target}
    />
    <KPICard
      title="Total Calls"
      value={metrics.total_calls}
      target={metrics.call_target}
      progress={metrics.call_attainment}
    />
    <KPICard
      title="Call Attainment"
      value={`${metrics.call_attainment}%`}>
      <ProgressBar value={metrics.call_attainment} />
    </KPICard>
    <KPICard title="Sample Drops" value={metrics.sample_drops} />
    <KPICard
      title="Avg TRx per Call"
      value={metrics.trx_per_call}
      description="Efficiency"
    />
  </KPIRow>
  
  <ChartsGrid>
    <ChartCard title="Territory Rankings" span={2}>
      <TerritoryRankingTable
        territories={rankings}
        columns={['rank', 'name', 'trx', 'vs_target', 'vs_prior', 'sparkline']}
      />
    </ChartCard>
    
    <ChartCard title="HCP Tier Distribution">
      <DonutChart
        data={tierDistribution}
        colors={tierColors}
        showLegend
        showPercentages
      />
    </ChartCard>
    
    <ChartCard title="Geographic Performance" span={2}>
      <USMapHeatmap
        data={statePerformance}
        metric="trx"
        colorScale="blues"
        onStateClick={drillDownToState}
      />
    </ChartCard>
    
    <ChartCard title="Product Performance Over Time" span={2}>
      <StackedBarChart
        data={productPerformance}
        xAxis="month"
        series={['TIROSINT Caps', 'TIROSINT Sol', 'FLECTOR', 'LICART']}
        colors={productColors}
      />
    </ChartCard>
  </ChartsGrid>
</TerritoryDashboard>
```

================================================================================
DATA INTEGRATION & API DESIGN
================================================================================

## CONNECT TO PHASE 6 MODEL OUTPUTS

Load predictions from Phase 6 models:
```ts
// lib/api/predictions.ts
import { loadPredictionModels } from './model-loader';

const models = loadPredictionModels({
  callSuccess: 'outputs/models/call_success_predictor.pkl',
  rxLift: 'outputs/models/prescription_lift_forecaster.pkl',
  ngdScore: 'outputs/models/ngd_score_predictor.pkl'
});

export async function getPredictions(npi: string) {
  // Load HCP features from ModelReady CSV
  const hcpFeatures = await loadHCPFeatures(npi);
  
  // Run predictions
  const callSuccessProb = await models.callSuccess.predict(hcpFeatures);
  const forecastedLift = await models.rxLift.predict(hcpFeatures);
  const ngdDecile = await models.ngdScore.predict(hcpFeatures);
  
  return {
    call_success_prob: callSuccessProb,
    forecasted_lift: forecastedLift,
    ngd_score: ngdDecile,
    confidence: calculateConfidence(hcpFeatures)
  };
}
```

## LOAD FEATURE-ENGINEERED DATA

```ts
// lib/data/loader.ts
import Papa from 'papaparse';

export async function loadModelReadyDataset() {
  const response = await fetch('/data/IBSA_ModelReady_20251013_2307.csv');
  const csvText = await response.text();
  
  const parsed = Papa.parse(csvText, {
    header: true,
    dynamicTyping: true,
    skipEmptyLines: true
  });
  
  return parsed.data as ModelReadyRow[];
}

export async function loadHCPFeatures(npi: string) {
  const dataset = await loadModelReadyDataset();
  return dataset.find(row => row.PrescriberId === npi);
}
```

## POSTGRESQL DATABASE SETUP

```sql
-- Create database
CREATE DATABASE ibsa_precall;

-- Load CSV data into PostgreSQL
COPY hcps FROM '/path/to/IBSA_ModelReady_20251013_2307.csv' 
WITH (FORMAT csv, HEADER true);

-- Create indexes for fast queries
CREATE INDEX idx_hcps_npi ON hcps(npi);
CREATE INDEX idx_hcps_tier ON hcps(hcp_tier_platinum, hcp_tier_gold);
CREATE INDEX idx_hcps_territory ON hcps("TerritoryId");
CREATE INDEX idx_hcps_specialty ON hcps("Specialty");
CREATE INDEX idx_hcps_trx ON hcps(trx_current_ytd);

-- Create materialized view for dashboard
CREATE MATERIALIZED VIEW hcp_dashboard_v AS
SELECT 
  "PrescriberId" as npi,
  "Specialty" as specialty,
  "State" as state,
  CASE 
    WHEN hcp_tier_platinum = 1 THEN 'Platinum'
    WHEN hcp_tier_gold = 1 THEN 'Gold'
    WHEN hcp_tier_silver = 1 THEN 'Silver'
    ELSE 'Bronze'
  END as tier,
  trx_current_ytd as trx_current,
  trx_prior_ytd as trx_prior,
  ROUND(trx_qtd_growth * 100, 2) as trx_growth_pct,
  total_calls,
  engagement_score * 100 as engagement_score,
  hcp_value_score * 100 as value_score,
  priority_tier1,
  priority_tier2
FROM hcps;

-- Refresh strategy
CREATE UNIQUE INDEX ON hcp_dashboard_v (npi);
```

================================================================================
DEPLOYMENT CHECKLIST
================================================================================

## STEP 1: PROJECT SETUP
```bash
# Create Next.js 14 project with TypeScript
npx create-next-app@latest ibsa-precall-ui --typescript --tailwind --app

cd ibsa-precall-ui

# Install dependencies
npm install @tanstack/react-table zustand @tanstack/react-query
npm install recharts react-dnd react-dnd-html5-backend
npm install date-fns papaparse

# Install shadcn/ui
npx shadcn-ui@latest init
npx shadcn-ui@latest add table card badge button dialog select checkbox slider calendar tabs progress avatar tooltip
```

## STEP 2: COPY DATA FILES
```bash
# Copy model outputs to public/data
cp "c:/Users/SandeepT/IBSA PoC V2/ibsa-poc-eda/outputs/targets/IBSA_ModelReady_20251013_2307.csv" public/data/
cp "c:/Users/SandeepT/IBSA PoC V2/ibsa-poc-eda/outputs/models/*.pkl" lib/models/
```

## STEP 3: SETUP POSTGRESQL
```bash
# Install PostgreSQL locally or use cloud (Vercel Postgres, Supabase, AWS RDS)
# Run SQL schema from above
# Load CSV data using COPY command
```

## STEP 4: CONFIGURE ENVIRONMENT
```bash
# .env.local
DATABASE_URL="postgresql://user:pass@localhost:5432/ibsa_precall"
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="your-secret-key"
```

## STEP 5: BUILD & RUN
```bash
# Development
npm run dev

# Production build
npm run build
npm run start

# Deploy to Vercel
vercel deploy
```

================================================================================
SUCCESS CRITERIA
================================================================================

UI Must Match ODIA Screenshots:
✅ HCP list view with exact columns
✅ HCP detail modal/page layout
✅ Call planning calendar with drag-drop
✅ Territory performance dashboard
✅ Color scheme matches (Platinum=gold, etc.)
✅ Tier badges styled identically
✅ Metrics cards with trends
✅ Charts match style (Recharts + Tailwind)

Functionality:
✅ Filter HCPs by territory, specialty, tier, TRx
✅ Sort/search HCP table
✅ View HCP details with predictions
✅ Drag-and-drop call scheduling
✅ Auto-optimize call plan (ML-driven)
✅ Export to Veeva CSV format
✅ Real-time metrics updates

Performance:
✅ Initial load < 2s
✅ Table rendering (10K rows) < 500ms
✅ API response < 200ms (p95)
✅ Lighthouse score > 90

================================================================================
NEXT ACTIONS
================================================================================

IMMEDIATE: Create Next.js project skeleton
THEN: Implement Screen 1 (HCP List) - highest priority
THEN: Implement Screen 2 (HCP Detail)
THEN: Implement Screen 3 (Calendar)
THEN: Implement Screen 4 (Territory Dashboard)
FINALLY: Integration testing with Phase 6 models

Ready to proceed? I can start building the Next.js UI now.
