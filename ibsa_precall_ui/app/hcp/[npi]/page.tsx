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
            <p className="text-muted-foreground">NPI: {hcp.npi}</p>
          </div>
        </div>
        <div className="flex gap-2">
          <Button variant="outline">Schedule Call</Button>
          <Button>Add to Call Plan</Button>
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
                {hcp.predictions.ngd_classification === 'Grower'
                  ? <>Grow {hcp.predictions.product_focus} prescriptions - AI predicts <span className="bg-purple-200 border border-purple-400 px-2 py-0.5 rounded font-bold inline-flex items-center gap-1"><Bot className="h-3 w-3" />+{formatNumber(hcp.predictions.forecasted_lift, 0)} TRx lift</span> with <span className="bg-purple-200 border border-purple-400 px-2 py-0.5 rounded font-bold inline-flex items-center gap-1"><Sparkles className="h-3 w-3" />{formatPercent(hcp.predictions.call_success_prob, 0)} success rate</span></>
                  : hcp.predictions.ngd_classification === 'Decliner'
                  ? <>Protect {hcp.ibsa_share.toFixed(0)}% IBSA share - <span className="bg-purple-200 border border-purple-400 px-2 py-0.5 rounded font-bold inline-flex items-center gap-1"><Bot className="h-3 w-3" />{hcp.predictions.ngd_classification}</span> status detected, prevent further decline</>
                  : hcp.predictions.ngd_classification === 'New'
                  ? <>Introduce {hcp.predictions.product_focus} - <span className="bg-purple-200 border border-purple-400 px-2 py-0.5 rounded font-bold inline-flex items-center gap-1"><Bot className="h-3 w-3" />{hcp.predictions.ngd_classification}</span> prescriber with <span className="bg-purple-200 border border-purple-400 px-2 py-0.5 rounded font-bold inline-flex items-center gap-1"><Sparkles className="h-3 w-3" />{formatPercent(hcp.predictions.call_success_prob, 0)} success probability</span></>
                  : <>Maintain relationship - <span className="bg-purple-200 border border-purple-400 px-2 py-0.5 rounded font-bold inline-flex items-center gap-1"><Bot className="h-3 w-3" />{hcp.predictions.ngd_classification}</span> prescriber, continue regular engagement</>
                }
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
                  <span className="ml-auto bg-purple-200 border border-purple-400 px-2 py-0.5 rounded font-semibold">
                    {hcp.predictions.product_focus === 'Tirosint' ? hcp.predictions.tirosint_ngd_category :
                     hcp.predictions.product_focus === 'Flector' ? hcp.predictions.flector_ngd_category :
                     hcp.predictions.licart_ngd_category}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <Bot className="h-3 w-3 text-purple-600 flex-shrink-0" />
                  <span className="text-gray-600">Next Best Action:</span>
                  <span className="ml-auto bg-purple-200 border border-purple-400 px-2 py-0.5 rounded font-semibold">{hcp.predictions.next_best_action}</span>
                </div>
              </div>
              <div className="mt-3 pt-3 border-t border-purple-200 text-xs text-gray-600 bg-blue-50 p-2 rounded">
                <strong>Why {hcp.predictions.product_focus}?</strong> AI selected this product based on highest predicted call success rate across all products. 
                {hcp.specialty.toLowerCase().includes('endocrin') ? ' Specialty alignment: Endocrinology prescriber optimal for Tirosint.' :
                 hcp.specialty.toLowerCase().includes('pain') ? ' Specialty alignment: Pain management prescriber optimal for Flector/Licart.' :
                 ' Other products analyzed but showed lower engagement probability.'}
              </div>
              <details className="mt-3 text-xs">
                <summary className="cursor-pointer text-purple-700 font-semibold hover:text-purple-900">
                  📊 View all product predictions (Tirosint, Flector, Licart)
                </summary>
                <div className="mt-2 p-3 bg-white border border-purple-200 rounded space-y-2">
                  <div className="grid grid-cols-3 gap-2">
                    <div className={`p-2 rounded border ${hcp.predictions.product_focus === 'Tirosint' ? 'border-green-500 bg-green-50' : 'border-gray-300'}`}>
                      <div className="font-semibold text-gray-700">Tirosint</div>
                      <div className="text-[11px] text-gray-600">Success: {formatPercent(hcp.predictions.tirosint_call_success, 0)}</div>
                      <div className="text-[11px] text-gray-600">Lift: {hcp.predictions.tirosint_prescription_lift >= 0 ? '+' : ''}{formatNumber(hcp.predictions.tirosint_prescription_lift, 1)}</div>
                    </div>
                    <div className={`p-2 rounded border ${hcp.predictions.product_focus === 'Flector' ? 'border-green-500 bg-green-50' : 'border-gray-300'}`}>
                      <div className="font-semibold text-gray-700">Flector</div>
                      <div className="text-[11px] text-gray-600">Success: {formatPercent(hcp.predictions.flector_call_success, 0)}</div>
                      <div className="text-[11px] text-gray-600">Lift: {hcp.predictions.flector_prescription_lift >= 0 ? '+' : ''}{formatNumber(hcp.predictions.flector_prescription_lift, 1)}</div>
                    </div>
                    <div className={`p-2 rounded border ${hcp.predictions.product_focus === 'Licart' ? 'border-green-500 bg-green-50' : 'border-gray-300'}`}>
                      <div className="font-semibold text-gray-700">Licart</div>
                      <div className="text-[11px] text-gray-600">Success: {formatPercent(hcp.predictions.licart_call_success, 0)}</div>
                      <div className="text-[11px] text-gray-600">Lift: {hcp.predictions.licart_prescription_lift >= 0 ? '+' : ''}{formatNumber(hcp.predictions.licart_prescription_lift, 1)}</div>
                    </div>
                  </div>
                  <div className="text-[11px] text-gray-500 italic">
                    ℹ️ The recommended product ({hcp.predictions.product_focus}) has the highest predicted call success rate for this HCP. Other products may still be discussed as secondary options.
                  </div>
                </div>
              </details>
            </div>

            {/* Opening Line */}
            <div className="border-l-4 border-gray-400 bg-gray-50 rounded p-4">
              <div className="text-xs font-semibold text-gray-600 mb-2">💬 OPENING LINE:</div>
              <p className="text-sm text-gray-800 italic">
                {hcp.predictions.ngd_classification === 'Decliner'
                  ? <>"I noticed some changes in prescribing patterns and wanted to understand what's driving your decisions. Our AI shows you as a <span className="bg-purple-200 border border-purple-400 px-1 not-italic font-medium inline-flex items-center gap-1"><Bot className="h-3 w-3" />{hcp.predictions.ngd_classification}</span> - let's discuss how we can support your practice."</>
                  : hcp.predictions.ngd_classification === 'New'
                  ? <>"Welcome to prescribing! Our AI identifies you as a <span className="bg-purple-200 border border-purple-400 px-1 not-italic font-medium inline-flex items-center gap-1"><Bot className="h-3 w-3" />{hcp.predictions.ngd_classification}</span> prescriber. I'd like to share how <span className="bg-purple-200 border border-purple-400 px-1 not-italic font-medium inline-flex items-center gap-1"><Sparkles className="h-3 w-3" />{hcp.predictions.product_focus}</span> could benefit your patients."</>
                  : hcp.predictions.ngd_classification === 'Grower'
                  ? <>"I see you're increasing prescriptions - our AI classifies you as a <span className="bg-purple-200 border border-purple-400 px-1 not-italic font-medium inline-flex items-center gap-1"><Bot className="h-3 w-3" />{hcp.predictions.ngd_classification}</span> with <span className="bg-purple-200 border border-purple-400 px-1 not-italic font-medium inline-flex items-center gap-1"><Sparkles className="h-3 w-3" />+{formatNumber(hcp.predictions.forecasted_lift, 0)} TRx growth potential</span>. Let's discuss how to accelerate this momentum."</>
                  : <>"Thank you for your continued partnership. Our AI predicts <span className="bg-purple-200 border border-purple-400 px-1 not-italic font-medium inline-flex items-center gap-1"><Sparkles className="h-3 w-3" />{formatPercent(hcp.predictions.call_success_prob, 0)} success</span> for today's call. I have updates that align with your practice focus."</>
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
                  <span><strong>Bring:</strong> <span className="bg-purple-200 border border-purple-400 px-1 font-semibold inline-flex items-center gap-1"><Bot className="h-3 w-3" />{hcp.predictions.sample_allocation} samples</span> for <span className="bg-purple-200 border border-purple-400 px-1 font-semibold inline-flex items-center gap-1"><Sparkles className="h-3 w-3" />{hcp.predictions.product_focus}</span> + clinical data</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-purple-400">•</span>
                  <span><strong>Discuss:</strong> {hcp.predictions.ngd_classification === 'Decliner' ? 'Retention strategy and competitive challenges' : hcp.predictions.ngd_classification === 'Grower' ? 'Growth acceleration and expanded usage' : hcp.predictions.ngd_classification === 'New' ? 'Product introduction and patient selection' : 'Treatment optimization and patient outcomes'}</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-purple-400">•</span>
                  <span><strong>Position:</strong> Focus on <span className="bg-purple-200 border border-purple-400 px-1 font-semibold inline-flex items-center gap-1"><Bot className="h-3 w-3" />{hcp.predictions.product_focus}</span> with messaging for <span className="bg-purple-200 border border-purple-400 px-1 font-semibold inline-flex items-center gap-1"><Sparkles className="h-3 w-3" />{hcp.predictions.ngd_classification}</span> prescribers</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-purple-400">•</span>
                  <span><strong>Close with:</strong> Schedule follow-up on <span className="bg-purple-200 border border-purple-400 px-1 font-semibold inline-flex items-center gap-1"><Zap className="h-3 w-3" />{hcp.predictions.best_day} {hcp.predictions.best_time}</span> (AI-predicted optimal time)</span>
                </li>
              </ul>
            </div>

            {/* Expected Outcomes */}
            <div className="bg-green-50 rounded p-4 border-2 border-green-400 border-dashed">
              <div className="text-xs font-semibold text-green-800 mb-3 flex items-center gap-1">
                <Sparkles className="h-4 w-4" />
                📈 EXPECTED OUTCOMES FOR {hcp.predictions.product_focus.toUpperCase()}
                <span className="ml-auto bg-green-600 text-white px-2 py-0.5 rounded-full text-[10px] font-bold">AI PREDICTIONS</span>
              </div>
              <div className="grid grid-cols-3 gap-4">
                <div className="text-center">
                  <div className="text-2xl font-bold text-green-900 flex items-center justify-center gap-1">
                    <Bot className="h-5 w-5 text-green-600" />
                    <span className="bg-green-200 border-2 border-green-500 px-2 rounded">
                      {hcp.predictions.product_focus === 'Tirosint' ? `${hcp.predictions.tirosint_prescription_lift >= 0 ? '+' : ''}${formatNumber(hcp.predictions.tirosint_prescription_lift, 1)}` :
                       hcp.predictions.product_focus === 'Flector' ? `${hcp.predictions.flector_prescription_lift >= 0 ? '+' : ''}${formatNumber(hcp.predictions.flector_prescription_lift, 1)}` :
                       `${hcp.predictions.licart_prescription_lift >= 0 ? '+' : ''}${formatNumber(hcp.predictions.licart_prescription_lift, 1)}`}
                    </span>
                  </div>
                  <div className="text-xs text-gray-600 mt-1 flex items-center justify-center gap-1">
                    <Sparkles className="h-3 w-3 text-green-500" />
                    TRx Lift (ML Forecast)
                  </div>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold text-green-900 flex items-center justify-center gap-1">
                    <Bot className="h-5 w-5 text-green-600" />
                    <span className="bg-green-200 border-2 border-green-500 px-2 rounded">
                      {hcp.predictions.product_focus === 'Tirosint' ? formatPercent(hcp.predictions.tirosint_call_success, 0) :
                       hcp.predictions.product_focus === 'Flector' ? formatPercent(hcp.predictions.flector_call_success, 0) :
                       formatPercent(hcp.predictions.licart_call_success, 0)}
                    </span>
                  </div>
                  <div className="text-xs text-gray-600 mt-1 flex items-center justify-center gap-1">
                    <Sparkles className="h-3 w-3 text-green-500" />
                    Success Probability (ML)
                  </div>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold text-green-900 flex items-center justify-center gap-1">
                    <Zap className="h-5 w-5 text-green-600" />
                    <span className="bg-green-200 border-2 border-green-500 px-2 rounded">
                      {hcp.predictions.product_focus === 'Tirosint' ? hcp.predictions.tirosint_ngd_category :
                       hcp.predictions.product_focus === 'Flector' ? hcp.predictions.flector_ngd_category :
                       hcp.predictions.licart_ngd_category}
                    </span>
                  </div>
                  <div className="text-xs text-gray-600 mt-1 flex items-center justify-center gap-1">
                    <Sparkles className="h-3 w-3 text-green-500" />
                    NGD Category (ML)
                  </div>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* EDA Business Intelligence - Why This HCP? */}
      <HCPEDAInsights hcp={hcp} />

      <Card>
        <CardContent className="pt-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="flex items-center gap-2">
              <MapPin className="h-4 w-4 text-muted-foreground" />
              <div>
                <div className="text-sm font-medium">Location</div>
                <div className="text-sm text-muted-foreground">{hcp.address || `${hcp.city}, ${hcp.state}`}</div>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Target className="h-4 w-4 text-muted-foreground" />
              <div>
                <div className="text-sm font-medium">Specialty</div>
                <div className="text-sm text-muted-foreground">{hcp.specialty}</div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

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
            <CardTitle>IBSA Product Mix</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={hcp.product_mix}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="product" angle={-45} textAnchor="end" height={80} tick={{ fontSize: 11 }} />
                <YAxis />
                <Tooltip 
                  formatter={(value: any, name: string) => [
                    name === 'trx' ? `${formatNumber(value)} Rx` : value,
                    name === 'trx' ? 'Prescriptions' : name
                  ]}
                />
                <Bar dataKey="trx" fill="#2563eb" name="TRx" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Market Share Breakdown</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie
                  data={[
                    { name: 'IBSA', value: hcp.ibsa_share, fill: '#2563eb' },
                    { name: 'Competitors', value: 100 - hcp.ibsa_share, fill: '#dc2626' }
                  ]}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  outerRadius={80}
                  label={(entry: any) => `${entry.name}: ${entry.value.toFixed(0)}%`}
                >
                  <Cell fill="#2563eb" />
                  <Cell fill="#dc2626" />
                </Pie>
                <Tooltip formatter={(value: any) => `${Number(value).toFixed(1)}%`} />
              </PieChart>
            </ResponsiveContainer>
            <div className="grid grid-cols-2 gap-4 pt-4">
              <div className="text-center p-3 bg-blue-50 rounded-lg">
                <div className="text-xs text-muted-foreground">IBSA TRx</div>
                <div className="text-lg font-bold text-blue-600">
                  {formatNumber(Math.round(hcp.trx_current * (hcp.ibsa_share / 100)))}
                </div>
              </div>
              <div className="text-center p-3 bg-red-50 rounded-lg">
                <div className="text-xs text-muted-foreground">Competitor TRx</div>
                <div className="text-lg font-bold text-red-600">
                  {formatNumber(Math.round(hcp.trx_current * ((100 - hcp.ibsa_share) / 100)))}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 gap-4">
        <Card>
          <CardHeader>
            <CardTitle>Market Position Details</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium">IBSA Market Share</span>
                <span className={`text-2xl font-bold ${
                  hcp.ibsa_share >= 50 ? 'text-green-600' :
                  hcp.ibsa_share >= 30 ? 'text-blue-600' :
                  'text-amber-600'
                }`}>
                  {formatPercent(hcp.ibsa_share, 0)}
                </span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-6">
                <div
                  className={`h-6 rounded-full flex items-center justify-end pr-2 text-white text-xs font-semibold ${
                    hcp.ibsa_share >= 50 ? 'bg-green-500' :
                    hcp.ibsa_share >= 30 ? 'bg-blue-500' :
                    'bg-amber-500'
                  }`}
                  style={{ width: `${hcp.ibsa_share}%` }}
                >
                  {hcp.ibsa_share >= 20 ? 'IBSA' : ''}
                </div>
              </div>
              <div className="grid grid-cols-3 gap-4 pt-2">
                <div className="text-center p-3 bg-blue-50 rounded-lg">
                  <div className="text-xs text-muted-foreground">IBSA TRx</div>
                  <div className="text-lg font-bold text-blue-600">
                    {formatNumber(Math.round(hcp.trx_current * (hcp.ibsa_share / 100)))}
                  </div>
                </div>
                <div className="text-center p-3 bg-gray-50 rounded-lg">
                  <div className="text-xs text-muted-foreground">Total Market TRx</div>
                  <div className="text-lg font-bold">
                    {formatNumber(hcp.trx_current)}
                  </div>
                </div>
                <div className="text-center p-3 bg-red-50 rounded-lg">
                  <div className="text-xs text-muted-foreground">Gap to Close</div>
                  <div className="text-lg font-bold text-red-600">
                    {formatNumber(Math.round(hcp.trx_current * ((100 - hcp.ibsa_share) / 100)))}
                  </div>
                </div>
              </div>
              <div className="pt-2 border-t">
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
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Competitive Intelligence</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div>
                <div className="text-xs text-muted-foreground mb-1">Therapeutic Area</div>
                <div className="text-sm font-semibold">{hcp.competitive_intel.ta_category}</div>
              </div>
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
                      style={{ width: `${hcp.competitive_intel.competitive_pressure_score || 0}%` }}
                    />
                  </div>
                  <span className="text-sm font-bold">{hcp.competitive_intel.competitive_pressure_score || 0}/100</span>
                </div>
              </div>
              <div>
                <div className="text-xs text-muted-foreground mb-1">Competitor Strength</div>
                <span className={`inline-block px-2 py-1 rounded text-xs font-semibold ${
                  hcp.competitive_intel.competitor_strength === 'Dominant' ? 'bg-red-100 text-red-700' :
                  hcp.competitive_intel.competitor_strength === 'Strong' ? 'bg-orange-100 text-orange-700' :
                  hcp.competitive_intel.competitor_strength === 'Moderate' ? 'bg-yellow-100 text-yellow-700' :
                  'bg-green-100 text-green-700'
                }`}>
                  {hcp.competitive_intel.competitor_strength}
                </span>
              </div>
              <div>
                <div className="text-xs text-muted-foreground mb-1">Situation</div>
                <div className="text-sm">{hcp.competitive_intel.competitive_situation}</div>
              </div>
              <div className="pt-2 border-t">
                <div className="text-xs text-muted-foreground mb-2">Likely Competitors</div>
                <div className="flex flex-wrap gap-1">
                  {hcp.competitive_intel.inferred_competitors?.map((comp, idx) => (
                    <span key={idx} className="text-xs bg-gray-100 px-2 py-1 rounded">
                      {comp}
                    </span>
                  ))}
                </div>
              </div>
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
                            {formatPercent(hcp.predictions.call_success_prob, 0)}
                          </span>
                        </div>
                      </div>
                      <div className="overflow-hidden h-2 text-xs flex rounded bg-blue-200">
                        <div
                          style={{ width: `${hcp.predictions.call_success_prob * 100}%` }}
                          className="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-blue-600"
                        ></div>
                      </div>
                    </div>
                  </div>

                  <div>
                    <div className="text-sm font-medium text-muted-foreground mb-2">Forecasted Lift</div>
                    <div className="text-3xl font-bold text-green-600">{hcp.predictions.forecasted_lift >= 0 ? '+' : ''}{formatNumber(hcp.predictions.forecasted_lift, 1)} TRx</div>
                    <div className="text-sm text-muted-foreground">Expected increase</div>
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
              <CardTitle>Call History</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">Call history timeline coming soon...</p>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
