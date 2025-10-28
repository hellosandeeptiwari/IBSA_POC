/**
 * ML Predictions API
 * Integrates with Phase 6 trained models to provide real-time predictions
 * 
 * ACTUAL MODELS TRAINED:
 * - 3 Products: Tirosint, Flector, Licart
 * - 3 Outcomes per product: call_success, prescription_lift, ngd_category
 * - Total: 9 models
 */

export interface MLPredictions {
  // ============================================================================
  // TIROSINT MODELS (3)
  // ============================================================================
  
  // Model 1: Tirosint Call Success (Binary Classification)
  tirosint_call_success: number  // Probability 0-1
  tirosint_call_success_prediction: boolean  // True if >= 0.5
  
  // Model 2: Tirosint Prescription Lift (Regression)
  tirosint_prescription_lift: number  // Forecasted TRx increase
  
  // Model 3: Tirosint NGD Category (Multi-Class Classification)
  tirosint_ngd_category: 'New' | 'Grower' | 'Stable' | 'Decliner'
  
  // ============================================================================
  // FLECTOR MODELS (3)
  // ============================================================================
  
  // Model 4: Flector Call Success (Binary Classification)
  flector_call_success: number  // Probability 0-1
  flector_call_success_prediction: boolean  // True if >= 0.5
  
  // Model 5: Flector Prescription Lift (Regression)
  flector_prescription_lift: number  // Forecasted TRx increase
  
  // Model 6: Flector NGD Category (Multi-Class Classification)
  flector_ngd_category: 'New' | 'Grower' | 'Stable' | 'Decliner'
  
  // ============================================================================
  // LICART MODELS (3)
  // ============================================================================
  
  // Model 7: Licart Call Success (Binary Classification)
  licart_call_success: number  // Probability 0-1
  licart_call_success_prediction: boolean  // True if >= 0.5
  
  // Model 8: Licart Prescription Lift (Regression)
  licart_prescription_lift: number  // Forecasted TRx increase
  
  // Model 9: Licart NGD Category (Multi-Class Classification)
  licart_ngd_category: 'New' | 'Grower' | 'Stable' | 'Decliner'
}

interface HCPFeatures {
  npi: string
  specialty?: string
  state?: string
  trx_current?: number
  trx_prior?: number
  engagement_score?: number
  value_score?: number
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  [key: string]: any
}

// Cache for predictions to avoid redundant calculations
const predictionCache = new Map<string, { predictions: MLPredictions; timestamp: number }>()
const CACHE_TTL = 5 * 60 * 1000 // 5 minutes

/**
 * Get ML predictions for an HCP
 * Returns predictions from all 9 trained models
 */
export async function getMLPredictions(npi: string): Promise<MLPredictions> {
  // Check cache first
  const cached = predictionCache.get(npi)
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return cached.predictions
  }

  try {
    // TODO: Call FastAPI backend when ready
    // For now, return mock predictions based on NPI
    const predictions = getMockPredictions(npi)
    
    // Cache the result
    predictionCache.set(npi, {
      predictions,
      timestamp: Date.now()
    })
    
    return predictions
  } catch (error) {
    console.error('Error loading predictions:', error)
    return getMockPredictions(npi)
  }
}

/**
 * Generate mock predictions for development
 * TODO: Replace with actual FastAPI calls when backend is ready
 */
function getMockPredictions(npi: string): MLPredictions {
  // Use NPI to generate deterministic random values
  const hash = npi.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0)
  const seed = hash % 100 / 100
  
  const categories: Array<'New' | 'Grower' | 'Stable' | 'Decliner'> = ['New', 'Grower', 'Stable', 'Decliner']
  const categoryIndex = hash % 4
  
  return {
    // Tirosint predictions
    tirosint_call_success: Math.min(0.3 + seed * 0.6, 0.95),
    tirosint_call_success_prediction: seed > 0.4,
    tirosint_prescription_lift: (seed - 0.5) * 20,
    tirosint_ngd_category: categories[categoryIndex],
    
    // Flector predictions
    flector_call_success: Math.min(0.25 + seed * 0.5, 0.85),
    flector_call_success_prediction: seed > 0.5,
    flector_prescription_lift: (seed - 0.5) * 15,
    flector_ngd_category: categories[(categoryIndex + 1) % 4],
    
    // Licart predictions
    licart_call_success: Math.min(0.2 + seed * 0.5, 0.80),
    licart_call_success_prediction: seed > 0.55,
    licart_prescription_lift: (seed - 0.5) * 12,
    licart_ngd_category: categories[(categoryIndex + 2) % 4],
  }
}

/**
 * Batch predictions for multiple HCPs
 */
export async function getBatchPredictions(npis: string[]): Promise<Map<string, MLPredictions>> {
  const results = new Map<string, MLPredictions>()
  
  await Promise.all(
    npis.map(async (npi) => {
      const predictions = await getMLPredictions(npi)
      results.set(npi, predictions)
    })
  )
  
  return results
}
