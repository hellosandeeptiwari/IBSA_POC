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
import { ArrowLeft, MapPin, TrendingUp, Target, Calendar, Bot, Sparkles, Zap } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts'
import { AIKeyMessages } from '@/components/ai-key-messages'
import { CallScriptGenerator } from '@/components/call-script-generator'
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
            <p className="text-muted-foreground">NPI: {hcp.npi || 'Not Available'}</p>
          </div>
        </div>
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
                  // Get product-specific call success rate
                  const productCallSuccess = hcp.predictions.product_focus === 'Tirosint' ? hcp.predictions.tirosint_call_success :
                                            hcp.predictions.product_focus === 'Flector' ? hcp.predictions.flector_call_success :
                                            hcp.predictions.licart_call_success
                  
                  const productLift = hcp.predictions.product_focus === 'Tirosint' ? hcp.predictions.tirosint_prescription_lift :
                                     hcp.predictions.product_focus === 'Flector' ? hcp.predictions.flector_prescription_lift :
                                     hcp.predictions.licart_prescription_lift
                  
                  if (hcp.predictions.ngd_classification === 'Grower') {
                    return <>Grow {hcp.predictions.product_focus} prescriptions - AI predicts <span className="bg-purple-200 border border-purple-400 px-2 py-0.5 rounded font-bold inline-flex items-center gap-1"><Bot className="h-3 w-3" />+{formatNumber(productLift, 1)} TRx lift</span> with <span className="bg-purple-200 border border-purple-400 px-2 py-0.5 rounded font-bold inline-flex items-center gap-1"><Sparkles className="h-3 w-3" />{formatPercent(productCallSuccess, 0)} success rate</span></>
                  } else if (hcp.predictions.ngd_classification === 'Decliner') {
                    return <>Protect {hcp.ibsa_share.toFixed(0)}% IBSA share - <span className="bg-purple-200 border border-purple-400 px-2 py-0.5 rounded font-bold inline-flex items-center gap-1"><Bot className="h-3 w-3" />{hcp.predictions.ngd_classification}</span> status detected, prevent further decline</>
                  } else if (hcp.predictions.ngd_classification === 'New') {
                    return <>Introduce {hcp.predictions.product_focus} - <span className="bg-purple-200 border border-purple-400 px-2 py-0.5 rounded font-bold inline-flex items-center gap-1"><Bot className="h-3 w-3" />{hcp.predictions.ngd_classification}</span> prescriber with <span className="bg-purple-200 border border-purple-400 px-2 py-0.5 rounded font-bold inline-flex items-center gap-1"><Sparkles className="h-3 w-3" />{formatPercent(productCallSuccess, 0)} success probability</span></>
                  } else {
                    return <>Maintain relationship - <span className="bg-purple-200 border border-purple-400 px-2 py-0.5 rounded font-bold inline-flex items-center gap-1"><Bot className="h-3 w-3" />{hcp.predictions.ngd_classification}</span> prescriber, continue regular engagement</>
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
                  <span className="text-gray-600">Call Success Rate:</span>
                  <span className="ml-auto bg-green-200 border-2 border-green-500 px-3 py-1 rounded font-bold text-green-800">
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
                      (Decile {hcp.ngd_decile}, {formatPercent(hcp.trx_growth, 1)} growth)
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
              
              {/* Always-visible product comparison */}
              <div className="mt-3 border-t pt-3 border-purple-200">
                <div className="text-xs font-semibold text-gray-700 mb-2 flex items-center gap-1">
                  <Sparkles className="h-3 w-3 text-purple-600" />
                  📊 All Product Predictions Compared (12 ML Models - 4 per product):
                  <span className="ml-auto text-[10px] bg-purple-100 text-purple-700 px-2 py-0.5 rounded font-normal">
                    Each product has separate LightGBM predictions
                  </span>
                </div>
                <div className="grid grid-cols-3 gap-2 text-xs">
                  <div className={`p-2 rounded border ${hcp.predictions.product_focus === 'Tirosint' ? 'border-green-500 bg-green-50 ring-2 ring-green-300' : 'border-gray-200 opacity-60'}`}>
                    <div className="font-semibold flex items-center gap-1">
                      Tirosint
                      {hcp.predictions.product_focus === 'Tirosint' && <span className="text-[10px] bg-green-600 text-white px-1 rounded">BEST</span>}
                    </div>
                    <div className="text-[10px] text-gray-600 mt-1">Call Success: {formatPercent(hcp.predictions.tirosint_call_success, 0)}</div>
                    <div className="text-[10px] text-gray-600">Rx Lift: {hcp.predictions.tirosint_prescription_lift >= 0 ? '+' : ''}{formatNumber(hcp.predictions.tirosint_prescription_lift, 1)} TRx</div>
                    <div className="text-[10px] text-gray-600">NGD: {hcp.predictions.tirosint_ngd_category}</div>
                    <div className="text-[10px] text-blue-700 font-semibold bg-blue-50 px-1 rounded">
                      Wallet Share Grw: {hcp.predictions.tirosint_wallet_share_growth >= 0 ? '+' : ''}{Math.abs(hcp.predictions.tirosint_wallet_share_growth) >= 0.1 ? formatNumber(hcp.predictions.tirosint_wallet_share_growth, 1) : hcp.predictions.tirosint_wallet_share_growth.toFixed(2)}pp
                    </div>
                  </div>
                  <div className={`p-2 rounded border ${hcp.predictions.product_focus === 'Flector' ? 'border-green-500 bg-green-50 ring-2 ring-green-300' : 'border-gray-200 opacity-60'}`}>
                    <div className="font-semibold flex items-center gap-1">
                      Flector
                      {hcp.predictions.product_focus === 'Flector' && <span className="text-[10px] bg-green-600 text-white px-1 rounded">BEST</span>}
                    </div>
                    <div className="text-[10px] text-gray-600 mt-1">Call Success: {formatPercent(hcp.predictions.flector_call_success, 0)}</div>
                    <div className="text-[10px] text-gray-600">Rx Lift: {hcp.predictions.flector_prescription_lift >= 0 ? '+' : ''}{formatNumber(hcp.predictions.flector_prescription_lift, 1)} TRx</div>
                    <div className="text-[10px] text-gray-600">NGD: {hcp.predictions.flector_ngd_category}</div>
                    <div className="text-[10px] text-blue-700 font-semibold bg-blue-50 px-1 rounded">
                      Wallet Share Grw: {hcp.predictions.flector_wallet_share_growth >= 0 ? '+' : ''}{Math.abs(hcp.predictions.flector_wallet_share_growth) >= 0.1 ? formatNumber(hcp.predictions.flector_wallet_share_growth, 1) : hcp.predictions.flector_wallet_share_growth.toFixed(2)}pp
                    </div>
                  </div>
                  <div className={`p-2 rounded border ${hcp.predictions.product_focus === 'Licart' ? 'border-green-500 bg-green-50 ring-2 ring-green-300' : 'border-gray-200 opacity-60'}`}>
                    <div className="font-semibold flex items-center gap-1">
                      Licart
                      {hcp.predictions.product_focus === 'Licart' && <span className="text-[10px] bg-green-600 text-white px-1 rounded">BEST</span>}
                    </div>
                    <div className="text-[10px] text-gray-600 mt-1">Call Success: {formatPercent(hcp.predictions.licart_call_success, 0)}</div>
                    <div className="text-[10px] text-gray-600">Rx Lift: {hcp.predictions.licart_prescription_lift >= 0 ? '+' : ''}{formatNumber(hcp.predictions.licart_prescription_lift, 1)} TRx</div>
                    <div className="text-[10px] text-gray-600">NGD: {hcp.predictions.licart_ngd_category}</div>
                    <div className="text-[10px] text-blue-700 font-semibold bg-blue-50 px-1 rounded">
                      Wallet Share Grw: {hcp.predictions.licart_wallet_share_growth >= 0 ? '+' : ''}{Math.abs(hcp.predictions.licart_wallet_share_growth) >= 0.1 ? formatNumber(hcp.predictions.licart_wallet_share_growth, 1) : hcp.predictions.licart_wallet_share_growth.toFixed(2)}pp
                    </div>
                  </div>
                </div>
                <div className="text-[11px] text-gray-500 italic mt-2 space-y-1">
                  <div>ℹ️ The recommended product ({hcp.predictions.product_focus}) has the highest predicted call success rate for this HCP. Other products may still be discussed as secondary options.</div>
                  
                  {/* Wallet Share Growth - Competitive Displacement */}
                  <div className="bg-gradient-to-r from-blue-50 to-green-50 border-2 border-blue-300 p-3 rounded-lg not-italic space-y-2">
                    <div className="flex items-center gap-2">
                      <strong className="text-blue-800 text-sm">� Wallet Share Growth = Market Share Gain from Competitors</strong>
                    </div>
                    
                    <div className="grid grid-cols-3 gap-2 text-[10px]">
                      <div className="bg-white border border-blue-200 p-2 rounded">
                        <div className="font-bold text-blue-900">Tirosint</div>
                        <div className="text-green-700 font-semibold mt-1">
                          {hcp.predictions.tirosint_wallet_share_growth >= 0 ? '+' : ''}
                          {Math.abs(hcp.predictions.tirosint_wallet_share_growth) >= 0.1 
                            ? formatNumber(hcp.predictions.tirosint_wallet_share_growth, 1) 
                            : hcp.predictions.tirosint_wallet_share_growth.toFixed(2)}pp gain
                        </div>
                        <div className="text-gray-600 mt-1">
                          {hcp.ibsa_share > 0 ? (
                            <>From {hcp.ibsa_share.toFixed(1)}% → {(hcp.ibsa_share + hcp.predictions.tirosint_wallet_share_growth).toFixed(1)}%</>
                          ) : (
                            <>Capture {Math.abs(hcp.predictions.tirosint_wallet_share_growth) >= 0.1 ? hcp.predictions.tirosint_wallet_share_growth.toFixed(1) : hcp.predictions.tirosint_wallet_share_growth.toFixed(2)}% from {hcp.competitive_intel?.inferred_competitors?.[0] || 'competitors'}</>
                          )}
                        </div>
                      </div>
                      <div className="bg-white border border-blue-200 p-2 rounded">
                        <div className="font-bold text-blue-900">Flector</div>
                        <div className="text-green-700 font-semibold mt-1">
                          {hcp.predictions.flector_wallet_share_growth >= 0 ? '+' : ''}
                          {Math.abs(hcp.predictions.flector_wallet_share_growth) >= 0.1 
                            ? formatNumber(hcp.predictions.flector_wallet_share_growth, 1) 
                            : hcp.predictions.flector_wallet_share_growth.toFixed(2)}pp gain
                        </div>
                        <div className="text-gray-600 mt-1">
                          {hcp.ibsa_share > 0 ? (
                            <>From {hcp.ibsa_share.toFixed(1)}% → {(hcp.ibsa_share + hcp.predictions.flector_wallet_share_growth).toFixed(1)}%</>
                          ) : (
                            <>Capture {Math.abs(hcp.predictions.flector_wallet_share_growth) >= 0.1 ? hcp.predictions.flector_wallet_share_growth.toFixed(1) : hcp.predictions.flector_wallet_share_growth.toFixed(2)}% from {hcp.competitive_intel?.inferred_competitors?.[0] || 'competitors'}</>
                          )}
                        </div>
                      </div>
                      <div className="bg-white border border-blue-200 p-2 rounded">
                        <div className="font-bold text-blue-900">Licart</div>
                        <div className="text-green-700 font-semibold mt-1">
                          {hcp.predictions.licart_wallet_share_growth >= 0 ? '+' : ''}
                          {Math.abs(hcp.predictions.licart_wallet_share_growth) >= 0.1 
                            ? formatNumber(hcp.predictions.licart_wallet_share_growth, 1) 
                            : hcp.predictions.licart_wallet_share_growth.toFixed(2)}pp gain
                        </div>
                        <div className="text-gray-600 mt-1">
                          {hcp.ibsa_share > 0 ? (
                            <>From {hcp.ibsa_share.toFixed(1)}% → {(hcp.ibsa_share + hcp.predictions.licart_wallet_share_growth).toFixed(1)}%</>
                          ) : (
                            <>Capture {Math.abs(hcp.predictions.licart_wallet_share_growth) >= 0.1 ? hcp.predictions.licart_wallet_share_growth.toFixed(1) : hcp.predictions.licart_wallet_share_growth.toFixed(2)}% from {hcp.competitive_intel?.inferred_competitors?.[0] || 'competitors'}</>
                          )}
                        </div>
                      </div>
                    </div>
                    
                    <div className="bg-yellow-50 border border-yellow-300 p-2 rounded text-[10px]">
                      <strong className="text-yellow-900">🎯 Competitive Strategy:</strong> These predictions show how much market share each IBSA product can capture from 
                      <strong> {hcp.competitive_intel?.competitor_product_distribution?.map(c => c.product).slice(0,2).join(' and ') || hcp.competitive_intel?.inferred_competitors?.slice(0,2).join(' and ') || 'competitors'}</strong>. 
                      Current IBSA share: <strong>{hcp.ibsa_share.toFixed(0)}%</strong> → 
                      Potential with {hcp.predictions.product_focus}: <strong>{(hcp.ibsa_share + (
                        hcp.predictions.product_focus === 'Tirosint' ? hcp.predictions.tirosint_wallet_share_growth :
                        hcp.predictions.product_focus === 'Flector' ? hcp.predictions.flector_wallet_share_growth :
                        hcp.predictions.licart_wallet_share_growth
                      )).toFixed(0)}%</strong>
                      {hcp.competitive_intel?.competitor_product_distribution && hcp.competitive_intel.competitor_product_distribution.length > 0 && (
                        <span className="block mt-1 text-red-700">
                          ⚠️ Main threat: <strong>{hcp.competitive_intel.competitor_product_distribution[0].product}</strong> (~{hcp.competitive_intel.competitor_product_distribution[0].trx} TRx)
                        </span>
                      )}
                    </div>
                  </div>
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
                  ? <>"I see you're increasing prescriptions - <span className="bg-green-200 border border-green-400 px-1 not-italic font-medium">{formatPercent(Math.abs(hcp.trx_growth), 1)} growth this quarter</span>. I have data showing how to accelerate this momentum with <span className="bg-blue-200 border border-blue-400 px-1 not-italic font-medium">{hcp.predictions.product_focus}</span> for your patients."</>
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
                  <span className="text-xs text-gray-500 ml-2 italic">(Calculated: Tier {hcp.tier} × Call Success {formatPercent(hcp.predictions.call_success_prob, 0)} × Rx Lift {hcp.rx_lift ? formatNumber(hcp.rx_lift, 1) : 'N/A'})</span>
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
                              <div className="text-gray-700 mt-1">"Your {formatPercent(hcp.trx_growth, 1)} growth shows strong patient outcomes with {hcp.predictions.product_focus}. Latest clinical evidence supports expanding usage across additional patient segments."</div>
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
            <CardTitle>IBSA Product Mix (TRx + NRx)</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={hcp.product_mix.map(p => ({ 
                ...p, 
                nrx: Math.round(p.trx * 0.15) // Approximate NRx as 15% of TRx for IBSA products
              }))}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="product" angle={-45} textAnchor="end" height={80} tick={{ fontSize: 11 }} />
                <YAxis />
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
            <div className="flex items-center justify-center gap-4 mt-2 text-xs">
              <div className="flex items-center gap-1">
                <div className="w-3 h-3 bg-blue-600 rounded"></div>
                <span>Total Rx</span>
              </div>
              <div className="flex items-center gap-1">
                <div className="w-3 h-3 bg-blue-300 rounded"></div>
                <span>New Rx</span>
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

      <div className="grid grid-cols-1 gap-4">

        <Card>
          <CardHeader>
            <CardTitle>Competitive Intelligence</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {/* Therapeutic Area & Situation */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <div className="text-xs text-muted-foreground mb-1">Therapeutic Area</div>
                  <div className="text-sm font-semibold">{hcp.competitive_intel.ta_category}</div>
                </div>
                <div>
                  <div className="text-xs text-muted-foreground mb-1">Situation</div>
                  <div className="text-sm">{hcp.competitive_intel.competitive_situation}</div>
                </div>
              </div>

              {/* Competitive Pressure */}
              <div>
                <div className="text-xs text-muted-foreground mb-1">Competitive Pressure</div>
                <div className="flex items-center gap-2">
                  <div className="flex-1 bg-gray-200 rounded-full h-2">
                    <div
                      className={`h-2 rounded-full ${
                        (hcp.competitive_intel.competitive_pressure_score || 0) > 90 ? 'bg-red-500' :
                        (hcp.competitive_intel.competitive_pressure_score || 0) > 70 ? 'bg-orange-500' :
                        (hcp.competitive_intel.competitive_pressure_score || 0) > 50 ? 'bg-yellow-500' :
                        'bg-green-500'
                      }`}
                      style={{ width: `${Math.min(hcp.competitive_intel.competitive_pressure_score || 0, 100)}%` }}
                    />
                  </div>
                  <span className="text-sm font-bold">{(hcp.competitive_intel.competitive_pressure_score || 0).toFixed(0)}/100</span>
                </div>
                <div className="mt-1 text-xs text-muted-foreground">
                  {hcp.competitive_intel.competitor_strength && (
                    <span className={`inline-block px-2 py-1 rounded font-semibold ${
                      hcp.competitive_intel.competitor_strength === 'Dominant' ? 'bg-red-100 text-red-700' :
                      hcp.competitive_intel.competitor_strength === 'Strong' ? 'bg-orange-100 text-orange-700' :
                      hcp.competitive_intel.competitor_strength === 'Moderate' ? 'bg-yellow-100 text-yellow-700' :
                      'bg-green-100 text-green-700'
                    }`}>
                      {hcp.competitive_intel.competitor_strength} Competition
                    </span>
                  )}
                </div>
              </div>

              {/* Actual Competitor Product Breakdown */}
              {hcp.competitive_intel.competitor_product_distribution && hcp.competitive_intel.competitor_product_distribution.length > 0 && (
                <div className="pt-3 border-t">
                  <div className="text-xs font-semibold text-gray-700 mb-3">Competitor Product Breakdown (Actual Writes)</div>
                  <div className="space-y-2">
                    {hcp.competitive_intel.competitor_product_distribution.map((comp, idx) => {
                      const totalCompTrx = hcp.competitor_trx_total || 0
                      const percentage = totalCompTrx > 0 ? (comp.trx / totalCompTrx) * 100 : 0
                      return (
                        <div key={idx} className="space-y-1">
                          <div className="flex items-center justify-between text-xs">
                            <span className="font-medium">{comp.product}</span>
                            <span className="text-gray-600 font-semibold">{formatNumber(comp.trx)} TRx ({percentage.toFixed(0)}%)</span>
                          </div>
                          <div className="w-full bg-gray-200 rounded-full h-2.5">
                            <div
                              className={`h-2.5 rounded-full ${
                                idx === 0 ? 'bg-red-500' : 
                                idx === 1 ? 'bg-orange-500' : 
                                'bg-amber-500'
                              }`}
                              style={{ width: `${Math.min(percentage, 100)}%` }}
                            />
                          </div>
                        </div>
                      )
                    })}
                  </div>
                  
                  {/* Strategy Recommendation */}
                  {hcp.competitive_intel.competitor_product_distribution[0] && (
                    <div className="mt-3 p-3 bg-amber-50 rounded-lg border border-amber-200">
                      <div className="flex items-start gap-2">
                        <span className="text-lg">💡</span>
                        <div className="text-xs text-amber-900">
                          <strong>Strategy:</strong> Total competitor market: <strong>{formatNumber(hcp.competitor_trx_total)}</strong> TRx. 
                          Primary competitor is <strong>{hcp.competitive_intel.competitor_product_distribution[0].product}</strong> with{' '}
                          <strong>{formatNumber(hcp.competitive_intel.competitor_product_distribution[0].trx)}</strong> TRx.
                          Focus differentiation messaging against this dominant competitor.
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* No competitor data fallback */}
              {(!hcp.competitive_intel.competitor_product_distribution || hcp.competitive_intel.competitor_product_distribution.length === 0) && (
                <div className="pt-3 border-t">
                  <div className="text-xs text-muted-foreground mb-2">Active Competitors</div>
                  <div className="flex flex-wrap gap-1">
                    {hcp.competitive_intel.inferred_competitors?.map((comp, idx) => (
                      <span key={idx} className="text-xs bg-gray-100 px-2 py-1 rounded">
                        {comp}
                      </span>
                    ))}
                  </div>
                  <div className="mt-2 text-xs text-muted-foreground italic">
                    No specific competitor TRx data available
                  </div>
                </div>
              )}

              {/* Competitive Pressure Trend */}
              {hcp.competitive_intel.competitive_pressure_score && (
                <div className="pt-4 border-t">
                  <div className="text-xs font-semibold text-gray-700 mb-3 flex items-center gap-1">
                    Competitive Pressure Analysis
                    <span className="text-gray-500 hover:text-gray-700 cursor-help" title="4-metric competitive snapshot: Red bar shows competitive market pressure, Blue shows your current IBSA share, Green shows AI-predicted call success rate, Amber shows risk of HCP switching to competitors. Higher bars = higher intensity">
                      <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
                      </svg>
                    </span>
                  </div>
                  <ResponsiveContainer width="100%" height={150}>
                    <BarChart
                      data={[
                        { metric: 'Comp\nPressure', value: hcp.competitive_intel.competitive_pressure_score || 0, fill: '#ef4444' },
                        { metric: 'IBSA\nShare', value: hcp.ibsa_share, fill: '#2563eb' },
                        { metric: 'Call\nSuccess', value: (hcp.predictions.call_success_prob || 0) * 100, fill: '#10b981' },
                        { 
                          metric: 'Conversion\nRisk', 
                          value: (() => {
                            // Calculate conversion risk: high competitive pressure + low IBSA share + declining trend = high risk
                            const compPressure = hcp.competitive_intel.competitive_pressure_score || 0;
                            const ibsaShare = hcp.ibsa_share || 0;
                            const isDecliner = hcp.predictions.ngd_classification === 'Decliner';
                            const baseRisk = (compPressure * (100 - ibsaShare)) / 100;
                            return isDecliner ? Math.min(baseRisk * 1.3, 100) : baseRisk;
                          })(), 
                          fill: '#f59e0b' 
                        }
                      ]}
                      layout="vertical"
                      margin={{ top: 5, right: 30, left: 60, bottom: 5 }}
                    >
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis type="number" domain={[0, 100]} />
                      <YAxis type="category" dataKey="metric" tick={{ fontSize: 10 }} />
                      <Tooltip formatter={(value: any) => `${Number(value).toFixed(1)}%`} />
                      <Bar dataKey="value" />
                    </BarChart>
                  </ResponsiveContainer>
                  <div className="mt-2 grid grid-cols-2 gap-2 text-[10px]">
                    <div className="bg-red-50 p-2 rounded">
                      <div className="text-red-700 font-semibold">Competitive Pressure</div>
                      <div className="text-gray-600">Current market competition level</div>
                    </div>
                    <div className="bg-blue-50 p-2 rounded">
                      <div className="text-blue-700 font-semibold">IBSA Share</div>
                      <div className="text-gray-600">Your current market position</div>
                    </div>
                    <div className="bg-green-50 p-2 rounded">
                      <div className="text-green-700 font-semibold">Call Success</div>
                      <div className="text-gray-600">AI predicted success rate</div>
                    </div>
                    <div className="bg-amber-50 p-2 rounded">
                      <div className="text-amber-700 font-semibold flex items-center gap-1">
                        Conversion Risk
                        <span className="text-amber-600 hover:text-amber-800 cursor-help" title="Formula: (Competitive Pressure × (100 - IBSA Share)) / 100. Decliners get 1.3x multiplier. Higher when competitors are strong and IBSA share is low.">
                          <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
                          </svg>
                        </span>
                      </div>
                      <div className="text-gray-600">Risk of switching to competitor</div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabbed Content Section */}
      <Tabs defaultValue="overview" className="w-full">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="overview">Overview & Insights</TabsTrigger>
          <TabsTrigger value="call-script">🤖 AI Call Script</TabsTrigger>
          <TabsTrigger value="history">Call History</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-4">
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

        <TabsContent value="call-script">
          <CallScriptGenerator 
            hcpId={hcp.npi}
            hcpName={hcp.name}
            specialty={hcp.specialty}
          />
        </TabsContent>

        <TabsContent value="history">
          <Card>
            <CardHeader>
              <CardTitle>Call History ({hcp.call_history.length} calls in 2025)</CardTitle>
            </CardHeader>
            <CardContent>
              {hcp.call_history.length === 0 ? (
                <p className="text-muted-foreground">No call history available for 2025</p>
              ) : (
                <div className="space-y-4">
                  {hcp.call_history.map((call, idx) => (
                    <div key={idx} className="border-l-4 border-blue-500 pl-4 py-2">
                      <div className="flex items-center justify-between mb-1">
                        <div className="flex items-center gap-3">
                          <span className="font-semibold text-sm">{call.call_date}</span>
                          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                            {call.call_type}
                          </span>
                          {call.is_sampled && (
                            <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">
                              📦 Samples
                            </span>
                          )}
                        </div>
                        <span className="text-xs text-gray-500">{call.duration}min</span>
                      </div>
                      <div className="text-sm text-gray-600 mb-1">
                        <span className="font-medium">Rep:</span> {call.rep_name}
                      </div>
                      {call.products && (
                        <div className="text-sm text-gray-600 mb-1">
                          <span className="font-medium">Products:</span> {call.products}
                        </div>
                      )}
                      {call.next_call_objective && (
                        <div className="text-sm bg-amber-50 p-2 rounded mt-2">
                          <span className="font-medium text-amber-900">Next Objective:</span>
                          <span className="text-amber-800 ml-1">{call.next_call_objective}</span>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
