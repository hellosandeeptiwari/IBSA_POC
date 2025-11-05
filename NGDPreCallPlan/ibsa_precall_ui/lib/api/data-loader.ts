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
  
  // Product-specific predictions (FIXED: Use new column names)
  Tirosint_growth_probability_pred?: number
  Tirosint_growth_probability_prob?: number
  Tirosint_prescription_lift_pred?: number
  Tirosint_ngd_category_pred?: number
  Tirosint_ngd_category_prob?: number
  Tirosint_wallet_share_growth_pred?: number
  
  Flector_growth_probability_pred?: number
  Flector_growth_probability_prob?: number
  Flector_prescription_lift_pred?: number
  Flector_ngd_category_pred?: number
  Flector_ngd_category_prob?: number
  Flector_wallet_share_growth_pred?: number
  
  Licart_growth_probability_pred?: number
  Licart_growth_probability_prob?: number
  Licart_prescription_lift_pred?: number
  Licart_ngd_category_pred?: number
  Licart_ngd_category_prob?: number
  Licart_wallet_share_growth_pred?: number
  
  // Aggregate predictions
  growth_probability?: number  // FIXED: Renamed from growth_probability
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
    // Auto-select data source based on environment
    const dataSource = process.env.DATA_SOURCE || 'local'
    const azureBlobUrl = process.env.AZURE_BLOB_URL || 'https://ibsangdpocdata.blob.core.windows.net/ngddatasets/IBSA_ModelReady_Enhanced_WithPredictions.csv'
    const localDataPath = process.env.LOCAL_DATA_PATH || '/data/IBSA_ModelReady_Enhanced_WithPredictions.csv'
    
    // Allow direct override via NEXT_PUBLIC_BLOB_URL
    const BLOB_URL = process.env.NEXT_PUBLIC_BLOB_URL || 
                     (dataSource === 'azure' ? azureBlobUrl : localDataPath)
    
    const isLocal = BLOB_URL.startsWith('/data')
    console.log(`📥 [Server] Loading HCP data from ${isLocal ? 'LOCAL file' : 'Azure Blob'}: ${BLOB_URL}`)
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
  
  // Use larger limit when searching to show all matching results
  const limit = filters?.search ? '1000' : '100'
  params.set('limit', limit)
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
    // Use npi if already transformed by API, otherwise transform from NPI
    const npi = (row as any).npi || String(row.NPI || row.PrescriberId || '').replace('.0', '')
    const specialty = row.Specialty || 'General Practice'
    
    // Keep original tier value from CSV
    const tier = String(row.Tier || 'N/A')
    
    // Determine best product focus by highest growth probability (FIXED: Use new column names)
    const tirosint_cs = Number(row.Tirosint_growth_probability_prob) || 0
    const flector_cs = Number(row.Flector_growth_probability_prob) || 0
    const licart_cs = Number(row.Licart_growth_probability_prob) || 0
    const bestCallSuccess = Math.max(tirosint_cs, flector_cs, licart_cs)
    
    // Use the highest product-specific growth probability instead of average
    const callSuccessScore = bestCallSuccess > 0 ? bestCallSuccess : (Number(row.growth_probability) || 0)
    
    // Normalize row data for priority calculation
    const rowForPriority = {
      ...row,
      growth_probability: bestCallSuccess,  // Use best product's growth probability
      forecasted_lift: Number(row.Tirosint_prescription_lift_pred) || Number(row.forecasted_lift) || 0
    }
    
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
      priority: computePriorityLevel(rowForPriority as ModelReadyRow),
      ibsa_share: Number(row.ibsa_share) || 0,
      nrx_count: Number(row.nrx_current_qtd) || 0,
      call_success_score: callSuccessScore,  // Now using product-specific call success!
      value_score: Number(row.expected_roi) || 0,
      rx_lift: Number(row.forecasted_lift) || 0,
      ngd_decile: 5,
      ngd_classification: (() => {
        // Use ML prediction from scoring models (Tirosint_ngd_category_pred)
        const ngdPred = Number(row.Tirosint_ngd_category_pred)
        if (ngdPred === 0) return 'Decliner'
        if (ngdPred === 1) return 'Stable'
        if (ngdPred === 2) return 'Grower'
        if (ngdPred === 3) return 'New'
        return String(row.ngd_classification || 'Stable')
      })(),
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
  // Use API route for single HCP lookup (call history is already parsed server-side)
  const response = await fetch(`/api/hcps/${npiParam}`)
  if (!response.ok) {
    console.error(`Failed to fetch HCP ${npiParam} from API`)
    return null
  }
  
  // API returns complete HCPDetail with call_history already parsed
  const hcpDetail: HCPDetail = await response.json()
  console.log(`✅ HCP ${npiParam} loaded from API with ${hcpDetail.call_history?.length || 0} calls`)
  
  return hcpDetail
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

// Compute a compact priority level (1-5) primarily from Growth Probability and Rx Lift,
// with light tie-breakers from tier and NGD classification.
function computePriorityLevel(row: ModelReadyRow): number {
  // Primary: Growth Probability (0..1) - likelihood of prescription increase
  const growthProb = Math.max(0, Math.min(1, Number(row.growth_probability) || 0))

  // Secondary: Rx Lift (normalize to 0..1 assuming typical range -50 to +50)
  const liftRaw = Number(row.forecasted_lift) || 0
  const rxLift = Math.max(0, Math.min(1, (liftRaw + 50) / 100))  // Shift range from -50..50 to 0..100

  // Tie-breakers: Tier and NGD
  const tier = getTierFromRow(row)
  const tierWeight = tier === 'Platinum' ? 1 : tier === 'Gold' ? 0.8 : tier === 'Silver' ? 0.6 : 0.4

  // NGD weight from decile/classification
  const ngdDecile = Number(row.ngd_decile) || 0
  const ngdClass = getNGDClassification(ngdDecile, Number(row.trx_qtd_growth) || 0)
  const ngdWeight = ngdClass === 'Grower' ? 1 : ngdClass === 'New' ? 0.9 : ngdClass === 'Stable' ? 0.7 : 0.4

  // SPECIAL CASE: If NGD says "Grower" or "New" but growth_probability is 0, use NGD status instead
  // This handles data inconsistencies where historical growth exists but model predicts 0
  let adjustedGrowthProb = growthProb
  if ((ngdClass === 'Grower' || ngdClass === 'New') && growthProb < 0.3) {
    adjustedGrowthProb = ngdClass === 'Grower' ? 0.6 : 0.5  // Give them minimum viable priority
  }

  // Blend into a composite 0..1 with emphasis on growth probability and lift
  const composite = 0.6 * adjustedGrowthProb + 0.3 * rxLift + 0.05 * tierWeight + 0.05 * ngdWeight

  // Debug logging (first 3 HCPs only)
  if (Math.random() < 0.01) {  // Log ~1% of records to avoid spam
    console.log('Priority Debug:', {
      npi: (row as any).PrescriberID,
      growthProb,
      adjustedGrowthProb,
      rxLift,
      liftRaw,
      tierWeight,
      ngdWeight,
      ngdClass,
      composite,
      finalPriority: composite >= 0.8 ? 5 : composite >= 0.6 ? 4 : composite >= 0.4 ? 3 : composite >= 0.2 ? 2 : 1
    })
  }

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
