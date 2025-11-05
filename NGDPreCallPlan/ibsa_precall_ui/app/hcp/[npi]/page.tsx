'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { getMLPredictions, type MLPredictions } from '@/lib/api/ml-predictions'
import { getHCPDetail } from '@/lib/api/data-loader'
import type { HCPDetail } from '@/lib/types'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { TierBadge } from '@/components/ui/tier-badge'
import { formatNumber, formatPercent } from '@/lib/utils'
import { ArrowLeft, MapPin, TrendingUp, Target, Calendar, Bot, Sparkles, Zap, FileText } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts'
import { AIKeyMessages } from '@/components/ai-key-messages'
import { CallScriptStreaming } from '@/components/call-script-streaming'
import { HCPEDAInsights } from '@/components/hcp-eda-insights'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'

export default function HCPDetailPage() {
  const router = useRouter()
  const resolvedParams = useParams()
  const [hcp, setHcp] = useState<HCPDetail | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadHCPDetail()
  }, [resolvedParams])

  async function loadHCPDetail() {
    setLoading(true)
    const npi = Array.isArray(resolvedParams.npi) ? resolvedParams.npi[0] : resolvedParams.npi as string
    const data = await getHCPDetail(npi)
    console.log('🔍 HCP Detail loaded:', {
      npi: data?.npi,
      name: data?.name,
      call_history_exists: !!data?.call_history,
      call_history_length: data?.call_history?.length || 0,
      call_history_sample: data?.call_history?.[0]
    })
    setHcp(data)
    setLoading(false)
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="text-lg">Loading HCP details...</div>
      </div>
    )
  }

  if (!hcp) {
    const npi = Array.isArray(resolvedParams.npi) ? resolvedParams.npi[0] : resolvedParams.npi as string
    return (
      <div className="flex flex-col items-center justify-center h-screen gap-4">
        <div className="text-lg">HCP not found (NPI: {npi})</div>
        <Button onClick={() => router.push('/')}>Back to Dashboard</Button>
      </div>
    )
  }

  const COLORS = ['#2563eb', '#10b981', '#f59e0b', '#6b7280']

  return (
    <div className="container mx-auto py-6 space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="outline" size="sm" onClick={() => router.push('/')}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back
          </Button>
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-3xl font-bold">{hcp.name}</h1>
              <TierBadge tier={hcp.tier} />
            </div>
            <div className="flex items-center gap-4 text-sm text-muted-foreground mt-1">
              <span>NPI: {hcp.npi || 'Not Available'}</span>
              {hcp.territory && (
                <>
                  <span className="text-gray-300">•</span>
                  <span className="flex items-center gap-1">
                    <MapPin className="h-3 w-3" />
                    Territory: <span className="font-medium text-gray-700">{hcp.territory}</span>
                  </span>
                </>
              )}
              {hcp.region && (
                <>
                  <span className="text-gray-300">•</span>
                  <span className="font-medium text-gray-700">Region: {hcp.region}</span>
                </>
              )}
            </div>
          </div>
        </div>
        
        {/* AI Call Script Generator - Streaming like Claude */}
        <CallScriptStreaming 
          hcpId={hcp.npi}
          hcpName={hcp.name}
          specialty={hcp.specialty}
        />
      </div>

      {/* Pre-Call Planning Summary */}
      <Card className="border-2 border-purple-200 bg-gradient-to-br from-purple-50 to-blue-50 shadow-sm">
        <CardHeader className="bg-gradient-to-r from-purple-600 to-blue-600 border-b">
          <CardTitle className="flex items-center gap-2 text-white">
            <Bot className="h-5 w-5" />
            Pre-Call Planning: What To Say & Do
          </CardTitle>
          <p className="text-xs text-purple-100 mt-1 flex items-center gap-2">
            <Sparkles className="h-3 w-3" />
            AI-generated call strategy • <span className="bg-purple-900/30 px-2 py-0.5 rounded-md backdrop-blur-sm font-medium">AI Predictions Highlighted</span>
          </p>
        </CardHeader>
        <CardContent className="pt-4">
          <div className="space-y-4">
            {/* Main Call Message */}
            <div className="border-l-4 border-purple-500 bg-purple-50/50 rounded p-4 border-2 border-dashed border-purple-300">
              <div className="text-xs font-semibold text-purple-700 mb-2 flex items-center gap-1">
                <Target className="h-3 w-3" />
                🎯 PRIMARY CALL OBJECTIVE
                <span className="ml-auto bg-purple-200 text-purple-800 px-2 py-0.5 rounded-full text-[10px] font-bold">AI GENERATED</span>
              </div>
              <p className="text-lg font-semibold text-gray-900 leading-tight">
                {(() => {
                  // Get product-specific metrics
                  const productCallSuccess = hcp.predictions.product_focus === 'Tirosint' ? hcp.predictions.tirosint_call_success :
                                            hcp.predictions.product_focus === 'Flector' ? hcp.predictions.flector_call_success :
                                            hcp.predictions.licart_call_success
                  
                  const productLift = hcp.predictions.product_focus === 'Tirosint' ? hcp.predictions.tirosint_prescription_lift :
                                     hcp.predictions.product_focus === 'Flector' ? hcp.predictions.flector_prescription_lift :
                                     hcp.predictions.licart_prescription_lift
                  
                  const currentShare = hcp.ibsa_share > 0 ? hcp.ibsa_share.toFixed(0) : 0
                  
                  if (hcp.predictions.ngd_classification === 'Grower') {
                    return <>Grow {hcp.predictions.product_focus} to <span className="bg-green-200 border border-green-400 px-2 py-0.5 rounded font-bold">+{formatNumber(productLift, 1)} TRx</span> potential</>
                  } else if (hcp.predictions.ngd_classification === 'Decliner') {
                    return <>Retain prescriber - <span className="bg-red-200 border border-red-400 px-2 py-0.5 rounded font-bold">{hcp.predictions.ngd_classification}</span> status, address concerns</>
                  } else if (hcp.predictions.ngd_classification === 'New') {
                    return <>Introduce {hcp.predictions.product_focus} - <span className="bg-blue-200 border border-blue-400 px-2 py-0.5 rounded font-bold">{hcp.predictions.ngd_classification}</span> prescriber opportunity</>
                  } else {
                    return <>Maintain {hcp.predictions.product_focus} - <span className="bg-gray-200 border border-gray-400 px-2 py-0.5 rounded font-bold">Stable</span> relationship</>
                  }
                })()}
              </p>
            </div>
              
            {/* AI Model Insights - RECOMMENDED PRODUCT */}
            <div className="bg-purple-50 border-l-4 border-purple-600 rounded p-4 border-2 border-dashed border-purple-300">
              <div className="text-xs font-semibold text-purple-700 mb-3 flex items-center gap-1">
                <Bot className="h-4 w-4" />
                🎯 RECOMMENDED PRODUCT: {hcp.predictions.product_focus}
                <span className="ml-2 bg-purple-200 text-purple-800 px-2 py-0.5 rounded-full text-[10px]">AI selected from 9 models</span>
                <span className="ml-auto bg-purple-600 text-white px-2 py-0.5 rounded-full text-[10px] font-bold">FOCUS HERE</span>
              </div>
              <div className="grid grid-cols-2 gap-3 text-sm">
                <div className="flex items-center gap-2">
                  <Sparkles className="h-3 w-3 text-purple-600 flex-shrink-0" />
                  <span className="text-gray-600">Growth Probability:</span>
                  <span className="ml-auto bg-green-200 border-2 border-green-500 px-3 py-1 rounded font-bold text-green-800" title="Likelihood of prescription growth (not call completion)">
                    {hcp.predictions.product_focus === 'Tirosint' ? formatPercent(hcp.predictions.tirosint_call_success, 0) :
                     hcp.predictions.product_focus === 'Flector' ? formatPercent(hcp.predictions.flector_call_success, 0) :
                     formatPercent(hcp.predictions.licart_call_success, 0)}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <Bot className="h-3 w-3 text-purple-600 flex-shrink-0" />
                  <span className="text-gray-600">Expected TRx Lift:</span>
                  <span className="ml-auto bg-green-200 border-2 border-green-500 px-3 py-1 rounded font-bold text-green-800">
                    {hcp.predictions.product_focus === 'Tirosint' ? `${hcp.predictions.tirosint_prescription_lift >= 0 ? '+' : ''}${formatNumber(hcp.predictions.tirosint_prescription_lift, 1)}` :
                     hcp.predictions.product_focus === 'Flector' ? `${hcp.predictions.flector_prescription_lift >= 0 ? '+' : ''}${formatNumber(hcp.predictions.flector_prescription_lift, 1)}` :
                     `${hcp.predictions.licart_prescription_lift >= 0 ? '+' : ''}${formatNumber(hcp.predictions.licart_prescription_lift, 1)}`}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <Bot className="h-3 w-3 text-purple-600 flex-shrink-0" />
                  <span className="text-gray-600">NGD Category:</span>
                  <span className="ml-auto bg-purple-200 border border-purple-400 px-2 py-0.5 rounded font-semibold inline-flex items-center gap-1">
                    {hcp.predictions.product_focus === 'Tirosint' ? hcp.predictions.tirosint_ngd_category :
                     hcp.predictions.product_focus === 'Flector' ? hcp.predictions.flector_ngd_category :
                     hcp.predictions.licart_ngd_category}
                    <span className="text-[10px] opacity-75">
                      ({formatPercent(hcp.predictions.growth_probability, 0)} growth probability)
                    </span>
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <Bot className="h-3 w-3 text-purple-600 flex-shrink-0" />
                  <span className="text-gray-600">Next Best Action:</span>
                  <span className="ml-auto bg-purple-200 border border-purple-400 px-2 py-0.5 rounded font-semibold inline-flex items-center gap-1">
                    {hcp.predictions.next_best_action}
                    <span className="text-[10px] bg-purple-600 text-white px-1 rounded">
                      {hcp.predictions.sample_allocation >= 12 ? 'High ROI' : hcp.predictions.sample_allocation >= 8 ? 'Moderate ROI' : 'Selective'}
                    </span>
                  </span>
                </div>
              </div>
              <div className="mt-3 pt-3 border-t border-purple-200 text-xs bg-blue-50 p-3 rounded border border-blue-200">
                <strong className="text-blue-900">Why {hcp.predictions.product_focus}?</strong>
                <ul className="mt-2 space-y-1 ml-4 text-gray-700">
                  <li>✓ <strong>Highest Success Rate:</strong> {formatPercent(
                    hcp.predictions.product_focus === 'Tirosint' ? hcp.predictions.tirosint_call_success :
                    hcp.predictions.product_focus === 'Flector' ? hcp.predictions.flector_call_success :
                    hcp.predictions.licart_call_success, 0
                  )} vs {formatPercent(
                    hcp.predictions.product_focus === 'Tirosint' ? Math.max(hcp.predictions.flector_call_success, hcp.predictions.licart_call_success) :
                    hcp.predictions.product_focus === 'Flector' ? Math.max(hcp.predictions.tirosint_call_success, hcp.predictions.licart_call_success) :
                    Math.max(hcp.predictions.tirosint_call_success, hcp.predictions.flector_call_success), 0
                  )} for next best</li>
                  <li>✓ <strong>Best Lift Potential:</strong> {
                    hcp.predictions.product_focus === 'Tirosint' ? `+${formatNumber(hcp.predictions.tirosint_prescription_lift, 1)}` :
                    hcp.predictions.product_focus === 'Flector' ? `+${formatNumber(hcp.predictions.flector_prescription_lift, 1)}` :
                    `+${formatNumber(hcp.predictions.licart_prescription_lift, 1)}`
                  } TRx forecasted</li>
                  <li>✓ <strong>Specialty Match:</strong> {hcp.specialty} prescribers show optimal outcomes with {hcp.predictions.product_focus}
                    {hcp.specialty.toLowerCase().includes('endocrin') ? ' (Thyroid disorder focus)' :
                     hcp.specialty.toLowerCase().includes('pain') ? ' (Pain management focus)' :
                     hcp.specialty.toLowerCase().includes('internal') ? ' (Broad therapeutic scope)' :
                     ''}</li>
                  {(hcp.competitive_intel?.competitive_pressure_score || 0) > 70 && (
                    <li>⚠️ <strong>Competitive Defense:</strong> {hcp.competitive_intel?.competitor_strength || 'Strong'} pressure detected - {hcp.predictions.product_focus} offers key differentiation</li>
                  )}
                </ul>
              </div>
              
              {/* Simplified product comparison - only show if recommended product is not obvious */}
              <div className="mt-3 border-t pt-3 border-purple-200">
                <div className="text-xs font-semibold text-gray-700 mb-2">
                  Other Products Available:
                </div>
                <div className="grid grid-cols-3 gap-2 text-xs">
                  <div className={`p-2 rounded border ${hcp.predictions.product_focus === 'Tirosint' ? 'border-green-500 bg-green-50 ring-2 ring-green-300' : 'border-gray-200 opacity-60'}`}>
                    <div className="font-semibold flex items-center gap-1">
                      Tirosint
                      {hcp.predictions.product_focus === 'Tirosint' && <span className="text-[10px] bg-green-600 text-white px-1 rounded">BEST</span>}
                    </div>
                    <div className="text-[10px] text-gray-600 mt-1">Growth: {formatPercent(hcp.predictions.tirosint_call_success, 0)}</div>
                    <div className="text-[10px] text-gray-600">Lift: {hcp.predictions.tirosint_prescription_lift >= 0 ? '+' : ''}{formatNumber(hcp.predictions.tirosint_prescription_lift, 1)} TRx</div>
                    <div className="text-[10px] text-gray-600">Status: {hcp.predictions.tirosint_ngd_category}</div>
                  </div>
                  <div className={`p-2 rounded border ${hcp.predictions.product_focus === 'Flector' ? 'border-green-500 bg-green-50 ring-2 ring-green-300' : 'border-gray-200 opacity-60'}`}>
                    <div className="font-semibold flex items-center gap-1">
                      Flector
                      {hcp.predictions.product_focus === 'Flector' && <span className="text-[10px] bg-green-600 text-white px-1 rounded">BEST</span>}
                    </div>
                    <div className="text-[10px] text-gray-600 mt-1">Growth: {formatPercent(hcp.predictions.flector_call_success, 0)}</div>
                    <div className="text-[10px] text-gray-600">Lift: {hcp.predictions.flector_prescription_lift >= 0 ? '+' : ''}{formatNumber(hcp.predictions.flector_prescription_lift, 1)} TRx</div>
                    <div className="text-[10px] text-gray-600">Status: {hcp.predictions.flector_ngd_category}</div>
                  </div>
                  <div className={`p-2 rounded border ${hcp.predictions.product_focus === 'Licart' ? 'border-green-500 bg-green-50 ring-2 ring-green-300' : 'border-gray-200 opacity-60'}`}>
                    <div className="font-semibold flex items-center gap-1">
                      Licart
                      {hcp.predictions.product_focus === 'Licart' && <span className="text-[10px] bg-green-600 text-white px-1 rounded">BEST</span>}
                    </div>
                    <div className="text-[10px] text-gray-600 mt-1">Growth: {formatPercent(hcp.predictions.licart_call_success, 0)}</div>
                    <div className="text-[10px] text-gray-600">Lift: {hcp.predictions.licart_prescription_lift >= 0 ? '+' : ''}{formatNumber(hcp.predictions.licart_prescription_lift, 1)} TRx</div>
                    <div className="text-[10px] text-gray-600">Status: {hcp.predictions.licart_ngd_category}</div>
                  </div>
                </div>
                <div className="text-[11px] text-gray-500 italic mt-2">
                  ℹ️ {hcp.predictions.product_focus} recommended based on highest success rate
                </div>
              </div>
            </div>

            {/* Opening Line */}
            <div className="border-l-4 border-gray-400 bg-gray-50 rounded p-4">
              <div className="text-xs font-semibold text-gray-600 mb-2">💬 OPENING LINE:</div>
              <p className="text-sm text-gray-800 italic">
                {hcp.predictions.ngd_classification === 'Decliner'
                  ? <>"I noticed some changes in prescribing patterns and wanted to understand what's driving your treatment decisions. Based on our analysis, I have insights that could help address competitive challenges you may be facing in your practice."</>
                  : hcp.predictions.ngd_classification === 'New'
                  ? <>"Welcome to prescribing! I'd like to share how <span className="bg-blue-200 border border-blue-400 px-1 not-italic font-medium">{hcp.predictions.product_focus}</span> could benefit your patient population, with clinical data showing strong outcomes for {hcp.specialty.toLowerCase()} practices."</>
                  : hcp.predictions.ngd_classification === 'Grower'
                  ? <>"I see you're increasing prescriptions - our predictive model shows <span className="bg-green-200 border border-green-400 px-1 not-italic font-medium">{formatPercent(hcp.predictions.growth_probability || 0, 0)} growth probability</span>. I have data showing how to accelerate this momentum with <span className="bg-blue-200 border border-blue-400 px-1 not-italic font-medium">{hcp.predictions.product_focus}</span> for your patients."</>
                  : <>"Thank you for your continued partnership. I have updates that align with your practice focus and can help optimize patient outcomes with our latest clinical evidence."</>
                }
              </p>
            </div>

            {/* Action Items */}
            <div className="border border-purple-300 rounded p-4 border-2 border-dashed bg-purple-50/30">
              <div className="text-xs font-semibold text-purple-700 mb-3 flex items-center gap-1">
                <Zap className="h-3 w-3" />
                ✅ ACTION ITEMS
                <span className="ml-2 text-purple-600 text-[10px]">(based on ML predictions)</span>
              </div>
              <ul className="space-y-2 text-sm text-gray-700">
                <li className="flex items-start gap-2">
                  <span className="text-purple-400">•</span>
                  <span><strong>Bring:</strong> <span className="bg-purple-200 border border-purple-400 px-1 font-semibold inline-flex items-center gap-1"><Bot className="h-3 w-3" />{hcp.predictions.sample_allocation} samples</span> for <span className="bg-purple-200 border border-purple-400 px-1 font-semibold inline-flex items-center gap-1"><Sparkles className="h-3 w-3" />{hcp.predictions.product_focus}</span> + clinical data
                  <span className="text-xs text-gray-500 ml-2 italic">(Calculated: Tier {hcp.tier} × Call Success {formatPercent(
                    hcp.predictions.product_focus === 'Tirosint' ? hcp.predictions.tirosint_call_success :
                    hcp.predictions.product_focus === 'Flector' ? hcp.predictions.flector_call_success :
                    hcp.predictions.licart_call_success, 0
                  )} × Rx Lift {formatNumber(
                    hcp.predictions.product_focus === 'Tirosint' ? hcp.predictions.tirosint_prescription_lift :
                    hcp.predictions.product_focus === 'Flector' ? hcp.predictions.flector_prescription_lift :
                    hcp.predictions.licart_prescription_lift, 1
                  )})</span>
                  </span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-purple-400">•</span>
                  <div className="flex-1">
                    <strong>Discuss:</strong>
                    <ul className="ml-4 mt-1 space-y-1 text-xs">
                      {hcp.predictions.ngd_classification === 'Decliner' && (
                        <>
                          <li>
                            <strong>Likely Competitors:</strong>
                            <div className="ml-4 mt-1">
                              {hcp.competitive_intel?.competitor_product_distribution?.map((comp, idx) => (
                                <div key={idx} className="text-xs">
                                  • <span className="font-semibold">{comp.product}</span>: ~{comp.trx} writes
                                </div>
                              )) || (
                                <div className="text-xs">
                                  • {hcp.competitive_intel?.inferred_competitors?.slice(0,3).join(', ') || 'Generic competitors'}
                                </div>
                              )}
                              <div className="text-[10px] text-gray-500 mt-1">
                                (Based on {hcp.specialty} prescribing patterns)
                              </div>
                            </div>
                          </li>
                          <li>• Address {hcp.competitive_intel?.competitor_strength?.toLowerCase() || 'competitive'} competitive pressure ({hcp.competitive_intel?.competitive_pressure_score || 0}/100 intensity)</li>
                          <li>• Opportunity to recover {(100 - hcp.ibsa_share).toFixed(0)}% market share ({formatNumber(Math.round(hcp.trx_current * ((100 - hcp.ibsa_share) / 100)))} TRx gap to close)</li>
                          <li>• {hcp.predictions.product_focus} differentiation vs {hcp.competitive_intel?.competitor_product_distribution?.[0]?.product || hcp.competitive_intel?.inferred_competitors?.[0] || 'competitors'} (show comparative data)</li>
                        </>
                      )}
                      {hcp.predictions.ngd_classification === 'Grower' && (
                        <>
                          <li>
                            <strong>IBSA Product Growth Analysis:</strong>
                            <div className="ml-4 mt-1">
                              <div className="text-xs">• <span className="font-semibold text-green-600">Tirosint:</span> {hcp.predictions.tirosint_ngd_category} (+{formatNumber(hcp.predictions.tirosint_prescription_lift)} TRx lift potential)</div>
                              <div className="text-xs">• <span className="font-semibold text-blue-600">Flector:</span> {hcp.predictions.flector_ngd_category} (+{formatNumber(hcp.predictions.flector_prescription_lift)} TRx lift potential)</div>
                              <div className="text-xs">• <span className="font-semibold text-purple-600">Licart:</span> {hcp.predictions.licart_ngd_category} (+{formatNumber(hcp.predictions.licart_prescription_lift)} TRx lift potential)</div>
                              <div className="text-[10px] text-gray-500 mt-1">
                                (Focus on products with highest growth momentum)
                              </div>
                            </div>
                          </li>
                          <li>• Accelerate {formatPercent(hcp.trx_growth, 1)} growth momentum with {hcp.predictions.product_focus} (highest lift: +{formatNumber(hcp.rx_lift || 0)} TRx)</li>
                          <li>• Expand usage in additional patient segments (current: {hcp.ibsa_share.toFixed(0)}% IBSA share, target: {Math.min(hcp.ibsa_share + 15, 80).toFixed(0)}%)</li>
                          <li>• Competitive position: {hcp.competitive_intel?.competitive_pressure_score && hcp.competitive_intel.competitive_pressure_score > 60 ? `Monitor ${hcp.competitive_intel.competitor_product_distribution?.[0]?.product || 'competitor'} activity` : 'Maintain lead with consistent engagement'}</li>
                        </>
                      )}
                      {hcp.predictions.ngd_classification === 'New' && (
                        <>
                          <li>
                            <strong>Market Entry Opportunity:</strong>
                            <div className="ml-4 mt-1">
                              <div className="text-xs">• <span className="font-semibold">First-mover advantage:</span> {hcp.competitive_intel?.competitive_situation === 'Not Using IBSA' ? 'Establish IBSA as preferred brand' : 'Early adoption window open'}</div>
                              <div className="text-xs">• <span className="font-semibold">Competitive landscape:</span> {hcp.competitive_intel?.competitor_product_distribution?.map(c => c.product).slice(0,2).join(' and ') || 'Generic competitors'} currently prescribe ~{formatNumber(hcp.competitor_trx_total || 0)} TRx</div>
                              <div className="text-[10px] text-gray-500 mt-1">
                                (Position {hcp.predictions.product_focus} as superior alternative)
                              </div>
                            </div>
                          </li>
                          <li>• Product introduction: {hcp.predictions.product_focus} clinical profile and patient selection criteria</li>
                          <li>• Formulary status and payer coverage (address access barriers proactively)</li>
                          <li>• Initial prescribing protocol: Start with {hcp.predictions.sample_allocation} samples + first prescription follow-up</li>
                        </>
                      )}
                      {hcp.predictions.ngd_classification === 'Stable' && (
                        <>
                          <li>
                            <strong>Retention & Share Defense:</strong>
                            <div className="ml-4 mt-1">
                              <div className="text-xs">• <span className="font-semibold">Current position:</span> {hcp.ibsa_share.toFixed(0)}% IBSA share ({formatNumber(Math.round(hcp.trx_current * hcp.ibsa_share / 100))} of {formatNumber(hcp.trx_current)} TRx)</div>
                              <div className="text-xs">• <span className="font-semibold">Competitive threats:</span> {hcp.competitive_intel?.competitive_pressure_score && hcp.competitive_intel.competitive_pressure_score > 50 ? `${hcp.competitive_intel.competitor_strength} pressure from ${hcp.competitive_intel.competitor_product_distribution?.[0]?.product || 'competitors'}` : 'Low competitive risk - maintain relationship'}</div>
                              <div className="text-xs">• <span className="font-semibold">Risk assessment:</span> {hcp.competitive_intel?.competitive_conversion_target ? '⚠️ High conversion risk - increase engagement' : '✓ Stable prescriber - standard cadence'}</div>
                            </div>
                          </li>
                          <li>• Maintain {hcp.ibsa_share.toFixed(0)}% IBSA share with consistent engagement (target: {Math.min(hcp.ibsa_share + 10, 90).toFixed(0)}%)</li>
                          <li>• Treatment optimization: Share new clinical evidence for {hcp.predictions.product_focus}</li>
                          <li>• Patient outcomes review and satisfaction tracking (prevent erosion)</li>
                        </>
                      )}
                    </ul>
                  </div>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-purple-400">•</span>
                  <div className="flex-1">
                    <strong>Position:</strong>
                    <div className="ml-4 mt-1 p-2 bg-blue-50 rounded text-xs text-gray-700">
                      Focus on <strong>{hcp.predictions.product_focus}</strong> messaging tailored to <strong>{hcp.predictions.ngd_classification}</strong> prescribers with {hcp.specialty.toLowerCase()} practice focus.
                      {(hcp.competitive_intel?.competitive_pressure_score || 0) > 70 && (
                        <div className="mt-1 text-red-700">
                          ⚠️ High competitive pressure ({hcp.competitive_intel?.competitive_pressure_score}/100) detected - emphasize {hcp.predictions.product_focus} differentiation.
                        </div>
                      )}
                      <div className="mt-1 text-xs text-gray-600 italic">
                        Note: Use MLR-approved messaging from call script generator for specific clinical claims.
                      </div>

                      {/* MLR-Approved Competitive Messaging */}
                      <div className="mt-3 p-3 bg-green-50 border border-green-200 rounded">
                        <div className="text-xs font-semibold text-green-800 mb-2 flex items-center gap-1">
                          ✅ MLR-APPROVED COMPETITIVE MESSAGING
                          <span className="ml-auto text-[10px] bg-green-600 text-white px-2 py-0.5 rounded-full">COMPLIANT</span>
                        </div>
                        
                        {/* Show relevant messaging based on HCP situation */}
                        {hcp.predictions.ngd_classification === 'Decliner' && (hcp.competitive_intel?.competitive_pressure_score || 0) > 60 && (
                          <div className="space-y-2 text-xs">
                            <div className="bg-white p-2 rounded border-l-2 border-green-500">
                              <div className="font-semibold text-gray-800">For Persistent Symptoms Discussion:</div>
                              <div className="text-gray-700 mt-1">"Many patients continue to experience symptoms even when their TSH levels appear normal with their current therapy. {hcp.predictions.product_focus} offers an alternative approach worth considering."</div>
                              <div className="text-[10px] text-gray-500 mt-1">MLR ID: WEB-TIR-SYMPTOMS-2025 | Expires: 2025-12-31</div>
                            </div>
                            
                            <div className="bg-white p-2 rounded border-l-2 border-green-500">
                              <div className="font-semibold text-gray-800">Objection Handler - Price Concerns:</div>
                              <div className="text-gray-700 mt-1">"While {hcp.competitive_intel?.competitor_product_distribution?.[0]?.product || 'generic options'} may have lower acquisition costs, consider total cost including patient compliance, symptom management, and dosing stability with {hcp.predictions.product_focus}."</div>
                              <div className="text-[10px] text-gray-500 mt-1">MLR ID: PRICE-OBJ-001 | Approved Comparison</div>
                            </div>
                          </div>
                        )}
                        
                        {hcp.predictions.ngd_classification === 'Grower' && (
                          <div className="space-y-2 text-xs">
                            <div className="bg-white p-2 rounded border-l-2 border-green-500">
                              <div className="font-semibold text-gray-800">Growth Momentum Messaging:</div>
                              <div className="text-gray-700 mt-1">"Our predictive model shows {formatPercent(hcp.predictions.growth_probability, 0)} growth probability with {hcp.predictions.product_focus}. Latest clinical evidence supports expanding usage across additional patient segments."</div>
                              <div className="text-[10px] text-gray-500 mt-1">MLR ID: GROWTH-EXPAND-001 | Treatment Expansion</div>
                            </div>
                          </div>
                        )}
                        
                        {hcp.predictions.ngd_classification === 'New' && (
                          <div className="space-y-2 text-xs">
                            <div className="bg-white p-2 rounded border-l-2 border-green-500">
                              <div className="font-semibold text-gray-800">First Prescription Messaging:</div>
                              <div className="text-gray-700 mt-1">"{hcp.predictions.product_focus} (levothyroxine sodium) replaces a hormone normally produced by the thyroid gland to treat hypothyroidism. Consider for patients requiring precise thyroid replacement."</div>
                              <div className="text-[10px] text-gray-500 mt-1">MLR ID: WEB-TIR-USE-2025 | Primary Indication</div>
                            </div>
                          </div>
                        )}
                        
                        {hcp.predictions.ngd_classification === 'Stable' && (hcp.competitive_intel?.competitive_pressure_score || 0) > 50 && (
                          <div className="space-y-2 text-xs">
                            <div className="bg-white p-2 rounded border-l-2 border-green-500">
                              <div className="font-semibold text-gray-800">Retention Messaging:</div>
                              <div className="text-gray-700 mt-1">"Your consistent results with {hcp.predictions.product_focus} demonstrate effective therapy. Recent updates in formulation and patient support programs enhance the value proposition."</div>
                              <div className="text-[10px] text-gray-500 mt-1">MLR ID: STABLE-RETAIN-001 | Loyalty Enhancement</div>
                            </div>
                          </div>
                        )}
                        
                        <div className="mt-2 pt-2 border-t border-green-200 text-[10px] text-gray-600">
                          💡 <strong>Note:</strong> All messaging is MLR-approved and compliant with promotional guidelines. 
                          Full call script with additional approved claims available in "AI Call Script" tab.
                        </div>
                      </div>
                    </div>
                  </div>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-purple-400">•</span>
                  <span><strong>Close with:</strong> Schedule follow-up on <span className="bg-purple-200 border border-purple-400 px-1 font-semibold inline-flex items-center gap-1"><Zap className="h-3 w-3" />{hcp.predictions.best_day} {hcp.predictions.best_time}</span>
                  <span className="text-xs text-gray-500 ml-2 italic">(Optimal timing based on {hcp.specialty} practice patterns)</span>
                  </span>
                </li>
              </ul>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* EDA Business Intelligence - Why This HCP? */}
      <HCPEDAInsights hcp={hcp} />

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">Current TRx</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{formatNumber(hcp.trx_current)}</div>
            <div className={`text-sm ${hcp.trx_growth >= 0 ? 'text-green-600' : 'text-red-600'}`}>
              {hcp.trx_growth >= 0 ? '' : ''} {formatPercent(Math.abs(hcp.trx_growth), 1)} vs prior
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">YTD TRx</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{formatNumber(hcp.trx_ytd)}</div>
            <div className="text-sm text-muted-foreground">Year to date</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">IBSA Share</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{formatPercent(hcp.ibsa_share, 0)}</div>
            <div className="text-sm text-muted-foreground">Market share</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">NRx Count</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{formatNumber(hcp.nrx_count)}</div>
            <div className="text-sm text-muted-foreground">New prescriptions</div>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card>
          <CardHeader>
            <CardTitle>Competitive Intelligence - Product Breakdown</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {/* IBSA vs Competitor Summary */}
              <div className="grid grid-cols-2 gap-4 pb-4 border-b">
                <div>
                  <div className="text-xs text-muted-foreground mb-1">IBSA Products</div>
                  <div className="text-2xl font-bold text-blue-600">{formatNumber(hcp.ibsa_trx_total)} TRx</div>
                  <div className="text-xs text-muted-foreground">{formatNumber(hcp.ibsa_nrx_qtd || 0)} NRx</div>
                </div>
                <div>
                  <div className="text-xs text-muted-foreground mb-1">Competitor Products</div>
                  <div className="text-2xl font-bold text-orange-600">{formatNumber(hcp.competitor_trx_total)} TRx</div>
                  <div className="text-xs text-muted-foreground">{formatNumber(hcp.competitor_nrx || 0)} NRx</div>
                </div>
              </div>

              {/* Top Competitor Products */}
              <div>
                <div className="text-sm font-semibold mb-2">Top Competitor Products</div>
                <div className="space-y-2">
                  {hcp.competitor_products && hcp.competitor_products.length > 0 ? (
                    hcp.competitor_products.slice(0, 3).map((product: any, idx: number) => (
                      <div key={idx} className="flex items-center justify-between py-2 px-3 bg-orange-50 rounded">
                        <div>
                          <div className="text-sm font-medium">{product.product_name}</div>
                          <div className="text-xs text-muted-foreground">{product.category}</div>
                        </div>
                        <div className="text-right">
                          <div className="text-sm font-semibold">{formatNumber(product.trx)} TRx</div>
                          <div className="text-xs text-muted-foreground">{product.market_share}%</div>
                        </div>
                      </div>
                    ))
                  ) : (
                    <div className="space-y-2">
                      <div className="flex items-center justify-between py-2 px-3 bg-orange-50 rounded">
                        <div>
                          <div className="text-sm font-medium">Synthroid/Levothyroxine</div>
                          <div className="text-xs text-muted-foreground">Thyroid</div>
                        </div>
                        <div className="text-right">
                          <div className="text-sm font-semibold">{formatNumber(hcp.competitor_synthroid_levothyroxine || 0)} TRx</div>
                          <div className="text-xs text-muted-foreground">
                            {hcp.competitor_trx_total > 0 ? Math.round((hcp.competitor_synthroid_levothyroxine || 0) / hcp.competitor_trx_total * 100) : 0}%
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center justify-between py-2 px-3 bg-orange-50 rounded">
                        <div>
                          <div className="text-sm font-medium">Voltaren/Diclofenac</div>
                          <div className="text-xs text-muted-foreground">Pain</div>
                        </div>
                        <div className="text-right">
                          <div className="text-sm font-semibold">{formatNumber(hcp.competitor_voltaren_diclofenac || 0)} TRx</div>
                          <div className="text-xs text-muted-foreground">
                            {hcp.competitor_trx_total > 0 ? Math.round((hcp.competitor_voltaren_diclofenac || 0) / hcp.competitor_trx_total * 100) : 0}%
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center justify-between py-2 px-3 bg-orange-50 rounded">
                        <div>
                          <div className="text-sm font-medium">Imdur/Nitrates</div>
                          <div className="text-xs text-muted-foreground">Cardiac</div>
                        </div>
                        <div className="text-right">
                          <div className="text-sm font-semibold">{formatNumber(hcp.competitor_imdur_nitrates || 0)} TRx</div>
                          <div className="text-xs text-muted-foreground">
                            {hcp.competitor_trx_total > 0 ? Math.round((hcp.competitor_imdur_nitrates || 0) / hcp.competitor_trx_total * 100) : 0}%
                          </div>
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              </div>

              {/* Competitive Pressure Score */}
              <div className="pt-3 border-t">
                <div className="flex items-center justify-between text-sm mb-2">
                  <span className="text-muted-foreground">Competitive Pressure</span>
                  <span className={`font-semibold ${
                    hcp.competitive_intel?.competitive_pressure_score > 70 ? 'text-red-600' :
                    hcp.competitive_intel?.competitive_pressure_score > 40 ? 'text-orange-600' :
                    'text-green-600'
                  }`}>
                    {hcp.competitive_intel?.competitive_pressure_score || Math.round((hcp.competitor_trx_total / (hcp.ibsa_trx_total + hcp.competitor_trx_total)) * 100)}%
                  </span>
                </div>
                <div className="flex-1 bg-gray-200 rounded-full h-2">
                  <div
                    className={`h-2 rounded-full ${
                      (hcp.competitive_intel?.competitive_pressure_score || 0) > 70 ? 'bg-red-500' :
                      (hcp.competitive_intel?.competitive_pressure_score || 0) > 40 ? 'bg-orange-500' :
                      'bg-green-500'
                    }`}
                    style={{ width: `${Math.min(hcp.competitive_intel?.competitive_pressure_score || Math.round((hcp.competitor_trx_total / (hcp.ibsa_trx_total + hcp.competitor_trx_total)) * 100), 100)}%` }}
                  />
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Market Share Breakdown (TRx + NRx)</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <BarChart 
                data={[
                  { 
                    category: 'IBSA', 
                    trx: hcp.ibsa_trx_total, 
                    nrx: hcp.ibsa_nrx_qtd || 0 
                  },
                  { 
                    category: 'Competitors', 
                    trx: hcp.competitor_trx_total, 
                    nrx: hcp.competitor_nrx || 0 
                  }
                ]}
                layout="vertical"
                margin={{ left: 80 }}
              >
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis type="number" />
                <YAxis dataKey="category" type="category" />
                <Tooltip 
                  formatter={(value: any, name: string) => [
                    `${formatNumber(value)} Rx`,
                    name === 'trx' ? 'Total Rx' : 'New Rx'
                  ]}
                />
                <Bar dataKey="trx" stackId="a" fill="#2563eb" name="TRx" />
                <Bar dataKey="nrx" stackId="a" fill="#93c5fd" name="NRx" />
              </BarChart>
            </ResponsiveContainer>
            {/* Market Share Progress Bar */}
            <div className="pt-4 border-t">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm font-medium">IBSA Market Share</span>
                <span className={`text-xl font-bold ${
                  hcp.ibsa_share >= 50 ? 'text-green-600' :
                  hcp.ibsa_share >= 30 ? 'text-blue-600' :
                  'text-amber-600'
                }`}>
                  {formatPercent(hcp.ibsa_share, 0)}
                </span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-5 mb-3">
                <div
                  className={`h-5 rounded-full flex items-center justify-end pr-2 text-white text-xs font-semibold ${
                    hcp.ibsa_share >= 50 ? 'bg-green-500' :
                    hcp.ibsa_share >= 30 ? 'bg-blue-500' :
                    'bg-amber-500'
                  }`}
                  style={{ width: `${hcp.ibsa_share}%` }}
                >
                  {hcp.ibsa_share >= 20 ? 'IBSA' : ''}
                </div>
              </div>
            </div>

            {/* TRx Breakdown Grid */}
            <div className="grid grid-cols-3 gap-3">
              <div className="text-center p-3 bg-blue-50 rounded-lg">
                <div className="text-xs text-muted-foreground">IBSA TRx</div>
                <div className="text-lg font-bold text-blue-600">
                  {formatNumber(hcp.ibsa_trx_total)}
                </div>
                <div className="text-xs text-blue-600 mt-1">+{formatNumber(hcp.ibsa_nrx_qtd || 0)} NRx</div>
              </div>
              <div className="text-center p-3 bg-gray-50 rounded-lg border border-gray-200">
                <div className="text-xs text-muted-foreground">Total Market TRx</div>
                <div className="text-lg font-bold">
                  {formatNumber(hcp.trx_current)}
                </div>
              </div>
              <div className="text-center p-3 bg-red-50 rounded-lg">
                <div className="text-xs text-muted-foreground">Gap to Close</div>
                <div className="text-lg font-bold text-red-600">
                  {formatNumber(hcp.competitor_trx_total)}
                </div>
                <div className="text-xs text-red-600 mt-1">+{formatNumber(hcp.competitor_nrx || 0)} NRx</div>
              </div>
            </div>

            {/* Growth Opportunity */}
            <div className="pt-3 border-t mt-3">
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted-foreground">Growth Opportunity</span>
                <span className={`font-semibold ${
                  hcp.competitive_intel.opportunity_score >= 50 ? 'text-green-600' :
                  'text-amber-600'
                }`}>
                  {hcp.competitive_intel.opportunity_score}% available
                </span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabbed Content Section */}
      <Tabs defaultValue="overview" className="w-full">
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="overview">Overview & Insights</TabsTrigger>
          <TabsTrigger value="call-script">🤖 AI Call Script</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-4">
          {/* Recent Call History - Compact */}
          {hcp.call_history && hcp.call_history.length > 0 ? (
            <Card className="border border-blue-200 bg-blue-50/30">
              <CardHeader className="py-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Calendar className="h-4 w-4 text-blue-600" />
                    <h3 className="text-base font-semibold">Recent Call History</h3>
                    <span className="text-xs bg-blue-100 text-blue-700 px-2 py-0.5 rounded-full">
                      {hcp.call_history.length} calls from CRM
                    </span>
                  </div>
                  <span className="text-xs text-gray-600">Last: {hcp.call_history[0]?.call_date}</span>
                </div>
              </CardHeader>
              <CardContent className="pt-0">
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead className="border-b border-gray-200 bg-gray-50">
                      <tr>
                        <th className="text-left py-2 px-3 font-semibold text-gray-700">Date</th>
                        <th className="text-left py-2 px-3 font-semibold text-gray-700">Type</th>
                        <th className="text-left py-2 px-3 font-semibold text-gray-700">Products</th>
                        <th className="text-left py-2 px-3 font-semibold text-gray-700">Rep</th>
                        <th className="text-left py-2 px-3 font-semibold text-gray-700">Details</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100">
                      {hcp.call_history.slice(0, 3).map((call, idx) => (
                        <tr key={idx} className={idx === 0 ? 'bg-blue-50' : 'bg-white hover:bg-gray-50'}>
                          <td className="py-2 px-3">
                            <span className={`text-xs font-medium ${idx === 0 ? 'text-blue-700' : 'text-gray-700'}`}>
                              {call.call_date}
                            </span>
                          </td>
                          <td className="py-2 px-3">
                            <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                              call.call_type === 'Detail' ? 'bg-green-100 text-green-700' :
                              call.call_type === 'Sample Drop' ? 'bg-purple-100 text-purple-700' :
                              'bg-gray-100 text-gray-700'
                            }`}>
                              {call.call_type}
                            </span>
                          </td>
                          <td className="py-2 px-3 text-xs text-gray-900">{call.products || '-'}</td>
                          <td className="py-2 px-3 text-xs text-gray-600">{call.rep_name}</td>
                          <td className="py-2 px-3">
                            <div className="flex items-center gap-2 text-xs">
                              {call.is_sampled === 'True' && (
                                <span className="bg-purple-100 text-purple-700 px-1.5 py-0.5 rounded">
                                  📦 Samples
                                </span>
                              )}
                              {call.next_call_objective && call.next_call_objective.trim() !== '' && (
                                <span className="bg-amber-100 text-amber-700 px-1.5 py-0.5 rounded truncate max-w-[200px]" title={call.next_call_objective}>
                                  🎯 {call.next_call_objective}
                                </span>
                              )}
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                {hcp.call_history.length > 3 && (
                  <div className="mt-2 text-center text-xs text-gray-500">
                    + {hcp.call_history.length - 3} more interactions
                  </div>
                )}
              </CardContent>
            </Card>
          ) : null}

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
            {/* AI Key Messages - Prominent left column */}
            <div className="lg:col-span-2">
              <Card className="border-2 border-purple-200 bg-purple-50/30">
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <TrendingUp className="h-5 w-5 text-purple-600" />
                    AI-Generated Call Guide
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <AIKeyMessages hcp={hcp} predictions={hcp.predictions} />
                </CardContent>
              </Card>
            </div>

            {/* Predictive Insights - Right column */}
            <Card className="border-2 border-blue-200 bg-blue-50/50">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <TrendingUp className="h-5 w-5 text-blue-600" />
                  Quick Stats
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-6">
                  <div>
                    <div className="text-sm font-medium text-muted-foreground mb-2">Call Success</div>
                    <div className="relative pt-1">
                      <div className="flex mb-2 items-center justify-between">
                        <div>
                          <span className="text-3xl font-bold text-blue-600">
                            {formatPercent(
                              hcp.predictions.product_focus === 'Tirosint' ? hcp.predictions.tirosint_call_success :
                              hcp.predictions.product_focus === 'Flector' ? hcp.predictions.flector_call_success :
                              hcp.predictions.licart_call_success, 0
                            )}
                          </span>
                        </div>
                      </div>
                      <div className="overflow-hidden h-2 text-xs flex rounded bg-blue-200">
                        <div
                          style={{ width: `${(hcp.predictions.product_focus === 'Tirosint' ? hcp.predictions.tirosint_call_success :
                                             hcp.predictions.product_focus === 'Flector' ? hcp.predictions.flector_call_success :
                                             hcp.predictions.licart_call_success) * 100}%` }}
                          className="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-blue-600"
                        ></div>
                      </div>
                    </div>
                  </div>

                  <div>
                    <div className="text-sm font-medium text-muted-foreground mb-2">Forecasted Lift</div>
                    <div className="text-3xl font-bold text-green-600">
                      {hcp.predictions.product_focus === 'Tirosint' ? `${hcp.predictions.tirosint_prescription_lift >= 0 ? '+' : ''}${formatNumber(hcp.predictions.tirosint_prescription_lift, 1)}` :
                       hcp.predictions.product_focus === 'Flector' ? `${hcp.predictions.flector_prescription_lift >= 0 ? '+' : ''}${formatNumber(hcp.predictions.flector_prescription_lift, 1)}` :
                       `${hcp.predictions.licart_prescription_lift >= 0 ? '+' : ''}${formatNumber(hcp.predictions.licart_prescription_lift, 1)}`} TRx
                    </div>
                    <div className="text-sm text-muted-foreground">Expected increase</div>
                  </div>

                  <div>
                    <div className="text-sm font-medium text-muted-foreground mb-2">Wallet Share Growth</div>
                    <div className="text-3xl font-bold text-indigo-600">
                      +{hcp.predictions.product_focus === 'Tirosint' ? 
                        formatNumber(hcp.predictions.tirosint_wallet_share_growth, hcp.predictions.tirosint_wallet_share_growth < 1 ? 2 : 1) :
                        hcp.predictions.product_focus === 'Flector' ? 
                        formatNumber(hcp.predictions.flector_wallet_share_growth, hcp.predictions.flector_wallet_share_growth < 1 ? 2 : 1) :
                        formatNumber(hcp.predictions.licart_wallet_share_growth, hcp.predictions.licart_wallet_share_growth < 1 ? 2 : 1)}pp
                    </div>
                    <div className="text-sm text-muted-foreground">Portfolio expansion</div>
                  </div>

                  <div>
                    <div className="text-sm font-medium text-muted-foreground mb-2">Product Focus</div>
                    <div className="text-3xl font-bold text-purple-600">{hcp.predictions.product_focus}</div>
                    <div className="text-sm text-muted-foreground">Best opportunity</div>
                  </div>

                  <div>
                    <div className="text-sm font-medium text-muted-foreground mb-2">Recommended Action</div>
                    <div className="inline-flex items-center px-3 py-1 rounded-full text-sm font-semibold bg-blue-100 text-blue-800">
                      {hcp.predictions.next_best_action}
                    </div>
                    <div className="text-sm text-muted-foreground mt-2">{hcp.predictions.sample_allocation} samples</div>
                  </div>

                  <div>
                    <div className="text-sm font-medium text-muted-foreground mb-2">Best Call Window</div>
                    <div className="flex items-center gap-2">
                      <Calendar className="h-4 w-4 text-muted-foreground" />
                      <div>
                        <div className="font-semibold">{hcp.predictions.best_day}</div>
                        <div className="text-sm text-muted-foreground">{hcp.predictions.best_time}</div>
                      </div>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="call-script" className="space-y-4">
          {/* Recent Call Activity - Historical Context */}
          {hcp.call_history && hcp.call_history.length > 0 && (
            <Card className="border-2 border-blue-200 bg-gradient-to-r from-blue-50/50 to-indigo-50/30">
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center">
                      <Calendar className="h-5 w-5 text-blue-600" />
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold">Recent Call History</h3>
                      <p className="text-sm text-gray-600">
                        {hcp.call_history.length} interactions in 2025 • Last contact: {hcp.call_history[0]?.call_date}
                      </p>
                    </div>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {hcp.call_history.slice(0, 3).map((call, idx) => (
                    <div 
                      key={idx} 
                      className={`p-4 bg-white rounded-lg border ${idx === 0 ? 'border-blue-300 shadow-sm' : 'border-gray-200'}`}
                    >
                      <div className="flex items-center justify-between mb-3">
                        <div className="flex items-center gap-3">
                          <div className={`text-sm font-bold px-3 py-1 rounded-full ${
                            idx === 0 ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-700'
                          }`}>
                            {call.call_date}
                          </div>
                          <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${
                            call.call_type === 'Detail' ? 'bg-green-100 text-green-700' :
                            call.call_type === 'Sample Drop' ? 'bg-purple-100 text-purple-700' :
                            call.call_type === 'Virtual' ? 'bg-blue-100 text-blue-700' :
                            'bg-gray-100 text-gray-700'
                          }`}>
                            {call.call_type}
                          </span>
                          {call.is_sampled && (
                            <span className="text-xs px-2 py-1 rounded-full bg-amber-100 text-amber-700 font-medium">
                              📦 Samples
                            </span>
                          )}
                        </div>
                        <div className="text-xs text-gray-500 font-medium">
                          Rep: {call.rep_name}
                        </div>
                      </div>

                      {call.products && (
                        <div className="mb-2 flex items-start gap-2">
                          <FileText className="h-4 w-4 text-gray-400 mt-0.5 flex-shrink-0" />
                          <div className="text-sm">
                            <span className="font-semibold text-gray-700">Products: </span>
                            <span className="text-gray-600">{call.products}</span>
                          </div>
                        </div>
                      )}

                      {call.next_call_objective && idx === 0 && (
                        <div className="mt-3 p-3 bg-gradient-to-r from-amber-50 to-orange-50 rounded-lg border-l-4 border-amber-500">
                          <div className="flex items-start gap-2">
                            <TrendingUp className="h-4 w-4 text-amber-600 mt-0.5 flex-shrink-0" />
                            <div>
                              <div className="text-xs font-bold text-amber-900 mb-1">PREVIOUS OBJECTIVE</div>
                              <div className="text-sm text-amber-800 font-medium">{call.next_call_objective}</div>
                            </div>
                          </div>
                        </div>
                      )}
                    </div>
                  ))}
                </div>

                {hcp.call_history.length > 3 && (
                  <div className="mt-4 text-center">
                    <div className="text-xs text-gray-500 font-medium">
                      + {hcp.call_history.length - 3} more interactions this year
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="call-script" className="space-y-4">
          <div className="flex items-center justify-center p-12">
            <div className="text-center space-y-4">
              <p className="text-gray-600">
                AI Call Script generator is now available via the button in the top-right corner
              </p>
              <CallScriptStreaming 
                hcpId={hcp.npi}
                hcpName={hcp.name}
                specialty={hcp.specialty}
              />
            </div>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  )
}
