'use client'

import { HCPDetail } from '@/lib/types'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { formatNumber } from '@/lib/utils'
import { 
  AlertTriangle, 
  TrendingUp, 
  TrendingDown,
  DollarSign,
  Target,
  Activity,
  Users,
  Package,
  ShieldAlert,
  Sparkles,
  Info
} from 'lucide-react'

interface HCPInsightsProps {
  hcp: HCPDetail
}

/**
 * HCP-Level EDA Insights Component
 * Shows WHY this HCP received their AI predictions
 * Based on Phase 3 EDA analysis findings
 */
export function HCPEDAInsights({ hcp }: HCPInsightsProps) {
  
  // Calculate insights based on EDA thresholds
  const insights = {
    // AT-RISK DETECTION (660 HCPs identified in EDA)
    isAtRisk: hcp.trx_growth < -10 && hcp.ibsa_share > 30,
    atRiskReason: hcp.trx_growth < -10 && hcp.ibsa_share > 30 
      ? `Declining TRx (${hcp.trx_growth.toFixed(1)}%) despite high IBSA share (${hcp.ibsa_share.toFixed(0)}%) - competitive threat detected`
      : null,
    
    // OPPORTUNITY DETECTION (264 HCPs identified in EDA)
    isOpportunity: hcp.trx_current > 50 && hcp.ibsa_share < 25,
    opportunityReason: hcp.trx_current > 50 && hcp.ibsa_share < 25
      ? `High prescribing volume (${formatNumber(hcp.trx_current)} TRx) but low IBSA share (${hcp.ibsa_share.toFixed(0)}%) - ${(100 - hcp.ibsa_share).toFixed(0)}% growth potential`
      : null,
    
    // SAMPLE BLACK HOLE DETECTION - Using forecasted lift as proxy
    // Negative or very low lift suggests samples not converting
    isSampleBlackHole: hcp.predictions.forecasted_lift < 1 && hcp.trx_current > 20,
    sampleBlackHoleReason: hcp.predictions.forecasted_lift < 1 && hcp.trx_current > 20
      ? `Low TRx lift forecast (${hcp.predictions.forecasted_lift.toFixed(1)} TRx) despite prescribing activity - samples may not be converting`
      : null,
    
    // HIGH ROI DETECTION - Using call success and lift predictions
    // High success probability + positive lift = good ROI
    isHighROI: hcp.predictions.call_success_prob > 0.6 && hcp.predictions.forecasted_lift > 5,
    highROIReason: hcp.predictions.call_success_prob > 0.6 && hcp.predictions.forecasted_lift > 5
      ? `Strong ROI potential: ${(hcp.predictions.call_success_prob * 100).toFixed(0)}% call success with +${hcp.predictions.forecasted_lift.toFixed(1)} TRx lift forecast`
      : null,
    
    // SHARE TREND ANALYSIS
    shareDecline: hcp.trx_growth < -5,
    shareGrowth: hcp.trx_growth > 5,
    shareStable: hcp.trx_growth >= -5 && hcp.trx_growth <= 5,
    
    // COMPETITIVE POSITION (from EDA competitive intelligence)
    competitivePosition: 
      hcp.ibsa_share > 50 ? 'IBSA Dominant' :
      hcp.ibsa_share < 25 ? 'Competitor Dominant' :
      'Balanced Competition',
    
    // VOLUME CLASSIFICATION
    volumeClassification:
      hcp.trx_current > 100 ? 'High Volume' :
      hcp.trx_current > 50 ? 'Medium Volume' :
      hcp.trx_current > 20 ? 'Low Volume' :
      'Minimal Volume',
    
    // PRESCRIBING CONSISTENCY (from EDA temporal analysis)
    isPrescribingConsistent: Math.abs(hcp.trx_current - hcp.trx_prior) < 10,
    
    // TIER JUSTIFICATION (from EDA ANOVA tests)
    tierJustification: getTierJustification(hcp),
  }

  return (
    <div className="space-y-4">
      
      {/* Critical Alerts - Show first */}
      <div className="space-y-4">
        
        {/* AT-RISK ALERT (660 HCPs from EDA) */}
        {insights.isAtRisk && (
          <Card className="border-red-300 bg-red-50">
            <CardContent className="pt-4">
              <div className="flex items-start gap-3">
                <AlertTriangle className="h-5 w-5 text-red-600 flex-shrink-0 mt-0.5" />
                <div className="flex-1">
                  <div className="font-semibold text-red-900 mb-1">
                    ⚠️ AT-RISK HCP - RETENTION PRIORITY
                  </div>
                  <p className="text-sm text-red-700 mb-2">
                    {insights.atRiskReason}
                  </p>
                  <div className="text-xs text-red-600 bg-red-100 rounded px-2 py-1 inline-block">
                    📊 EDA Finding: 1 of 660 at-risk HCPs identified (0.74% of universe)
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* OPPORTUNITY ALERT (264 HCPs from EDA) */}
        {insights.isOpportunity && (
          <Card className="border-green-300 bg-green-50">
            <CardContent className="pt-4">
              <div className="flex items-start gap-3">
                <TrendingUp className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
                <div className="flex-1">
                  <div className="font-semibold text-green-900 mb-1">
                    🎯 GROWTH OPPORTUNITY - HIGH POTENTIAL
                  </div>
                  <p className="text-sm text-green-700 mb-2">
                    {insights.opportunityReason}
                  </p>
                  <div className="text-xs text-green-600 bg-green-100 rounded px-2 py-1 inline-block">
                    📊 EDA Finding: 1 of 264 opportunity HCPs identified (0.30% of universe)
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* SAMPLE BLACK HOLE ALERT (48.5% from EDA) */}
        {insights.isSampleBlackHole && (
          <Card className="border-amber-300 bg-amber-50">
            <CardContent className="pt-4">
              <div className="flex items-start gap-3">
                <DollarSign className="h-5 w-5 text-amber-600 flex-shrink-0 mt-0.5" />
                <div className="flex-1">
                  <div className="font-semibold text-amber-900 mb-1">
                    💸 SAMPLE BLACK HOLE - OPTIMIZATION NEEDED
                  </div>
                  <p className="text-sm text-amber-700 mb-2">
                    {insights.sampleBlackHoleReason}
                  </p>
                  <div className="text-xs text-amber-600 bg-amber-100 rounded px-2 py-1 inline-block">
                    📊 EDA Finding: Sample black hole (48.5% of HCPs show ROI &lt; 5%)
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* HIGH ROI RECOGNITION (18.5% from EDA) */}
        {insights.isHighROI && (
          <Card className="border-blue-300 bg-blue-50">
            <CardContent className="pt-4">
              <div className="flex items-start gap-3">
                <Sparkles className="h-5 w-5 text-blue-600 flex-shrink-0 mt-0.5" />
                <div className="flex-1">
                  <div className="font-semibold text-blue-900 mb-1">
                    ⭐ HIGH-VALUE HCP - EXCELLENT ROI
                  </div>
                  <p className="text-sm text-blue-700 mb-2">
                    {insights.highROIReason}
                  </p>
                  <div className="text-xs text-blue-600 bg-blue-100 rounded px-2 py-1 inline-block">
                    📊 EDA Finding: High-ROI HCP (top 18.5% of universe)
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        )}
      </div>

    </div>
  )
}

// Helper component for individual insight cards
function InsightCard({ 
  icon, 
  label, 
  value, 
  detail, 
  color, 
  edaContext 
}: { 
  icon: React.ReactNode
  label: string
  value: string
  detail: string
  color: string
  edaContext: string
}) {
  const colorClasses = {
    green: 'bg-green-100 text-green-800 border-green-300',
    red: 'bg-red-100 text-red-800 border-red-300',
    amber: 'bg-amber-100 text-amber-800 border-amber-300',
    blue: 'bg-blue-100 text-blue-800 border-blue-300',
    indigo: 'bg-indigo-100 text-indigo-800 border-indigo-300',
    purple: 'bg-purple-100 text-purple-800 border-purple-300',
    yellow: 'bg-yellow-100 text-yellow-800 border-yellow-300',
    gray: 'bg-gray-100 text-gray-800 border-gray-300',
    zinc: 'bg-zinc-100 text-zinc-800 border-zinc-300',
  }

  return (
    <div className="border rounded-lg p-3 space-y-2">
      <div className="flex items-center gap-2 text-gray-600">
        {icon}
        <span className="text-xs font-medium">{label}</span>
      </div>
      <div className={`inline-block px-2 py-1 rounded text-sm font-semibold border ${colorClasses[color as keyof typeof colorClasses]}`}>
        {value}
      </div>
      <div className="text-xs text-gray-600">{detail}</div>
      <div className="text-xs text-gray-500 italic pt-1 border-t">
        📊 {edaContext}
      </div>
    </div>
  )
}

// Helper function to determine tier justification
function getTierJustification(hcp: HCPDetail): string {
  if (hcp.tier === 'Platinum') {
    return `High value: ${hcp.trx_current}+ TRx, ${(hcp.ibsa_share * 100).toFixed(0)}% share`
  } else if (hcp.tier === 'Gold') {
    return `Good value: ${hcp.trx_current} TRx, ${(hcp.ibsa_share * 100).toFixed(0)}% share`
  } else if (hcp.tier === 'Silver') {
    return `Moderate value: ${hcp.trx_current} TRx`
  } else {
    return `Lower value: ${hcp.trx_current} TRx`
  }
}
