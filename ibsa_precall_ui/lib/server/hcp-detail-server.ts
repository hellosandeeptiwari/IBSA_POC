import type { HCPDetail, CallHistory } from '../types'

export async function getHCPDetailFromRow(row: any, npiParam: string): Promise<HCPDetail> {
  // Extract NPI from row data
  const npi = String(row.NPI || row.PrescriberId || npiParam || '').replace('.0', '')
  
  // Parse call history from embedded JSON column
  let hcpCallHistory: CallHistory[] = []
  if (row.call_history_json) {
    try {
      const parsed = JSON.parse(row.call_history_json)
      if (Array.isArray(parsed)) {
        hcpCallHistory = parsed
      }
    } catch (error) {
      console.warn(`⚠️ [Server] Failed to parse call_history_json for NPI ${npi}:`, error)
    }
  }
  
  // Map NGD category from predictions
  const mapNGDCategory = (pred: any): 'New' | 'Grower' | 'Stable' | 'Decliner' => {
    if (typeof pred === 'string') {
      const predLower = pred.toLowerCase()
      if (predLower.includes('new')) return 'New'
      if (predLower.includes('grow')) return 'Grower'
      if (predLower.includes('declin')) return 'Decliner'
      return 'Stable'
    }
    return 'Stable'
  }

  // Get product-specific predictions
  const tirosint_cs = Number(row.Tirosint_call_success_prob) || 0
  const tirosint_lift = Number(row.Tirosint_prescription_lift_pred) || 0
  const flector_cs = Number(row.Flector_call_success_prob) || 0
  const flector_lift = Number(row.Flector_prescription_lift_pred) || 0
  const licart_cs = Number(row.Licart_call_success_prob) || 0
  const licart_lift = Number(row.Licart_prescription_lift_pred) || 0

  // Determine best product by call success
  let productFocus = 'Tirosint'
  let bestCallSuccess = tirosint_cs
  if (flector_cs > bestCallSuccess) {
    productFocus = 'Flector'
    bestCallSuccess = flector_cs
  }
  if (licart_cs > bestCallSuccess) {
    productFocus = 'Licart'
    bestCallSuccess = licart_cs
  }

  // Calculate TRx and shares
  const tirosintTrx = Number(row.tirosint_trx) || 0
  const flectorTrx = Number(row.flector_trx) || 0
  const licartTrx = Number(row.licart_trx) || 0
  const competitorTrxTotal = Number(row.competitor_trx) || 0
  const ibsaTrxTotal = tirosintTrx + flectorTrx + licartTrx
  const trxCurrent = ibsaTrxTotal + competitorTrxTotal
  const effectiveIbsaShare = trxCurrent > 0 ? (ibsaTrxTotal / trxCurrent) * 100 : 15

  return {
    npi,
    name: row.PrescriberName || 'Unknown',
    specialty: row.Specialty || 'General Practice',
    territory: row.Territory || row.TerritoryName || row.State || 'Unknown',
    region: '',
    city: row.City || '',
    state: row.State || '',
    tier: String(row.TirosintTargetTier || row.FlectorTargetTier || row.LicartTargetTier || 'N/A'),
    trx_current: trxCurrent,
    trx_prior: 0,
    trx_growth: 0,
    trx_ytd: trxCurrent,
    last_call_date: null,
    days_since_call: null,
    next_call_date: null,
    priority: 0,
    ibsa_share: effectiveIbsaShare,
    ibsa_trx_total: ibsaTrxTotal,
    competitor_trx_total: competitorTrxTotal,
    nrx_count: Number(row.ibsa_nrx_qtd) || 0,
    call_success_score: Number(row.call_success_prob) || 0,
    value_score: Number(row.expected_roi) || 0,
    ngd_decile: 5,
    ngd_classification: (row.ngd_classification as any) || 'Stable',
    address: '',
    phone: '',
    tirosint_trx: tirosintTrx,
    flector_trx: flectorTrx,
    licart_trx: licartTrx,
    competitor_trx: competitorTrxTotal,
    competitor_synthroid_levothyroxine: Number(row.competitor_synthroid_levothyroxine) || 0,
    competitor_voltaren_diclofenac: Number(row.competitor_voltaren_diclofenac) || 0,
    competitor_imdur_nitrates: Number(row.competitor_imdur_nitrates) || 0,
    ibsa_nrx_qtd: Number(row.ibsa_nrx_qtd) || 0,
    competitor_nrx: Number(row.competitor_nrx) || 0,
    competitor_nrx_synthroid_levothyroxine: Number(row.competitor_nrx_synthroid_levothyroxine) || 0,
    competitor_nrx_voltaren_diclofenac: Number(row.competitor_nrx_voltaren_diclofenac) || 0,
    competitor_nrx_imdur_nitrates: Number(row.competitor_nrx_imdur_nitrates) || 0,
    product_mix: [],
    call_history: hcpCallHistory,
    predictions: {
      tirosint_call_success: tirosint_cs,
      tirosint_call_success_prediction: tirosint_cs > 0.5,
      tirosint_prescription_lift: tirosint_lift,
      tirosint_ngd_category: mapNGDCategory(row.Tirosint_ngd_category_pred),
      tirosint_wallet_share_growth: Number(row.Tirosint_wallet_share_growth_pred) || 0,
      flector_call_success: flector_cs,
      flector_call_success_prediction: flector_cs > 0.5,
      flector_prescription_lift: flector_lift,
      flector_ngd_category: mapNGDCategory(row.Flector_ngd_category_pred),
      flector_wallet_share_growth: Number(row.Flector_wallet_share_growth_pred) || 0,
      licart_call_success: licart_cs,
      licart_call_success_prediction: licart_cs > 0.5,
      licart_prescription_lift: licart_lift,
      licart_ngd_category: mapNGDCategory(row.Licart_ngd_category_pred),
      licart_wallet_share_growth: Number(row.Licart_wallet_share_growth_pred) || 0,
      call_success_prob: bestCallSuccess,
      product_focus: productFocus as any,
      next_best_action: row.next_best_action || 'Detail Only',
      sample_allocation: Number(row.sample_allocation) || 3,
      best_day: row.best_day || 'Thursday',
      best_time: row.best_time || '10:00 AM',
      ngd_classification: (row.ngd_classification as any) || 'Stable',
      forecasted_lift: Number(row.forecasted_lift) || 0,
      wallet_share_growth_avg: (Number(row.Tirosint_wallet_share_growth_pred) + Number(row.Flector_wallet_share_growth_pred) + Number(row.Licart_wallet_share_growth_pred)) / 3 || 0
    },
    competitive_intel: {
      competitive_pressure_score: 50,
      inferred_competitors: [],
      competitor_product_distribution: [],
      competitor_rx: [],
      brand_switching: [],
      opportunity_score: 50
    }
  }
}
