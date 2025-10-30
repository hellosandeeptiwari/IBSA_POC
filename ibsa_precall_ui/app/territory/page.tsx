'use client'

import { useState, useEffect } from 'react'
import { getHCPs } from '@/lib/api/data-loader'
import type { HCP } from '@/lib/types'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { formatNumber, formatPercent } from '@/lib/utils'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, LineChart, Line, Legend, ScatterChart, Scatter } from 'recharts'
import { TrendingUp, Users, Target, Award, MapPin, Brain, Activity, DollarSign } from 'lucide-react'

export default function TerritoryDashboardPage() {
  const [data, setData] = useState<HCP[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedTerritory, setSelectedTerritory] = useState<string>('all')

  useEffect(() => {
    loadData()
  }, [])

  async function loadData() {
    setLoading(true)
    const hcps = await getHCPs()
    setData(hcps)
    setLoading(false)
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
      goldCount: hcps.filter(h => h.tier === 'Gold').length
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

      {/* Charts Row 1 - NGD and Tier Distribution */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* NGD Distribution */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5 text-green-600" />
              NGD Classification
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={ngdData}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  outerRadius={100}
                  label={(entry) => `${entry.name}: ${entry.value} (${((entry.value / filteredData.length) * 100).toFixed(0)}%)`}
                >
                  {ngdData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Tier Distribution */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Award className="h-5 w-5 text-amber-500" />
              HCP Tier Distribution
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={tierData}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  outerRadius={100}
                  label={(entry) => `${entry.name}: ${entry.value}`}
                >
                  {tierData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      {/* Charts Row 2 - Territory Performance */}
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

        {/* Territory Growth Analysis */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5 text-green-600" />
              Territory Growth Rate (QoQ)
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={400}>
              <BarChart data={territoryGrowthData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="territory" angle={-45} textAnchor="end" height={100} tick={{ fontSize: 10 }} />
                <YAxis label={{ value: 'Growth %', angle: -90, position: 'insideLeft' }} />
                <Tooltip 
                  formatter={(value: any) => `${Number(value).toFixed(1)}%`}
                />
                <Bar dataKey="growth" fill="#10b981" name="Growth %" />
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
                  <th className="text-right p-3 font-semibold">Total TRx</th>
                  <th className="text-right p-3 font-semibold">Growth %</th>
                  <th className="text-right p-3 font-semibold">HCPs</th>
                  <th className="text-right p-3 font-semibold">Avg TRx/HCP</th>
                  <th className="text-right p-3 font-semibold">Market Share</th>
                  <th className="text-right p-3 font-semibold">High Priority</th>
                  <th className="text-right p-3 font-semibold">New/Growers</th>
                  <th className="text-right p-3 font-semibold">Call Success</th>
                  <th className="text-right p-3 font-semibold">HCP Power Score</th>
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
                    <td className="p-3 text-right font-mono text-blue-600 font-semibold">{formatNumber(territory.totalTRx)}</td>
                    <td className="p-3 text-right">
                      <span className={`font-semibold ${territory.growth >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                        {territory.growth >= 0 ? '↑' : '↓'} {formatPercent(Math.abs(territory.growth) / 100, 1)}
                      </span>
                    </td>
                    <td className="p-3 text-right font-mono">{formatNumber(territory.hcpCount)}</td>
                    <td className="p-3 text-right font-mono">{formatNumber(territory.avgTRxPerHCP, 1)}</td>
                    <td className="p-3 text-right">
                      <span className={`inline-flex items-center px-2 py-1 rounded text-xs font-semibold ${
                        territory.avgMarketShare >= 50 ? 'bg-green-100 text-green-700' :
                        territory.avgMarketShare >= 30 ? 'bg-blue-100 text-blue-700' :
                        'bg-amber-100 text-amber-700'
                      }`}>
                        {formatPercent(territory.avgMarketShare / 100, 0)}
                      </span>
                    </td>
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
                    <td className="p-3 text-right">
                      <span className={`inline-flex items-center px-2 py-1 rounded text-xs font-semibold ${
                        territory.avgCallSuccess >= 10 ? 'bg-blue-100 text-blue-700' :
                        territory.avgCallSuccess >= 5 ? 'bg-gray-100 text-gray-700' :
                        'bg-red-100 text-red-700'
                      }`}>
                        {formatPercent(territory.avgCallSuccess / 100, 0)}
                      </span>
                    </td>
                    <td className="p-3 text-right">
                      <span className={`inline-flex items-center justify-center w-10 h-10 rounded-full text-sm font-bold ${
                        territory.avgPowerScore >= 75 ? 'bg-green-100 text-green-700' :
                        territory.avgPowerScore >= 50 ? 'bg-blue-100 text-blue-700' :
                        'bg-gray-100 text-gray-700'
                      }`}>
                        {Math.round(territory.avgPowerScore)}
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
