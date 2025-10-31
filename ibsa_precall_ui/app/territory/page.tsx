'use client'

import { useState, useEffect } from 'react'
import { getHCPs } from '@/lib/api/data-loader'
import type { HCP } from '@/lib/types'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { formatNumber, formatPercent } from '@/lib/utils'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, LineChart, Line, Legend, ScatterChart, Scatter } from 'recharts'
import { TrendingUp, Users, Target, Award, MapPin, Brain, Activity, DollarSign, Package, ShieldAlert } from 'lucide-react'

export default function TerritoryDashboardPage() {
  const [data, setData] = useState<HCP[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedTerritory, setSelectedTerritory] = useState<string>('all')

  useEffect(() => {
    loadData()
  }, [])

  async function loadData() {
    setLoading(true)
    try {
      // Use much smaller sample for fast loading - 2000 HCPs is enough for territory trends
      const params = new URLSearchParams()
      params.set('limit', '2000')  // Optimized for speed while maintaining accuracy
      params.set('offset', '0')
      
      const response = await fetch(`/api/hcps?${params}`, {
        next: { revalidate: 60 } // Cache for 1 minute
      })
      if (!response.ok) {
        console.error('Failed to fetch HCPs from API')
        setData([])
        setLoading(false)
        return
      }
      
      const { data: rawData } = await response.json()
      
      // Transform to HCP format
      const hcps = rawData.map((row: any) => {
        const npi = String(row.NPI || row.PrescriberId || '').replace('.0', '')
        return {
          npi,
          name: String(row.PrescriberName || npi),
          specialty: String(row.Specialty || 'General Practice'),
          city: String(row.City || ''),
          state: String(row.State || ''),
          territory: String(row.Territory || row.TerritoryName || row.State || 'Unknown'),
          region: String(row.RegionName || row.State || 'Unknown'),
          tier: String(row.Tier || 'N/A'),
          trx_current: Number(row.TRx_Current || row.trx_current_qtd) || 0,
          trx_prior: Number(row.trx_prior_qtd) || 0,
          trx_growth: Number(row.forecasted_lift) || 0,
          last_call_date: null,
          days_since_call: null,
          next_call_date: null,
          priority: 1,
          ibsa_share: Number(row.ibsa_share) || 0,
          nrx_count: Number(row.nrx_current_qtd) || 0,
          call_success_score: Number(row.call_success_prob) || 0,
          value_score: Number(row.expected_roi) || 0,
          rx_lift: Number(row.forecasted_lift) || 0,
          ngd_decile: 5,
          ngd_classification: String(row.ngd_classification || 'Stable'),
          // Product-specific TRx
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
          competitor_nrx_imdur_nitrates: Number(row.competitor_nrx_imdur_nitrates) || 0,
        }
      })
      
      console.log(`Loaded ${hcps.length} HCPs for territory analytics`)
      setData(hcps)
    } catch (error) {
      console.error('Error loading HCP data:', error)
      setData([])
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="flex items-center gap-3">
          <Brain className="h-8 w-8 animate-pulse text-blue-600" />
          <div className="text-lg">Loading territory analytics...</div>
        </div>
      </div>
    )
  }

  // Filter data by territory
  const filteredData = selectedTerritory === 'all' ? data : data.filter(h => h.territory === selectedTerritory)

  // Get unique territories
  const territories = Array.from(new Set(data.map(h => h.territory))).sort()

  // Territory-level metrics
  const territoryMetrics = territories.map(territory => {
    const hcps = data.filter(h => h.territory === territory)
    const totalTRx = hcps.reduce((sum, h) => sum + h.trx_current, 0)
    const totalPriorTRx = hcps.reduce((sum, h) => sum + h.trx_prior, 0)
    const growth = totalPriorTRx > 0 ? ((totalTRx - totalPriorTRx) / totalPriorTRx) * 100 : 0
    const avgMarketShare = hcps.reduce((sum, h) => sum + h.ibsa_share, 0) / hcps.length
    const highPriority = hcps.filter(h => h.priority <= 2).length
    const newGrowers = hcps.filter(h => h.ngd_classification === 'New' || h.ngd_classification === 'Grower').length
    const avgCallSuccess = hcps.reduce((sum, h) => sum + (h.call_success_score || 0), 0) / hcps.length * 100 // Convert to percentage
    const avgPowerScore = hcps.reduce((sum, h) => sum + (h.value_score || 0), 0) / hcps.length

    // Product-specific TRx
    const tirosintTRx = hcps.reduce((sum, h) => sum + (h.tirosint_trx || 0), 0)
    const flectorTRx = hcps.reduce((sum, h) => sum + (h.flector_trx || 0), 0)
    const licartTRx = hcps.reduce((sum, h) => sum + (h.licart_trx || 0), 0)
    const ibsaTotalTRx = tirosintTRx + flectorTRx + licartTRx

    // Competitor TRx
    const competitorTRx = hcps.reduce((sum, h) => sum + (h.competitor_trx || 0), 0)
    const synthroidTRx = hcps.reduce((sum, h) => sum + (h.competitor_synthroid_levothyroxine || 0), 0)
    const voltarenTRx = hcps.reduce((sum, h) => sum + (h.competitor_voltaren_diclofenac || 0), 0)
    const imdurTRx = hcps.reduce((sum, h) => sum + (h.competitor_imdur_nitrates || 0), 0)

    // NRx data
    const ibsaNRx = hcps.reduce((sum, h) => sum + (h.ibsa_nrx_qtd || 0), 0)
    const competitorNRx = hcps.reduce((sum, h) => sum + (h.competitor_nrx || 0), 0)

    return {
      territory,
      totalTRx,
      growth,
      hcpCount: hcps.length,
      avgTRxPerHCP: totalTRx / hcps.length,
      avgMarketShare,
      highPriority,
      newGrowers,
      newGrowersPct: (newGrowers / hcps.length) * 100,
      avgCallSuccess,
      avgPowerScore: avgPowerScore, // From expected_roi (ML model output)
      platinumCount: hcps.filter(h => h.tier === 'Platinum').length,
      goldCount: hcps.filter(h => h.tier === 'Gold').length,
      // Product-specific metrics
      tirosintTRx,
      flectorTRx,
      licartTRx,
      ibsaTotalTRx,
      // Competitor metrics
      competitorTRx,
      synthroidTRx,
      voltarenTRx,
      imdurTRx,
      // NRx metrics
      ibsaNRx,
      competitorNRx,
      // Market share
      marketShare: ibsaTotalTRx + competitorTRx > 0 ? (ibsaTotalTRx / (ibsaTotalTRx + competitorTRx)) * 100 : 0
    }
  }).sort((a, b) => b.totalTRx - a.totalTRx)

  // Overall KPIs
  const totalTRx = filteredData.reduce((sum, h) => sum + h.trx_current, 0)
  const totalPriorTRx = filteredData.reduce((sum, h) => sum + h.trx_prior, 0)
  const overallGrowth = totalPriorTRx > 0 ? ((totalTRx - totalPriorTRx) / totalPriorTRx) * 100 : 0
  const avgMarketShare = filteredData.reduce((sum, h) => sum + h.ibsa_share, 0) / filteredData.length
  const highPriorityCount = filteredData.filter(h => h.priority <= 2).length
  const newGrowerCount = filteredData.filter(h => h.ngd_classification === 'New' || h.ngd_classification === 'Grower').length

  // NGD Distribution
  const ngdData = [
    { name: 'New', value: filteredData.filter(h => h.ngd_classification === 'New').length, color: '#3b82f6' },
    { name: 'Grower', value: filteredData.filter(h => h.ngd_classification === 'Grower').length, color: '#10b981' },
    { name: 'Stable', value: filteredData.filter(h => h.ngd_classification === 'Stable').length, color: '#6b7280' },
    { name: 'Decliner', value: filteredData.filter(h => h.ngd_classification === 'Decliner').length, color: '#ef4444' }
  ]

  // Tier Distribution
  const tierData = [
    { name: 'Platinum', value: filteredData.filter(h => h.tier === 'Platinum').length, color: '#fbbf24' },
    { name: 'Gold', value: filteredData.filter(h => h.tier === 'Gold').length, color: '#94a3b8' },
    { name: 'Silver', value: filteredData.filter(h => h.tier === 'Silver').length, color: '#60a5fa' },
    { name: 'Bronze', value: filteredData.filter(h => h.tier === 'Bronze').length, color: '#78716c' }
  ]

  // Top 10 territories for chart
  const top10Territories = territoryMetrics.slice(0, 10)

  // Territory growth comparison
  const territoryGrowthData = territoryMetrics
    .filter(t => t.hcpCount >= 10) // Only territories with 10+ HCPs
    .sort((a, b) => b.growth - a.growth)
    .slice(0, 12)

  return (
    <div className="container mx-auto py-6 space-y-6">
      {/* Header */}
      <div className="bg-gradient-to-r from-purple-600 to-blue-600 rounded-lg p-6 text-white shadow-lg">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <MapPin className="h-12 w-12" />
            <div>
              <h1 className="text-3xl font-bold mb-1">Territory Performance Analytics</h1>
              <p className="text-blue-100">AI-powered insights across {territories.length} territories</p>
            </div>
          </div>
          <div className="text-right">
            <div className="text-sm text-blue-100">Total HCPs</div>
            <div className="text-4xl font-bold">{formatNumber(filteredData.length)}</div>
          </div>
        </div>
      </div>

      {/* Territory Selector */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex items-center gap-4">
            <label className="font-medium">Filter by Territory:</label>
            <select
              value={selectedTerritory}
              onChange={(e) => setSelectedTerritory(e.target.value)}
              className="px-4 py-2 border rounded-md min-w-[300px]"
            >
              <option value="all">All Territories</option>
              {territories.map(territory => (
                <option key={territory} value={territory}>{territory}</option>
              ))}
            </select>
            {selectedTerritory !== 'all' && (
              <Button variant="ghost" size="sm" onClick={() => setSelectedTerritory('all')}>
                Clear Filter
              </Button>
            )}
          </div>
        </CardContent>
      </Card>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
        <Card className="border-2 border-blue-500">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
              <Activity className="h-4 w-4" />
              Total TRx
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">{formatNumber(totalTRx)}</div>
            <div className={`text-sm font-medium ${overallGrowth >= 0 ? 'text-green-600' : 'text-red-600'}`}>
              {overallGrowth >= 0 ? '↑' : '↓'} {formatPercent(Math.abs(overallGrowth) / 100, 1)} vs prior
            </div>
          </CardContent>
        </Card>

        <Card className="border-2 border-green-500">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
              <TrendingUp className="h-4 w-4" />
              New & Growers
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-green-600">{formatNumber(newGrowerCount)}</div>
            <div className="text-sm text-muted-foreground">
              {formatPercent((newGrowerCount / filteredData.length), 0)} of total HCPs
            </div>
          </CardContent>
        </Card>

        <Card className="border-2 border-purple-500">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
              <Target className="h-4 w-4" />
              High Priority
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-purple-600">{formatNumber(highPriorityCount)}</div>
            <div className="text-sm text-muted-foreground">
              Priority 1-2 targets
            </div>
          </CardContent>
        </Card>

        <Card className="border-2 border-amber-500">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
              <DollarSign className="h-4 w-4" />
              Avg Market Share
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-amber-600">{formatPercent(avgMarketShare / 100, 0)}</div>
            <div className="text-sm text-muted-foreground">
              Average across HCPs
            </div>
          </CardContent>
        </Card>

        <Card className="border-2 border-blue-500">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
              <Brain className="h-4 w-4" />
              Avg Call Success
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-blue-600">
              {formatPercent(filteredData.reduce((sum, h) => sum + (h.call_success_score || 0), 0) / filteredData.length, 0)}
            </div>
            <div className="text-sm text-muted-foreground">
              ML prediction
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Product-Specific Intelligence KPIs */}
      <Card className="bg-gradient-to-r from-blue-50 to-purple-50 border-2 border-blue-200">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Package className="h-5 w-5 text-blue-600" />
            Product Portfolio Intelligence
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Tirosint */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium text-gray-600">Tirosint</span>
                <span className="text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded">Thyroid</span>
              </div>
              <div className="text-3xl font-bold text-blue-600">
                {formatNumber(filteredData.reduce((sum, h) => sum + (h.tirosint_trx || 0), 0))}
              </div>
              <div className="text-sm text-gray-500">Total TRx</div>
              <div className="flex items-center gap-2 text-sm">
                <span className="text-gray-600">vs Synthroid:</span>
                <span className="font-semibold text-orange-600">
                  {formatNumber(filteredData.reduce((sum, h) => sum + (h.competitor_synthroid_levothyroxine || 0), 0))} TRx
                </span>
              </div>
            </div>

            {/* Flector */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium text-gray-600">Flector</span>
                <span className="text-xs bg-green-100 text-green-700 px-2 py-1 rounded">Pain Mgmt</span>
              </div>
              <div className="text-3xl font-bold text-green-600">
                {formatNumber(filteredData.reduce((sum, h) => sum + (h.flector_trx || 0), 0))}
              </div>
              <div className="text-sm text-gray-500">Total TRx</div>
              <div className="flex items-center gap-2 text-sm">
                <span className="text-gray-600">vs Voltaren:</span>
                <span className="font-semibold text-orange-600">
                  {formatNumber(filteredData.reduce((sum, h) => sum + (h.competitor_voltaren_diclofenac || 0), 0))} TRx
                </span>
              </div>
            </div>

            {/* Licart */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium text-gray-600">Licart</span>
                <span className="text-xs bg-purple-100 text-purple-700 px-2 py-1 rounded">Cardiology</span>
              </div>
              <div className="text-3xl font-bold text-purple-600">
                {formatNumber(filteredData.reduce((sum, h) => sum + (h.licart_trx || 0), 0))}
              </div>
              <div className="text-sm text-gray-500">Total TRx</div>
              <div className="flex items-center gap-2 text-sm">
                <span className="text-gray-600">vs Imdur:</span>
                <span className="font-semibold text-orange-600">
                  {formatNumber(filteredData.reduce((sum, h) => sum + (h.competitor_imdur_nitrates || 0), 0))} TRx
                </span>
              </div>
            </div>
          </div>

          {/* Market Share Summary */}
          <div className="mt-6 pt-6 border-t border-blue-200">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="text-center">
                <div className="text-sm text-gray-600 mb-1">IBSA Total TRx</div>
                <div className="text-2xl font-bold text-blue-600">
                  {formatNumber(
                    filteredData.reduce((sum, h) => 
                      sum + (h.tirosint_trx || 0) + (h.flector_trx || 0) + (h.licart_trx || 0), 0
                    )
                  )}
                </div>
              </div>
              <div className="text-center">
                <div className="text-sm text-gray-600 mb-1">Competitor Total TRx</div>
                <div className="text-2xl font-bold text-orange-600">
                  {formatNumber(filteredData.reduce((sum, h) => sum + (h.competitor_trx || 0), 0))}
                </div>
              </div>
              <div className="text-center">
                <div className="text-sm text-gray-600 mb-1">IBSA Market Share</div>
                <div className="text-2xl font-bold text-green-600">
                  {formatPercent(
                    filteredData.reduce((sum, h) => 
                      sum + (h.tirosint_trx || 0) + (h.flector_trx || 0) + (h.licart_trx || 0), 0
                    ) / 
                    (filteredData.reduce((sum, h) => 
                      sum + (h.tirosint_trx || 0) + (h.flector_trx || 0) + (h.licart_trx || 0) + (h.competitor_trx || 0), 0
                    ) || 1),
                    1
                  )}
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Charts Row 1 - NGD Classification */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <TrendingUp className="h-5 w-5 text-green-600" />
            NGD Classification Distribution
          </CardTitle>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={ngdData} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis type="number" />
              <YAxis dataKey="name" type="category" width={100} />
              <Tooltip formatter={(value: any) => `${formatNumber(value)} HCPs`} />
              <Bar dataKey="value" name="HCP Count">
                {ngdData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
          <div className="grid grid-cols-4 gap-4 mt-4">
            {ngdData.map((item) => (
              <div key={item.name} className="text-center">
                <div className="text-2xl font-bold" style={{ color: item.color }}>
                  {formatNumber(item.value)}
                </div>
                <div className="text-sm text-gray-600">{item.name}</div>
                <div className="text-xs text-gray-500">
                  {formatPercent(item.value / filteredData.length, 0)}
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Charts Row 2 - Product Intelligence */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* IBSA Product Mix */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Package className="h-5 w-5 text-blue-600" />
              IBSA Product Mix (TRx + NRx)
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart 
                data={[
                  { 
                    name: 'Tirosint', 
                    trx: filteredData.reduce((sum, h) => sum + (h.tirosint_trx || 0), 0),
                    nrx: filteredData.reduce((sum, h) => sum + (h.ibsa_nrx_qtd || 0), 0) * 0.4 // Approximate Tirosint portion
                  },
                  { 
                    name: 'Flector', 
                    trx: filteredData.reduce((sum, h) => sum + (h.flector_trx || 0), 0),
                    nrx: filteredData.reduce((sum, h) => sum + (h.ibsa_nrx_qtd || 0), 0) * 0.35 // Approximate Flector portion
                  },
                  { 
                    name: 'Licart', 
                    trx: filteredData.reduce((sum, h) => sum + (h.licart_trx || 0), 0),
                    nrx: filteredData.reduce((sum, h) => sum + (h.ibsa_nrx_qtd || 0), 0) * 0.25 // Approximate Licart portion
                  }
                ]}
              >
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip formatter={(value: any) => formatNumber(value)} />
                <Legend />
                <Bar dataKey="trx" stackId="a" fill="#1e40af" name="TRx" />
                <Bar dataKey="nrx" stackId="a" fill="#60a5fa" name="NRx" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Competitive Intelligence */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Target className="h-5 w-5 text-red-600" />
              IBSA vs Competitor Market Share
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart 
                data={[
                  {
                    category: 'IBSA Total',
                    trx: filteredData.reduce((sum, h) => sum + (h.tirosint_trx || 0) + (h.flector_trx || 0) + (h.licart_trx || 0), 0),
                    nrx: filteredData.reduce((sum, h) => sum + (h.ibsa_nrx_qtd || 0), 0)
                  },
                  {
                    category: 'Competitors',
                    trx: filteredData.reduce((sum, h) => sum + (h.competitor_trx || 0), 0),
                    nrx: filteredData.reduce((sum, h) => sum + (h.competitor_nrx || 0), 0)
                  }
                ]}
                layout="vertical"
              >
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis type="number" />
                <YAxis dataKey="category" type="category" width={120} />
                <Tooltip formatter={(value: any) => formatNumber(value)} />
                <Legend />
                <Bar dataKey="trx" stackId="a" fill="#1e40af" name="TRx" />
                <Bar dataKey="nrx" stackId="a" fill="#60a5fa" name="NRx" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      {/* Charts Row 3 - Competitor Breakdown */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <ShieldAlert className="h-5 w-5 text-orange-600" />
            Competitor Product Breakdown
          </CardTitle>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart 
              data={[
                { 
                  name: 'Synthroid/Levothyroxine', 
                  value: filteredData.reduce((sum, h) => sum + (h.competitor_synthroid_levothyroxine || 0), 0)
                },
                { 
                  name: 'Voltaren/Diclofenac', 
                  value: filteredData.reduce((sum, h) => sum + (h.competitor_voltaren_diclofenac || 0), 0)
                },
                { 
                  name: 'Imdur/Nitrates', 
                  value: filteredData.reduce((sum, h) => sum + (h.competitor_imdur_nitrates || 0), 0)
                }
              ]}
            >
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" angle={-15} textAnchor="end" height={80} />
              <YAxis label={{ value: 'Total TRx', angle: -90, position: 'insideLeft' }} />
              <Tooltip formatter={(value: any) => formatNumber(value)} />
              <Bar dataKey="value" fill="#f59e0b" name="Competitor TRx" />
            </BarChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      {/* Charts Row 4 - Territory Performance */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* Top 10 Territories by TRx */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Activity className="h-5 w-5 text-blue-600" />
              Top 10 Territories by Total TRx
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={400}>
              <BarChart data={top10Territories} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis type="number" />
                <YAxis dataKey="territory" type="category" width={180} tick={{ fontSize: 11 }} />
                <Tooltip 
                  formatter={(value: any, name: string) => [
                    name === 'totalTRx' ? formatNumber(value) :
                    name === 'avgTRxPerHCP' ? formatNumber(value, 1) :
                    value,
                    name === 'totalTRx' ? 'Total TRx' :
                    name === 'avgTRxPerHCP' ? 'Avg TRx/HCP' :
                    name
                  ]}
                />
                <Bar dataKey="totalTRx" fill="#2563eb" name="Total TRx" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Top Territories by Market Share */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Target className="h-5 w-5 text-green-600" />
              Top 10 Territories by IBSA Market Share
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={400}>
              <BarChart 
                data={territoryMetrics
                  .filter(t => t.hcpCount >= 5)
                  .sort((a, b) => b.marketShare - a.marketShare)
                  .slice(0, 10)
                }
                layout="vertical"
              >
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis type="number" label={{ value: 'Market Share %', position: 'bottom' }} />
                <YAxis dataKey="territory" type="category" width={180} tick={{ fontSize: 11 }} />
                <Tooltip 
                  formatter={(value: any) => `${Number(value).toFixed(1)}%`}
                />
                <Bar dataKey="marketShare" fill="#10b981" name="Market Share %" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      {/* Territory Rankings Table */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <MapPin className="h-5 w-5 text-purple-600" />
            Complete Territory Rankings
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b bg-gray-50">
                  <th className="text-left p-3 font-semibold">Rank</th>
                  <th className="text-left p-3 font-semibold">Territory</th>
                  <th className="text-right p-3 font-semibold">IBSA TRx</th>
                  <th className="text-right p-3 font-semibold">Comp TRx</th>
                  <th className="text-right p-3 font-semibold">Market Share</th>
                  <th className="text-right p-3 font-semibold">Growth %</th>
                  <th className="text-right p-3 font-semibold">HCPs</th>
                  <th className="text-right p-3 font-semibold">Tirosint</th>
                  <th className="text-right p-3 font-semibold">Flector</th>
                  <th className="text-right p-3 font-semibold">Licart</th>
                  <th className="text-right p-3 font-semibold">High Priority</th>
                  <th className="text-right p-3 font-semibold">New/Growers</th>
                </tr>
              </thead>
              <tbody>
                {territoryMetrics.map((territory, index) => (
                  <tr key={territory.territory} className="border-b hover:bg-gray-50 cursor-pointer"
                      onClick={() => setSelectedTerritory(territory.territory)}>
                    <td className="p-3">
                      <span className={`inline-flex items-center justify-center w-8 h-8 rounded-full text-sm font-bold ${
                        index === 0 ? 'bg-yellow-100 text-yellow-700' :
                        index === 1 ? 'bg-gray-200 text-gray-700' :
                        index === 2 ? 'bg-orange-100 text-orange-700' :
                        'bg-blue-50 text-blue-700'
                      }`}>
                        {index + 1}
                      </span>
                    </td>
                    <td className="p-3 font-medium">{territory.territory}</td>
                    <td className="p-3 text-right font-mono text-blue-600 font-semibold">{formatNumber(territory.ibsaTotalTRx)}</td>
                    <td className="p-3 text-right font-mono text-orange-600 font-semibold">{formatNumber(territory.competitorTRx)}</td>
                    <td className="p-3 text-right">
                      <span className={`inline-flex items-center px-2 py-1 rounded text-xs font-semibold ${
                        territory.marketShare >= 50 ? 'bg-green-100 text-green-700' :
                        territory.marketShare >= 30 ? 'bg-blue-100 text-blue-700' :
                        'bg-amber-100 text-amber-700'
                      }`}>
                        {formatPercent(territory.marketShare / 100, 0)}
                      </span>
                    </td>
                    <td className="p-3 text-right">
                      <span className={`font-semibold ${territory.growth >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                        {territory.growth >= 0 ? '↑' : '↓'} {formatPercent(Math.abs(territory.growth) / 100, 1)}
                      </span>
                    </td>
                    <td className="p-3 text-right font-mono">{formatNumber(territory.hcpCount)}</td>
                    <td className="p-3 text-right font-mono text-sm">{formatNumber(territory.tirosintTRx)}</td>
                    <td className="p-3 text-right font-mono text-sm">{formatNumber(territory.flectorTRx)}</td>
                    <td className="p-3 text-right font-mono text-sm">{formatNumber(territory.licartTRx)}</td>
                    <td className="p-3 text-right">
                      <span className="inline-flex items-center px-2 py-1 rounded text-xs font-semibold bg-purple-100 text-purple-700">
                        {territory.highPriority}
                      </span>
                    </td>
                    <td className="p-3 text-right">
                      <span className="inline-flex items-center px-2 py-1 rounded text-xs font-semibold bg-green-100 text-green-700">
                        {territory.newGrowers} ({formatPercent(territory.newGrowersPct / 100, 0)})
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Additional Insights */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
              <Users className="h-4 w-4" />
              Avg HCPs per Territory
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">
              {formatNumber(data.length / territories.length, 0)}
            </div>
            <div className="text-sm text-muted-foreground">
              {territories.length} active territories
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
              <Brain className="h-4 w-4" />
              Avg HCP Power Score
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-blue-600">
              {formatNumber(filteredData.reduce((sum, h) => sum + (h.value_score || 0), 0) / filteredData.length, 0)}
            </div>
            <div className="text-sm text-muted-foreground">
              Out of 100
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground flex items-center gap-2">
              <Target className="h-4 w-4" />
              High-Value Targets
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-purple-600">
              {formatNumber(filteredData.filter(h => h.tier === 'Platinum' || h.tier === 'Gold').length)}
            </div>
            <div className="text-sm text-muted-foreground">
              Platinum + Gold HCPs
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
