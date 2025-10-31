// HCP Data Types
export interface HCP {
  npi: string
  name: string
  specialty: string
  city: string
  state: string
  territory: string
  region: string
  tier: string  // Original tier value from CSV
  trx_current: number
  trx_prior: number
  trx_growth: number
  last_call_date: string | null
  days_since_call: number | null
  next_call_date: string | null
  priority: number
  ibsa_share: number
  nrx_count: number
  call_success_score: number
  value_score: number
  rx_lift?: number
  ngd_classification: 'New' | 'Grower' | 'Stable' | 'Decliner'
  ngd_decile: number
  // Product-specific TRx from CSV
  tirosint_trx?: number
  flector_trx?: number
  licart_trx?: number
  // Competitor TRx data
  competitor_trx?: number
  competitor_synthroid_levothyroxine?: number
  competitor_voltaren_diclofenac?: number
  competitor_imdur_nitrates?: number
  // NRx data
  ibsa_nrx_qtd?: number
  competitor_nrx?: number
  competitor_nrx_synthroid_levothyroxine?: number
  competitor_nrx_voltaren_diclofenac?: number
  competitor_nrx_imdur_nitrates?: number
}

export interface HCPDetail extends HCP {
  address: string
  phone: string
  trx_ytd: number
  ibsa_trx_total: number  // Total IBSA TRx (Tirosint + Flector + Licart)
  competitor_trx_total: number  // Total Competitor TRx
  product_mix: ProductMix[]
  call_history: CallHistory[]
  predictions: Predictions
  competitive_intel: CompetitiveIntel
}

export interface ProductMix {
  product: string
  trx: number
  percentage: number
}

export interface CallHistory {
  npi: string
  call_date: string
  call_type: 'Detail' | 'Sample Drop' | 'Virtual' | 'Group Detail'
  rep_name: string
  next_call_objective: string
  status: string
  products: string
  is_sampled: boolean
  duration: number
  location: string
}

export interface Predictions {
  // ============================================================================
  // REAL ML MODEL PREDICTIONS - Phase 6 Trained Models (12 total)
  // 3 Products × 4 Outcomes = 12 Models
  // ============================================================================
  
  // TIROSINT MODELS (4)
  tirosint_call_success: number  // Probability 0-1
  tirosint_call_success_prediction: boolean
  tirosint_prescription_lift: number  // Forecasted TRx increase
  tirosint_ngd_category: 'New' | 'Grower' | 'Stable' | 'Decliner'
  tirosint_wallet_share_growth: number  // Wallet share growth percentage points (0-100)
  
  // FLECTOR MODELS (4)
  flector_call_success: number
  flector_call_success_prediction: boolean
  flector_prescription_lift: number
  flector_ngd_category: 'New' | 'Grower' | 'Stable' | 'Decliner'
  flector_wallet_share_growth: number  // Wallet share growth percentage points (0-100)
  
  // LICART MODELS (4)
  licart_call_success: number
  licart_call_success_prediction: boolean
  licart_prescription_lift: number
  licart_ngd_category: 'New' | 'Grower' | 'Stable' | 'Decliner'
  licart_wallet_share_growth: number  // Wallet share growth percentage points (0-100)
  
  // ============================================================================
  // DERIVED FIELDS (computed from real model outputs for UI convenience)
  // ============================================================================
  
  // Primary product (highest call success probability)
  product_focus: 'Tirosint' | 'Flector' | 'Licart'
  
  // Best performing model metrics
  call_success_prob: number  // Max of 3 products
  forecasted_lift: number  // Sum of positive lifts
  ngd_classification: 'New' | 'Grower' | 'Stable' | 'Decliner'  // From product_focus
  wallet_share_growth_avg: number  // Average wallet share growth across products
  
  // Tactical recommendations
  next_best_action: string
  sample_allocation: number
  best_day: string
  best_time: string
}

export interface CompetitiveIntel {
  competitor_rx: { brand: string; trx: number; share: number }[]
  brand_switching: { from: string; to: string; count: number }[]
  opportunity_score: number
  // NEW: From prescriber pattern analysis
  ta_category?: string
  competitive_pressure_score?: number
  competitor_strength?: 'Weak' | 'Moderate' | 'Strong' | 'Dominant'
  competitive_situation?: string
  competitor_trx_est?: number
  growth_opportunity_score?: number
  inferred_competitors?: string[]
  competitor_product_distribution?: { product: string; trx: number }[]
  // NEW: From Model 10 - Competitive Conversion Predictions
  competitive_conversion_target?: boolean
  competitive_conversion_probability?: number
  conversion_likelihood?: 'Low' | 'Medium' | 'High'
  competitive_priority_score?: number
  priority_level?: 'Low' | 'Medium' | 'High'
}

// Call Planning Types
export interface CallPlan {
  id: string
  hcp_npi: string
  hcp_name: string
  territory_id: string
  scheduled_date: string
  priority: number
  action: string
  status: 'scheduled' | 'completed' | 'cancelled'
  tier: string
}

export interface CalendarDay {
  date: string
  calls: CallPlan[]
  capacity: number
  isToday: boolean
}

// Territory Types
export interface Territory {
  id: string
  name: string
  region: string
  rep_name: string
}

export interface TerritoryMetrics {
  total_trx: number
  trx_trend: number
  trx_vs_target: number
  total_calls: number
  call_target: number
  call_attainment: number
  sample_drops: number
  trx_per_call: number
}

export interface TerritoryRanking {
  rank: number
  territory_name: string
  trx: number
  vs_target: number
  vs_prior: number
  sparkline: number[]
}

// Filter Types
export interface HCPFilters {
  territory?: string
  specialty?: string[]
  tier?: string[]
  trx_min?: number
  trx_max?: number
  last_call_from?: string
  last_call_to?: string
  search?: string
}

// Chart Data Types
export interface ChartDataPoint {
  label: string
  value: number
  color?: string
}

export interface TimeSeriesDataPoint {
  date: string
  [key: string]: string | number
}
