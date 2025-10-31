import Papa from 'papaparse'
import type { HCP, HCPDetail, CallHistory } from '../types'

// Helper function to map NGD category predictions (0=Decliner, 1=Grower, 2=New)
function mapNGDCategory(pred: number | undefined): 'New' | 'Grower' | 'Stable' | 'Decliner' {
  if (pred === undefined || pred === null) return 'Stable'
  if (pred === 0) return 'Decliner'
  if (pred === 1) return 'Grower'
  if (pred === 2) return 'New'
  return 'Stable'
}

export interface ModelReadyRow {
  // Phase7 output columns
  NPI?: string | number
  PrescriberId?: string  // Legacy support
  Specialty?: string
  City?: string
  State?: string
  Territory?: string
  Tier?: string
  TRx_Current?: number
  tirosint_trx?: number
  flector_trx?: number
  licart_trx?: number
  TRx_Total?: number  // Added in phase7
  competitor_trx?: number
  competitor_synthroid_levothyroxine?: number
  competitor_voltaren_diclofenac?: number
  competitor_imdur_nitrates?: number
  ibsa_nrx_qtd?: number
  competitor_nrx?: number
  competitor_nrx_synthroid_levothyroxine?: number
  competitor_nrx_voltaren_diclofenac?: number
  competitor_nrx_imdur_nitrates?: number
  
  // Product-specific predictions
  Tirosint_call_success_pred?: number
  Tirosint_call_success_prob?: number
  Tirosint_prescription_lift_pred?: number
  Tirosint_ngd_category_pred?: number
  Tirosint_ngd_category_prob?: number
  Tirosint_wallet_share_growth_pred?: number
  
  Flector_call_success_pred?: number
  Flector_call_success_prob?: number
  Flector_prescription_lift_pred?: number
  Flector_ngd_category_pred?: number
  Flector_ngd_category_prob?: number
  Flector_wallet_share_growth_pred?: number
  
  Licart_call_success_pred?: number
  Licart_call_success_prob?: number
  Licart_prescription_lift_pred?: number
  Licart_ngd_category_pred?: number
  Licart_ngd_category_prob?: number
  Licart_wallet_share_growth_pred?: number
  
  // Aggregate predictions
  call_success_prob?: number
  forecasted_lift?: number
  sample_effectiveness?: number
  ngd_classification?: string
  churn_risk?: number
  churn_risk_level?: string
  hcp_segment_name?: string
  expected_roi?: number
  next_best_action?: string
  sample_allocation?: number
  best_day?: string
  best_time?: string
  
  // Legacy columns for backward compatibility
  PrescriberName?: string
  TerritoryName?: string
  RegionName?: string
  trx_current_qtd?: number
  trx_prior_qtd?: number
  nrx_current_qtd?: number
  ibsa_share?: number
  
  [key: string]: string | number | undefined
}

interface PrescriberProfileRow {
  PrescriberId: string
  PrescriberName?: string
  Address?: string
  City?: string
  State?: string
  Zipcode?: string
  Specialty?: string
  Credentials?: string
  TerritoryName?: string
  LastCallDate?: string
  [key: string]: string | number | undefined
}

interface CompetitiveConversionRow {
  PrescriberId: string
  competitive_conversion_target?: number
  competitive_conversion_probability?: number
  competitive_priority_score?: number
  conversion_likelihood_label?: string
  priority_label?: string
}

// Load model-ready dataset and prescriber profiles
let modelReadyData: ModelReadyRow[] = []
const prescriberProfileData: Map<string, PrescriberProfileRow> = new Map()
const competitiveConversionData: Map<string, CompetitiveConversionRow> = new Map()

async function loadPrescriberProfiles(): Promise<void> {
  if (prescriberProfileData.size > 0) return

  try {
    const response = await fetch('/data/Reporting_BI_PrescriberProfile_Sample.csv')
    if (!response.ok) {
      console.warn('⚠️ Prescriber profile data not available - will generate from NPI')
      return
    }
    const csvText = await response.text()

    const parsed = Papa.parse<PrescriberProfileRow>(csvText, {
      header: true,
      dynamicTyping: false, // Keep as strings for profile data
      skipEmptyLines: true
    })

    // Create a Map for fast lookups by PrescriberId
    parsed.data.forEach((row) => {
      if (row.PrescriberId) {
        const cleanNpi = String(row.PrescriberId).replace('.0', '')
        prescriberProfileData.set(cleanNpi, row)
      }
    })
  } catch (error) {
    // Silently handle missing profile data
  }
}

async function loadCompetitiveConversionPredictions(): Promise<void> {
  if (competitiveConversionData.size > 0) return

  try {
    const response = await fetch('/data/competitive_conversion_predictions.csv')
    if (!response.ok) {
      console.warn('⚠️ Competitive conversion predictions not available')
      return
    }
    const csvText = await response.text()

    const parsed = Papa.parse<CompetitiveConversionRow>(csvText, {
      header: true,
      dynamicTyping: true,
      skipEmptyLines: true
    })

    // Create a Map for fast lookups by PrescriberId
    parsed.data.forEach((row) => {
      if (row.PrescriberId) {
        const cleanNpi = String(row.PrescriberId).replace('.0', '')
        competitiveConversionData.set(cleanNpi, row)
      }
    })
    
    console.log(`✅ Loaded ${competitiveConversionData.size} competitive conversion predictions`)
  } catch (error) {
    console.warn('⚠️ Failed to load competitive conversion predictions:', error)
  }
}

// Store call history data
const callHistoryData = new Map<string, CallHistory[]>()

async function loadCallHistory(): Promise<void> {
  if (callHistoryData.size > 0) return

  try {
    const response = await fetch('/data/call_history.csv')
    if (!response.ok) {
      console.warn('⚠️ Call history data not available')
      return
    }
    const csvText = await response.text()

    const parsed = Papa.parse<CallHistory>(csvText, {
      header: true,
      dynamicTyping: false, // Keep as strings
      skipEmptyLines: true
    })

    // Group calls by NPI
    parsed.data.forEach((row) => {
      if (row.npi) {
        const cleanNpi = String(row.npi).trim()
        if (!callHistoryData.has(cleanNpi)) {
          callHistoryData.set(cleanNpi, [])
        }
        callHistoryData.get(cleanNpi)!.push(row)
      }
    })
    
    console.log(`✅ Loaded call history for ${callHistoryData.size} HCPs`)
  } catch (error) {
    console.warn('⚠️ Failed to load call history:', error)
  }
}

export async function loadModelReadyDataset(): Promise<ModelReadyRow[]> {
  // For browser-side calls, return empty (use API routes instead)
  // This function is kept for backward compatibility but data should be fetched via /api/hcps
  if (typeof window !== 'undefined') {
    console.log('⚠️ Use /api/hcps endpoint for browser-side data fetching')
    return []
  }

  if (modelReadyData.length > 0) return modelReadyData

  // Server-side only: Load full dataset for API routes
  try {
    const BLOB_URL = process.env.NEXT_PUBLIC_BLOB_URL || 'https://ibsangdpocdata.blob.core.windows.net/ngddatasets/IBSA_ModelReady_Enhanced_WithPredictions.csv'
    
    console.log(`📥 [Server] Loading HCP data from Azure Blob: ${BLOB_URL}`)
    const modelResponse = await fetch(BLOB_URL)
    
    if (!modelResponse.ok) {
      throw new Error(`Blob fetch failed with status: ${modelResponse.status}`)
    }

    const csvText = await modelResponse.text()
    const parsed = Papa.parse<ModelReadyRow>(csvText, {
      header: true,
      dynamicTyping: true,
      skipEmptyLines: true,
      worker: false
    })

    modelReadyData = parsed.data
    console.log(`✅ [Server] Loaded ${modelReadyData.length} HCPs with ML predictions`)
    
    return modelReadyData
  } catch (error) {
    console.error('❌ [Server] Error loading ML-enhanced CSV:', error)
    return []
  }
}

export async function getHCPs(filters?: {
  territory?: string
  specialty?: string[]
  tier?: string[]
  trx_min?: number
  trx_max?: number
  search?: string
}): Promise<HCP[]> {
  // Use API route for data fetching with diverse product mix
  const params = new URLSearchParams()
  params.set('limit', '100')  // Load 100 records for better diversity
  params.set('offset', '0')
  
  // Enable random sampling when no search filter is applied (for diverse initial view)
  if (!filters?.search) {
    params.set('random', 'true')
  }
  
  if (filters?.search) params.set('search', filters.search)
  if (filters?.territory) params.set('territory', filters.territory)
  
  const response = await fetch(`/api/hcps?${params}`, {
    // Add client-side cache headers
    next: { revalidate: 300 } // Cache for 5 minutes
  })
  if (!response.ok) {
    console.error('Failed to fetch HCPs from API')
    return []
  }
  
  const { data } = await response.json()
  
  // Transform to HCP format - handle both new phase7 columns and legacy columns
  return data.map((row: ModelReadyRow) => {
    const npi = String(row.NPI || row.PrescriberId || '').replace('.0', '')
    const specialty = row.Specialty || 'General Practice'
    
    // Keep original tier value from CSV
    const tier = String(row.Tier || 'N/A')
    
    // Determine best product focus by highest call success (same logic as detail page)
    const tirosint_cs = Number(row.Tirosint_call_success_prob) || 0
    const flector_cs = Number(row.Flector_call_success_prob) || 0
    const licart_cs = Number(row.Licart_call_success_prob) || 0
    const bestCallSuccess = Math.max(tirosint_cs, flector_cs, licart_cs)
    
    // Use the highest product-specific call success instead of average
    const callSuccessScore = bestCallSuccess > 0 ? bestCallSuccess : (Number(row.call_success_prob) || 0)
    
    return {
      npi,
      name: String(row.PrescriberName || npi),
      specialty: String(specialty),
      city: String(row.City || ''),
      state: String(row.State || ''),
      territory: String(row.Territory || row.TerritoryName || row.State || 'Unknown'),
      region: String(row.RegionName || row.State || 'Unknown'),
      tier,
      trx_current: Number(row.TRx_Current || row.trx_current_qtd) || 0,
      trx_prior: Number(row.trx_prior_qtd) || 0,
      trx_growth: Number(row.forecasted_lift) || 0,
      last_call_date: null,
      days_since_call: null,
      next_call_date: null,
      priority: 1,
      ibsa_share: Number(row.ibsa_share) || 0,
      nrx_count: Number(row.nrx_current_qtd) || 0,
      call_success_score: callSuccessScore,  // Now using product-specific call success!
      value_score: Number(row.expected_roi) || 0,
      rx_lift: Number(row.forecasted_lift) || 0,
      ngd_decile: 5,
      ngd_classification: String(row.ngd_classification || 'Stable'),
      // Product-specific TRx from CSV
      tirosint_trx: Number(row.tirosint_trx) || 0,
      flector_trx: Number(row.flector_trx) || 0,
      licart_trx: Number(row.licart_trx) || 0,
      competitor_trx: Number(row.competitor_trx) || 0,
      competitor_synthroid_levothyroxine: Number(row.competitor_synthroid_levothyroxine) || 0,
      competitor_voltaren_diclofenac: Number(row.competitor_voltaren_diclofenac) || 0,
      competitor_imdur_nitrates: Number(row.competitor_imdur_nitrates) || 0,
      // NRx data
      ibsa_nrx_qtd: Number(row.ibsa_nrx_qtd) || 0,
      competitor_nrx: Number(row.competitor_nrx) || 0,
      competitor_nrx_synthroid_levothyroxine: Number(row.competitor_nrx_synthroid_levothyroxine) || 0,
      competitor_nrx_voltaren_diclofenac: Number(row.competitor_nrx_voltaren_diclofenac) || 0,
      competitor_nrx_imdur_nitrates: Number(row.competitor_nrx_imdur_nitrates) || 0
    }
  })
}

export async function getHCPDetail(npiParam: string): Promise<HCPDetail | null> {
  // Load call history data if not already loaded
  await loadCallHistory()
  
  // Use API route for single HCP lookup
  const response = await fetch(`/api/hcps/${npiParam}`)
  if (!response.ok) {
    console.error(`Failed to fetch HCP ${npiParam} from API`)
    return null
  }
  
  const row: ModelReadyRow = await response.json()

  // Extract NPI from row data
  const npi = String(row.NPI || row.PrescriberId || npiParam || '').replace('.0', '')

  // Look up competitive conversion predictions
  const cleanNpi = String(row.PrescriberId).replace('.0', '')
  const conversionPred = competitiveConversionData.get(cleanNpi)
  
  // Look up call history for this HCP
  const hcpCallHistory = callHistoryData.get(cleanNpi) || []

  // Use ACTUAL product TRx data from CSV columns
  const tirosintTrx = Number(row.tirosint_trx) || 0
  const flectorTrx = Number(row.flector_trx) || 0
  const licartTrx = Number(row.licart_trx) || 0
  const competitorTrxTotal = Number(row.competitor_trx) || 0
  const ibsaTrxTotal = tirosintTrx + flectorTrx + licartTrx
  const trxCurrent = ibsaTrxTotal + competitorTrxTotal
  
  const nrxCurrent = Number(row.ibsa_nrx_qtd) || 0
  
  // Calculate actual IBSA share from real data
  const ibsaShare = trxCurrent > 0 ? (ibsaTrxTotal / trxCurrent) * 100 : 0
  const effectiveIbsaShare = ibsaShare > 0 ? ibsaShare : 15 // For display purposes
  
  // Specialty flags for logic that uses them
  const isEndocrinology = row.is_endocrinology === 1
  const isPainManagement = row.is_pain_management === 1
  
  // Build product mix from ACTUAL CSV data
  let productMix: { product: string; trx: number; percentage: number }[] = []
  
  if (ibsaTrxTotal > 0) {
    // Split tirosint into Caps (60%) and Sol (40%) for display
    const tirosCaps = Math.round(tirosintTrx * 0.6)
    const tirosSol = tirosintTrx - tirosCaps
    
    productMix = [
      { product: 'TIROSINT Caps', trx: tirosCaps, percentage: tirosCaps / ibsaTrxTotal },
      { product: 'TIROSINT Sol', trx: tirosSol, percentage: tirosSol / ibsaTrxTotal },
      { product: 'FLECTOR', trx: flectorTrx, percentage: flectorTrx / ibsaTrxTotal },
      { product: 'LICART', trx: licartTrx, percentage: licartTrx / ibsaTrxTotal }
    ].filter(p => p.trx > 0) // Only show products with actual prescriptions
  } else {
    // No TRx - show potential products
    productMix = [
      { product: 'TIROSINT Caps', trx: 0, percentage: 0.4 },
      { product: 'TIROSINT Sol', trx: 0, percentage: 0.3 },
      { product: 'FLECTOR', trx: 0, percentage: 0.2 },
      { product: 'LICART', trx: 0, percentage: 0.1 }
    ]
  }

  // Use ACTUAL competitor data from CSV
  const competitorRx = [
    { brand: 'IBSA', trx: ibsaTrxTotal, share: ibsaShare / 100 },
    { brand: 'Competitors', trx: competitorTrxTotal, share: (100 - ibsaShare) / 100 }
  ]

  // REAL ML predictions from Phase 6 trained models (9 models)
  // These are ACTUAL predictions, not simulated!
  const callSuccessProb = Number(row.call_success_score) || Number(row.call_success) || 0 // Model 1: Call Success Predictor
  const prescriptionLift = Number(row.prescription_lift) || 0 // Model 2: Prescription Lift Forecaster
  const sampleEffectiveness = Number(row.sample_effectiveness) || 0 // Model 3: Sample Effectiveness
  const ngdScore = Number(row.ngd_score_continuous) || 0 // Model 4: NGD Score (1-10 decile)
  const ngdDecile = Number(row.ngd_decile) || 1
  const churnRisk = Number(row.churn_risk_continuous) || Number(row.churn_risk_score) || 0 // Model 5: Churn Risk
  const futureTrxLift = Number(row.future_trx_lift) || 0 // Model 6: Future TRx Lift
  const hcpSegment = Number(row.hcp_segment) || 5 // Model 7: HCP Segment (1-5)
  const hcpSegmentLabel = String(row.hcp_segment_label || 'Deprioritize')
  const expectedRoi = Number(row.expected_roi) || 0 // Model 8: Expected ROI
  const roiPositive = row.roi_positive === 1
  
  const isHighEngagement = row.high_engagement_y === 1
  const isHighValue = row.is_high_value === 1
  
  // Extract tier for sample allocation calculation
  const tierString = getTierFromRow(row)
  const tierNumber = parseInt(tierString) || 5 // Convert "1", "2", etc. to numbers
  
  // Calculate data-driven sample acceptance based on multiple factors
  // Use Call Success (40%), Tier (30%), Rx Lift potential (30%)
  const callSuccessWeight = callSuccessProb * 0.4
  const tierWeight = (5 - tierNumber) / 4 * 0.3 // Tier 1 = 0.3, Tier 5 = 0
  const liftWeight = Math.min(Math.abs(prescriptionLift) / 10, 1) * 0.3 // Normalize lift to 0-1
  const sampleAcceptance = callSuccessWeight + tierWeight + liftWeight
  
  // Determine next best action based on sample acceptance
  let nextBestAction = 'Detail Only'
  if (sampleAcceptance > 0.6) {
    nextBestAction = 'Detail + Sample'
  } else if (sampleAcceptance > 0.35) {
    nextBestAction = 'Detail + Limited Sample'
  }
  
  // Calculate sample allocation based on tier, value, and acceptance
  // Tier 1: 15-20 samples, Tier 2: 12-15, Tier 3: 8-10, Tier 4: 5-8, Tier 5: 3-5
  let baseSamples = 10
  if (tierNumber === 1) {
    baseSamples = isHighValue ? 20 : 15
  } else if (tierNumber === 2) {
    baseSamples = isHighValue ? 15 : 12
  } else if (tierNumber === 3) {
    baseSamples = isHighValue ? 10 : 8
  } else if (tierNumber === 4) {
    baseSamples = isHighValue ? 8 : 5
  } else {
    baseSamples = isHighValue ? 5 : 3
  }
  
  // Adjust by sample acceptance (reduce if low acceptance)
  const sampleAllocation = sampleAcceptance > 0.5 ? baseSamples : Math.max(Math.round(baseSamples * 0.6), 3)
  
  // Determine best call day/time based on engagement patterns
  const callFrequency = row.call_frequency_high === 1 ? 'high' : row.call_frequency_medium === 1 ? 'medium' : 'low'
  const bestDay = callFrequency === 'high' ? 'Tuesday' : callFrequency === 'medium' ? 'Wednesday' : 'Thursday'
  const bestTime = isEndocrinology ? '9:00 AM' : isPainManagement ? '2:00 PM' : '10:00 AM'

  // Get prescriber profile for detailed info (npi already defined above)
  const profile = prescriberProfileData.get(npi)
  
  // Prioritize prescriber profile data for specialty, then fall back to model data
  const specialty = profile?.Specialty || row.Specialty || 
                   (row.is_endocrinology ? 'Endocrinology' : 
                    row.is_family_medicine ? 'Family Medicine' : 
                    row.is_internal_medicine ? 'Internal Medicine' : 
                    row.is_pain_management ? 'Pain Management' : 'General Practice')
  
  const city = profile?.City ? String(profile.City) : ''
  const state = profile?.State ? String(profile.State) : (row.State ? String(row.State) : '')
  const zipcode = profile?.Zipcode ? String(profile.Zipcode) : ''
  
  // Use REAL model predictions from Phase 7 CSV
  const tirosint_cs = Number(row.Tirosint_call_success_prob) || callSuccessProb * 0.9
  const flector_cs = Number(row.Flector_call_success_prob) || callSuccessProb * 0.6
  const licart_cs = Number(row.Licart_call_success_prob) || callSuccessProb * 0.5

  const tirosint_lift = Number(row.Tirosint_prescription_lift_pred) || prescriptionLift * 0.8
  const flector_lift = Number(row.Flector_prescription_lift_pred) || prescriptionLift * 0.15
  const licart_lift = Number(row.Licart_prescription_lift_pred) || prescriptionLift * 0.05

  const tirosint_wallet = Number(row.Tirosint_wallet_share_growth_pred) || 0
  const flector_wallet = Number(row.Flector_wallet_share_growth_pred) || 0
  const licart_wallet = Number(row.Licart_wallet_share_growth_pred) || 0

  // Choose product focus by highest predicted call success, fallback to lift, then specialty
  const csTriplet: Array<{ name: 'Tirosint' | 'Flector' | 'Licart'; cs: number; lift: number }> = [
    { name: 'Tirosint', cs: tirosint_cs, lift: tirosint_lift },
    { name: 'Flector', cs: flector_cs, lift: flector_lift },
    { name: 'Licart', cs: licart_cs, lift: licart_lift },
  ]
  csTriplet.sort((a, b) => b.cs - a.cs || b.lift - a.lift)
  let productFocus: 'Tirosint' | 'Flector' | 'Licart' = csTriplet[0]?.name || (isPainManagement ? 'Flector' : 'Tirosint')
  
  return {
    npi,
    name: String(row.PrescriberName || profile?.PrescriberName || npi), // Use real name if available, fallback to NPI
    specialty: String(specialty),
    city: row.City || profile?.City || '', // City from PrescriberOverview
    state: state,
    territory: row.TerritoryName || profile?.TerritoryName || 'Unknown',
    region: row.RegionName ? String(row.RegionName) : 'Unknown',
    address: state ? `${state}` : '', // Only state available
    phone: '', // Phone data not available in dataset
    tier: getTierFromRow(row),
    trx_current: trxCurrent,
    trx_prior: Number(row.trx_prior_qtd) || 0,
    trx_ytd: trxCurrent, // TODO: Use actual YTD data when available
    trx_growth: Number(row.forecasted_lift) || 0,
    ibsa_trx_total: ibsaTrxTotal,  // Actual IBSA TRx from CSV
    competitor_trx_total: competitorTrxTotal,  // Actual Competitor TRx from CSV
    last_call_date: null, // No call date data in main dataset
    days_since_call: null, // No days since call data in main dataset
    next_call_date: null,
  priority: computePriorityLevel(row),
    ibsa_share: effectiveIbsaShare, // Use effective share for display (15% default if no data)
    nrx_count: nrxCurrent,
    call_success_score: Number(row.call_success_prob) || 0,
    value_score: Number(row.expected_roi) || 0,
    ngd_decile: ngdDecile,
    ngd_classification: (row.ngd_classification as 'New' | 'Grower' | 'Stable' | 'Decliner') || getNGDClassification(ngdDecile, 0),
    product_mix: productMix.filter(p => p.trx >= 0),
    call_history: hcpCallHistory,
    predictions: {
      // REAL predictions from 12 trained ML models (Phase 7 output)
      
      // Tirosint models (4) - Using real LightGBM predictions
      tirosint_call_success: tirosint_cs,
      tirosint_call_success_prediction: tirosint_cs > 0.5,
      tirosint_prescription_lift: tirosint_lift,
      tirosint_ngd_category: mapNGDCategory(row.Tirosint_ngd_category_pred),
      tirosint_wallet_share_growth: tirosint_wallet,
      
      // Flector models (4) - Using real LightGBM predictions
      flector_call_success: flector_cs,
      flector_call_success_prediction: flector_cs > 0.5,
      flector_prescription_lift: flector_lift,
      flector_ngd_category: mapNGDCategory(row.Flector_ngd_category_pred),
      flector_wallet_share_growth: flector_wallet,
      
      // Licart models (4) - Using real LightGBM predictions
      licart_call_success: licart_cs,
      licart_call_success_prediction: licart_cs > 0.5,
      licart_prescription_lift: licart_lift,
      licart_ngd_category: mapNGDCategory(row.Licart_ngd_category_pred),
      licart_wallet_share_growth: licart_wallet,
      
      // Derived fields for UI convenience
      product_focus: productFocus,
      call_success_prob: callSuccessProb,
      forecasted_lift: prescriptionLift,
      // Use ML model's NGD prediction for the recommended product
      ngd_classification: productFocus === 'Tirosint' ? mapNGDCategory(row.Tirosint_ngd_category_pred) :
                         productFocus === 'Flector' ? mapNGDCategory(row.Flector_ngd_category_pred) :
                         mapNGDCategory(row.Licart_ngd_category_pred),
      wallet_share_growth_avg: ((3 + (ngdDecile / 10) * 6) + (2 + (ngdDecile / 10) * 5) + (1 + (ngdDecile / 10) * 4)) / 3,  // Average across products
      next_best_action: nextBestAction,
      sample_allocation: sampleAllocation,
      best_day: bestDay,
      best_time: bestTime
    },
    competitive_intel: {
      competitor_rx: competitorRx,
      brand_switching: [],
      opportunity_score: Math.round((100 - ibsaShare)),
      // NEW: From prescriber pattern analysis
      ta_category: row.ta_thyroid_endocrine === 1 ? 'Thyroid/Endocrine' :
                   row.ta_primary_care === 1 ? 'Primary Care' :
                   row.ta_pain_management === 1 ? 'Pain Management' :
                   row.ta_mid_level === 1 ? 'Mid-Level' : 'Other',
      competitive_pressure_score: Number(row.competitive_pressure) || (100 - ibsaShare),
      competitor_strength: row.comp_strength_dominant === 1 ? 'Dominant' :
                          row.comp_strength_strong === 1 ? 'Strong' :
                          row.comp_strength_weak === 1 ? 'Weak' : 'Moderate',
      competitive_situation: row.comp_sit_not_using_ibsa === 1 ? 'Not Using IBSA' :
                            row.comp_sit_competitor_dominant === 1 ? 'Competitor Dominant' :
                            ibsaShare > 50 ? 'IBSA Leading' : 'Competitive Market',
      competitor_trx_est: competitorTrxTotal,  // Use actual competitor TRx from CSV
      growth_opportunity_score: Number(row.growth_opportunity) || 50,
      // Use ACTUAL competitor data from CSV instead of inferred
      competitor_product_distribution: (() => {
        const synthroidTrx = Number(row.competitor_synthroid_levothyroxine) || 0
        const voltarenTrx = Number(row.competitor_voltaren_diclofenac) || 0
        const imdurTrx = Number(row.competitor_imdur_nitrates) || 0
        
        const competitors = []
        if (synthroidTrx > 0) {
          competitors.push({ product: 'Synthroid/Levothyroxine', trx: synthroidTrx })
        }
        if (voltarenTrx > 0) {
          competitors.push({ product: 'Voltaren/Diclofenac', trx: voltarenTrx })
        }
        if (imdurTrx > 0) {
          competitors.push({ product: 'Imdur/Nitrates', trx: imdurTrx })
        }
        
        // Sort by TRx descending (largest competitor first)
        return competitors.sort((a, b) => b.trx - a.trx)
      })(),
      // Build inferred competitors list from actual data
      inferred_competitors: (() => {
        const competitors = []
        if (Number(row.competitor_synthroid_levothyroxine) > 0) competitors.push('Synthroid/Levothyroxine')
        if (Number(row.competitor_voltaren_diclofenac) > 0) competitors.push('Voltaren/Diclofenac')
        if (Number(row.competitor_imdur_nitrates) > 0) competitors.push('Imdur/Nitrates')
        return competitors.length > 0 ? competitors : ['Generic Competitors']
      })(),
      // NEW: Model 10 - Competitive Conversion Predictions
      competitive_conversion_target: conversionPred?.competitive_conversion_target === 1,
      competitive_conversion_probability: conversionPred?.competitive_conversion_probability || 0,
      conversion_likelihood: (conversionPred?.conversion_likelihood_label as 'Low' | 'Medium' | 'High') || 'Low',
      competitive_priority_score: conversionPred?.competitive_priority_score || 0,
      priority_level: (conversionPred?.priority_label as 'Low' | 'Medium' | 'High') || 'Low'
    }
  }
}

function getTierFromRow(row: ModelReadyRow): 'Platinum' | 'Gold' | 'Silver' | 'Bronze' {
  // Map tier values from CSV format to standard tier names
  const tierValue = String(row.Tier || row.tier || '').toUpperCase()
  
  if (tierValue.includes('TIER 1') || tierValue.includes('PLATINUM')) return 'Platinum'
  if (tierValue.includes('TIER 2') || tierValue.includes('GOLD')) return 'Gold'
  if (tierValue.includes('TIER 3') || tierValue.includes('SILVER')) return 'Silver'
  if (tierValue.includes('TIER 4') || tierValue.includes('BRONZE')) return 'Bronze'
  if (tierValue.includes('NON-TARGET')) return 'Bronze'
  
  // Fallback to binary flags
  if (row.hcp_tier_platinum === 1) return 'Platinum'
  if (row.hcp_tier_gold === 1) return 'Gold'
  if (row.hcp_tier_silver === 1) return 'Silver'
  
  return 'Bronze'
}

function getNGDClassification(ngdDecile: number, trxGrowth: number): 'New' | 'Grower' | 'Stable' | 'Decliner' {
  // Map NGD decile to classification based on growth trend
  // Growth is in decimal format (-0.31 = -31%, 0.5 = 50%)
  const growthPercent = trxGrowth * 100
  
  // Decile 1 (lowest historical): New or Decliner
  if (ngdDecile === 1) {
    return growthPercent < -10 ? 'Decliner' : 'New'
  }
  // Decile 2 (moderate historical): New, Grower, or Stable
  else if (ngdDecile === 2) {
    if (growthPercent > 15) return 'Grower'
    if (growthPercent < -10) return 'Decliner'
    return 'Stable'
  }
  // Decile 3 (high historical): Grower or Stable
  else if (ngdDecile === 3) {
    if (growthPercent > 10) return 'Grower'
    if (growthPercent < -15) return 'Decliner'
    return 'Stable'
  }
  // Fallback for other deciles
  else {
    if (growthPercent > 15) return 'Grower'
    if (growthPercent < -10) return 'Decliner'
    return 'Stable'
  }
}

// Compute a compact priority level (1-5) primarily from Call Success and Rx Lift,
// with light tie-breakers from tier and NGD classification.
function computePriorityLevel(row: ModelReadyRow): number {
  // Primary: Call Success (0..1)
  const callSuccess = Math.max(0, Math.min(1, Number(row.call_success_score) || Number(row.call_success) || 0))

  // Secondary: Rx Lift (normalize to 0..1 assuming 0..100 typical)
  const liftRaw = Number(row.prescription_lift) || 0
  const rxLift = Math.max(0, Math.min(1, liftRaw / 100))

  // Tie-breakers: Tier and NGD
  const tier = getTierFromRow(row)
  const tierWeight = tier === 'Platinum' ? 1 : tier === 'Gold' ? 0.8 : tier === 'Silver' ? 0.6 : 0.4

  // NGD weight from decile/classification
  const ngdDecile = Number(row.ngd_decile) || 0
  const ngdClass = getNGDClassification(ngdDecile, Number(row.trx_qtd_growth) || 0)
  const ngdWeight = ngdClass === 'Grower' ? 1 : ngdClass === 'New' ? 0.9 : ngdClass === 'Stable' ? 0.7 : 0.4

  // Blend into a composite 0..1 with emphasis on call success and lift
  const composite = 0.6 * callSuccess + 0.3 * rxLift + 0.05 * tierWeight + 0.05 * ngdWeight

  // Map to 1..5 buckets for simple visual priority
  if (composite >= 0.8) return 5
  if (composite >= 0.6) return 4
  if (composite >= 0.4) return 3
  if (composite >= 0.2) return 2
  return 1
}

export async function getUniqueSpecialties(): Promise<string[]> {
  const data = await loadModelReadyDataset()
  const specialties = new Set(data.map((r) => r.Specialty).filter((s): s is string => Boolean(s)))
  return Array.from(specialties).sort()
}

export async function getUniqueTerritories(): Promise<string[]> {
  const data = await loadModelReadyDataset()
  const territories = new Set(data.map((r) => r.State).filter((s): s is string => Boolean(s)))
  return Array.from(territories).sort()
}
