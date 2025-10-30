'use client'

import { useState, useEffect, useMemo } from 'react'
import { useRouter } from 'next/navigation'
import { getHCPs } from '@/lib/api/data-loader'
import type { HCP } from '@/lib/types'
import { TierBadge } from '@/components/ui/tier-badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Tooltip } from '@/components/ui/tooltip'
import { formatNumber, formatPercent, formatDate } from '@/lib/utils'
import { Search, Filter, Brain, TrendingUp, Target, DollarSign, Sparkles, Bot } from 'lucide-react'

export default function DashboardPage() {
  const router = useRouter()
  const [data, setData] = useState<HCP[]>([])
  const [loading, setLoading] = useState(true)
  const [loadingProgress, setLoadingProgress] = useState(0)
  const [globalFilter, setGlobalFilter] = useState('')
  const [showFilters, setShowFilters] = useState(false)
  const [currentPage, setCurrentPage] = useState(0)
  const [pageSize, setPageSize] = useState(20)  // Show 20 HCPs per page
  
  // Sorting states
  const [sortColumn, setSortColumn] = useState<string>('trx_current')  // Sort by Total TRx to show HCPs with activity
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('desc')
  
  // Filter states
  const [selectedTiers, setSelectedTiers] = useState<string[]>([])
  const [selectedSpecialties, setSelectedSpecialties] = useState<string[]>([])
  const [selectedTerritories, setSelectedTerritories] = useState<string[]>([])
  const [minTrx, setMinTrx] = useState(0)  // Show all HCPs initially

  useEffect(() => {
    loadData()
  }, [])

  async function loadData() {
    setLoading(true)
    setLoadingProgress(10)
    const startTime = performance.now()
    try {
      setLoadingProgress(30)
      const hcps = await getHCPs()
      setLoadingProgress(80)
      const loadTime = performance.now() - startTime
      console.log(`⚡ Data loaded in ${loadTime.toFixed(0)}ms (${hcps.length} HCPs)`)
      setData(hcps)
      setLoadingProgress(100)
    } catch (error) {
      console.error('Error loading HCPs:', error)
    } finally {
      setTimeout(() => setLoading(false), 200) // Small delay for smooth transition
    }
  }

  const filteredData = useMemo(() => {
    let filtered = data.filter(hcp => {
      // Filter out invalid NPIs (empty, null, or undefined)
      if (!hcp.npi || hcp.npi === '' || hcp.npi === 'undefined') return false
      
      // Apply tier filter
      if (selectedTiers.length > 0 && !selectedTiers.includes(hcp.tier)) return false
      
      // Apply specialty filter
      if (selectedSpecialties.length > 0 && !selectedSpecialties.includes(hcp.specialty)) return false
      
      // Apply territory filter
      if (selectedTerritories.length > 0 && !selectedTerritories.includes(hcp.territory)) return false
      
      // Apply minimum TRx filter
      if (minTrx > 0 && hcp.trx_current < minTrx) return false
      
      // Apply global search filter
      if (globalFilter) {
        const searchLower = globalFilter.toLowerCase()
        const matchesNpi = hcp.npi.toLowerCase().includes(searchLower)
        const matchesName = hcp.name.toLowerCase().includes(searchLower)
        const matchesTerritory = hcp.territory.toLowerCase().includes(searchLower)
        const matchesSpecialty = hcp.specialty.toLowerCase().includes(searchLower)
        
        if (!matchesNpi && !matchesName && !matchesTerritory && !matchesSpecialty) {
          return false
        }
      }
      
      return true
    })

    // Apply sorting
    if (sortColumn) {
      filtered = [...filtered].sort((a, b) => {
        let aVal: any = a[sortColumn as keyof HCP]
        let bVal: any = b[sortColumn as keyof HCP]
        
        // Handle special cases
        if (sortColumn === 'value_score') {
          aVal = a.value_score || 0
          bVal = b.value_score || 0
        } else if (sortColumn === 'call_success_score') {
          aVal = (a.call_success_score || 0) * 100
          bVal = (b.call_success_score || 0) * 100
        }
        
        // Convert to numbers if possible
        const aNum = typeof aVal === 'number' ? aVal : parseFloat(aVal as string)
        const bNum = typeof bVal === 'number' ? bVal : parseFloat(bVal as string)
        
        if (!isNaN(aNum) && !isNaN(bNum)) {
          return sortDirection === 'asc' ? aNum - bNum : bNum - aNum
        }
        
        // String comparison
        const aStr = String(aVal || '').toLowerCase()
        const bStr = String(bVal || '').toLowerCase()
        
        if (sortDirection === 'asc') {
          return aStr < bStr ? -1 : aStr > bStr ? 1 : 0
        } else {
          return bStr < aStr ? -1 : bStr > aStr ? 1 : 0
        }
      })
    }
    
    return filtered
  }, [data, selectedTiers, selectedSpecialties, selectedTerritories, minTrx, globalFilter, sortColumn, sortDirection])

  const handleTierToggle = (tier: string) => {
    setSelectedTiers(prev =>
      prev.includes(tier) ? prev.filter(t => t !== tier) : [...prev, tier]
    )
  }

  const handleTerritoryToggle = (territory: string) => {
    setSelectedTerritories(prev =>
      prev.includes(territory) ? prev.filter(t => t !== territory) : [...prev, territory]
    )
  }

  const handleClearFilters = () => {
    setSelectedTiers([])
    setSelectedSpecialties([])
    setSelectedTerritories([])
    setMinTrx(0)
    setGlobalFilter('')
  }

  const handleSort = (column: string) => {
    if (sortColumn === column) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc')
    } else {
      setSortColumn(column)
      setSortDirection('asc')
    }
  }

  const SortIcon = ({ column }: { column: string }) => {
    if (sortColumn !== column) {
      return <span className="text-gray-400 ml-1">⇅</span>
    }
    return sortDirection === 'asc' ? <span className="text-blue-600 ml-1">↑</span> : <span className="text-blue-600 ml-1">↓</span>
  }

  if (loading) {
    return (
      <div className="container mx-auto py-6 space-y-6">
        <div className="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-lg p-6 text-white shadow-lg">
          <div className="flex items-center gap-4 mb-4">
            <Brain className="h-12 w-12 animate-pulse" />
            <div>
              <h2 className="text-2xl font-bold mb-1">Loading AI-Powered Pre-Call Planning...</h2>
              <p className="text-blue-100">Fetching HCP data from secure cloud storage</p>
            </div>
          </div>
          {/* Progress Bar */}
          <div className="w-full bg-blue-800 rounded-full h-3 overflow-hidden">
            <div 
              className="bg-white h-3 rounded-full transition-all duration-500 ease-out"
              style={{ width: `${loadingProgress}%` }}
            />
          </div>
          <div className="mt-2 text-sm text-blue-100">
            {loadingProgress < 30 && "Initializing data connection..."}
            {loadingProgress >= 30 && loadingProgress < 80 && "Loading HCP records..."}
            {loadingProgress >= 80 && "Almost ready..."}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="container mx-auto py-6 space-y-6">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-lg p-6 text-white shadow-lg">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Brain className="h-12 w-12" />
            <div>
              <h2 className="text-2xl font-bold mb-1">AI-Powered Pre-Call Planning</h2>
              <p className="text-blue-100">Intelligent insights to optimize your call strategy</p>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-4 text-center">
            <div>
              <div className="text-3xl font-bold">{formatNumber(filteredData.length)}</div>
              <div className="text-sm text-blue-100">HCPs</div>
            </div>
            <div>
              <div className="text-3xl font-bold">{formatNumber(filteredData.reduce((sum, h) => sum + h.trx_current, 0))}</div>
              <div className="text-sm text-blue-100">Total TRx</div>
            </div>
            <div>
              <div className="text-3xl font-bold">{formatNumber(filteredData.filter(h => h.trx_growth > 0).length)}</div>
              <div className="text-sm text-blue-100">Growing</div>
            </div>
          </div>
        </div>
      </div>

      {/* Enhanced Filters Section */}
      <Card>
        <CardContent className="pt-4 pb-4">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <Filter className="h-4 w-4 text-blue-600" />
              <h2 className="text-base font-semibold">Filters</h2>
              {(selectedTiers.length > 0 || selectedSpecialties.length > 0 || selectedTerritories.length > 0 || minTrx > 0) && (
                <span className="px-2 py-0.5 bg-blue-100 text-blue-700 rounded-full text-xs font-medium">
                  {selectedTiers.length + selectedSpecialties.length + selectedTerritories.length + (minTrx > 0 ? 1 : 0)} active
                </span>
              )}
            </div>
            <div className="flex gap-2">
              <Button variant={showFilters ? 'default' : 'outline'} size="sm" onClick={() => setShowFilters(!showFilters)}>
                {showFilters ? 'Hide' : 'Show'} Filters
              </Button>
              {(selectedTiers.length > 0 || selectedSpecialties.length > 0 || selectedTerritories.length > 0 || minTrx > 0) && (
                <Button variant="ghost" size="sm" onClick={handleClearFilters}>
                  Clear
                </Button>
              )}
            </div>
          </div>

          {/* Search Bar - Always Visible */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <input
              type="text"
              placeholder="Search by NPI, Name, or Territory..."
              value={globalFilter}
              onChange={(e) => setGlobalFilter(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border-2 rounded-lg text-sm focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all"
            />
            {globalFilter && (
              <button
                onClick={() => setGlobalFilter('')}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                ✕
              </button>
            )}
          </div>

          {/* Filter Panels - Collapsible */}
          {showFilters && (
            <div className="space-y-4 pt-3 border-t mt-3">
              {/* Tier Filter */}
              <div>
                <div className="flex items-center justify-between mb-3">
                  <h3 className="text-sm font-semibold text-gray-700">HCP Tier</h3>
                  {selectedTiers.length > 0 && (
                    <button
                      onClick={() => setSelectedTiers([])}
                      className="text-xs text-blue-600 hover:text-blue-800"
                    >
                      Clear
                    </button>
                  )}
                </div>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                  {['Platinum', 'Gold', 'Silver', 'Bronze'].map((tier) => {
                    const count = data.filter(h => h.tier === tier).length
                    const isSelected = selectedTiers.includes(tier)
                    return (
                      <button
                        key={tier}
                        onClick={() => handleTierToggle(tier)}
                        className={`flex items-center justify-between px-4 py-3 rounded-lg border-2 transition-all ${
                          isSelected
                            ? 'border-blue-500 bg-blue-50 text-blue-700 shadow-sm'
                            : 'border-gray-200 hover:border-gray-300 bg-white'
                        }`}
                      >
                        <span className="font-medium text-sm">{tier}</span>
                        <span className={`text-xs ${isSelected ? 'text-blue-600' : 'text-gray-500'}`}>
                          {formatNumber(count)}
                        </span>
                      </button>
                    )
                  })}
                </div>
              </div>

              {/* Territory Filter */}
              <div>
                <div className="flex items-center justify-between mb-3">
                  <h3 className="text-sm font-semibold text-gray-700">Territory</h3>
                  {selectedTerritories.length > 0 && (
                    <button
                      onClick={() => setSelectedTerritories([])}
                      className="text-xs text-blue-600 hover:text-blue-800"
                    >
                      Clear ({selectedTerritories.length})
                    </button>
                  )}
                </div>
                <select
                  className="w-full px-3 py-2 text-sm border-2 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200"
                  onChange={(e) => {
                    if (e.target.value) handleTerritoryToggle(e.target.value)
                    e.target.value = ''
                  }}
                  value=""
                >
                  <option value="">Select territory...</option>
                  {Array.from(new Set(data.map(h => h.territory))).sort().map((territory) => {
                    const count = data.filter(h => h.territory === territory).length
                    return (
                      <option key={territory} value={territory}>
                        {territory} ({count} HCPs)
                      </option>
                    )
                  })}
                </select>
                {selectedTerritories.length > 0 && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    {selectedTerritories.map((territory) => (
                      <span
                        key={territory}
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-blue-100 text-blue-700 rounded-full text-xs font-medium"
                      >
                        {territory.length > 25 ? territory.substring(0, 25) + '...' : territory}
                        <button
                          onClick={() => handleTerritoryToggle(territory)}
                          className="hover:text-blue-900 font-bold"
                        >
                          ✕
                        </button>
                      </span>
                    ))}
                  </div>
                )}
              </div>

              {/* Specialty Filter */}
              <div>
                <div className="flex items-center justify-between mb-3">
                  <h3 className="text-sm font-semibold text-gray-700">Specialty</h3>
                  {selectedSpecialties.length > 0 && (
                    <button
                      onClick={() => setSelectedSpecialties([])}
                      className="text-xs text-blue-600 hover:text-blue-800"
                    >
                      Clear ({selectedSpecialties.length})
                    </button>
                  )}
                </div>
                <select
                  className="w-full px-3 py-2 text-sm border-2 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200"
                  onChange={(e) => {
                    if (e.target.value && !selectedSpecialties.includes(e.target.value)) {
                      setSelectedSpecialties([...selectedSpecialties, e.target.value])
                    }
                    e.target.value = ''
                  }}
                  value=""
                >
                  <option value="">Select specialty...</option>
                  {Array.from(new Set(data.map(h => h.specialty))).sort().map((specialty) => {
                    const count = data.filter(h => h.specialty === specialty).length
                    return (
                      <option key={specialty} value={specialty}>
                        {specialty} ({count} HCPs)
                      </option>
                    )
                  })}
                </select>
                {selectedSpecialties.length > 0 && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    {selectedSpecialties.map((specialty) => (
                      <span
                        key={specialty}
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-green-100 text-green-700 rounded-full text-xs font-medium"
                      >
                        {specialty}
                        <button
                          onClick={() => setSelectedSpecialties(selectedSpecialties.filter(s => s !== specialty))}
                          className="hover:text-green-900 font-bold"
                        >
                          ✕
                        </button>
                      </span>
                    ))}
                  </div>
                )}
              </div>

              {/* TRx Range Filter */}
              <div>
                <div className="flex items-center justify-between mb-3">
                  <h3 className="text-sm font-semibold text-gray-700">Minimum TRx Volume</h3>
                  {minTrx > 0 && (
                    <button
                      onClick={() => setMinTrx(0)}
                      className="text-xs text-blue-600 hover:text-blue-800"
                    >
                      Clear
                    </button>
                  )}
                </div>
                <div className="flex items-center gap-4">
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value={minTrx}
                    onChange={(e) => setMinTrx(Number(e.target.value))}
                    className="flex-1 h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer accent-blue-600"
                  />
                  <input
                    type="number"
                    value={minTrx}
                    onChange={(e) => setMinTrx(Number(e.target.value))}
                    className="w-20 px-3 py-2 text-sm border-2 rounded-lg text-center focus:border-blue-500 focus:ring-2 focus:ring-blue-200"
                    placeholder="0"
                  />
                </div>
                <div className="mt-2 flex justify-between text-xs text-gray-500">
                  <span>0 TRx</span>
                  <span className="font-medium text-blue-600">{minTrx} TRx minimum</span>
                  <span>100+ TRx</span>
                </div>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Summary Stats - Top Row */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card className="border-2 border-blue-500">
          <CardContent className="pt-6">
            <div className="flex items-center gap-2 text-blue-600 mb-2">
              <Brain className="h-5 w-5" />
              <div className="text-sm font-medium">Total HCPs</div>
            </div>
            <div className="text-3xl font-bold">{formatNumber(filteredData.length)}</div>
            <div className="text-xs text-gray-500 mt-1">
              {formatNumber(filteredData.filter(h => h.ngd_classification === 'New').length)} New • {' '}
              {formatNumber(filteredData.filter(h => h.ngd_classification === 'Grower').length)} Growers
            </div>
          </CardContent>
        </Card>
        
        <Card className="border-2 border-green-500">
          <CardContent className="pt-6">
            <div className="flex items-center gap-2 text-green-600 mb-2">
              <TrendingUp className="h-5 w-5" />
              <div className="text-sm font-medium">Total TRx</div>
            </div>
            <div className="text-3xl font-bold text-green-600">
              {formatNumber(filteredData.reduce((sum, h) => sum + h.trx_current, 0))}
            </div>
            <div className="text-xs text-gray-500 mt-1">
              Avg: {(filteredData.reduce((sum, h) => sum + h.trx_current, 0) / Math.max(filteredData.length, 1)).toFixed(1)} per HCP
            </div>
          </CardContent>
        </Card>
        
        <Card className="border-2 border-purple-500">
          <CardContent className="pt-6">
            <div className="flex items-center gap-2 text-purple-600 mb-2">
              <Sparkles className="h-5 w-5" />
              <div className="text-sm font-medium">Avg Power Score</div>
            </div>
            <div className="text-3xl font-bold">
              {(filteredData.reduce((sum, h) => sum + (h.value_score || 0), 0) / Math.max(filteredData.length, 1)).toFixed(0)}
            </div>
            <div className="text-xs text-gray-500 mt-1">
              {formatNumber(filteredData.filter(h => (h.value_score || 0) >= 75).length)} High Value (75+)
            </div>
          </CardContent>
        </Card>
        
        <Card className="border-2 border-orange-500">
          <CardContent className="pt-6">
            <div className="flex items-center gap-2 text-orange-600 mb-2">
              <Target className="h-5 w-5" />
              <div className="text-sm font-medium">Avg Call Success</div>
            </div>
            <div className="text-3xl font-bold text-orange-600">
              {(filteredData.reduce((sum, h) => sum + ((h.call_success_score || 0) * 100), 0) / Math.max(filteredData.length, 1)).toFixed(0)}%
            </div>
            <div className="text-xs text-gray-500 mt-1">
              {formatNumber(filteredData.filter(h => (h.call_success_score || 0) >= 0.7).length)} High Probability (70%+)
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Table */}
      <div className="rounded-md border bg-card shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full border-collapse">
            <thead className="bg-gray-50 dark:bg-gray-800">
              <tr>
                <th className="px-2 py-2 text-left text-[11px] font-medium text-gray-500 uppercase border-b cursor-pointer hover:bg-gray-100" onClick={() => handleSort('npi')}>
                  <div className="flex items-center">
                    NPI
                    <SortIcon column="npi" />
                    <Tooltip content="Unique healthcare provider ID" />
                  </div>
                </th>
                <th className="px-2 py-2 text-left text-[11px] font-medium text-gray-500 uppercase border-b cursor-pointer hover:bg-gray-100" onClick={() => handleSort('name')}>
                  <div className="flex items-center">
                    Prescriber
                    <SortIcon column="name" />
                    <Tooltip content="Healthcare provider name" />
                  </div>
                </th>
                <th className="px-2 py-2 text-left text-[11px] font-medium text-gray-500 uppercase border-b cursor-pointer hover:bg-gray-100" onClick={() => handleSort('specialty')}>
                  <div className="flex items-center">
                    Specialty
                    <SortIcon column="specialty" />
                    <Tooltip content="Medical specialty" />
                  </div>
                </th>
                <th className="px-2 py-2 text-left text-[11px] font-medium text-gray-500 uppercase border-b cursor-pointer hover:bg-gray-100" onClick={() => handleSort('territory')}>
                  <div className="flex items-center">
                    Territory
                    <SortIcon column="territory" />
                    <Tooltip content="Sales territory assignment" />
                  </div>
                </th>
                <th className="px-2 py-2 text-left text-[11px] font-medium text-gray-500 uppercase border-b bg-purple-50 cursor-pointer hover:bg-gray-100" onClick={() => handleSort('ngd_decile')}>
                  <div className="flex items-center gap-1">
                    <Bot className="h-3 w-3 text-purple-600" />
                    <span className="flex items-center gap-1">
                      NGD Status
                      <span className="px-1.5 py-0.5 bg-purple-200 text-purple-700 rounded text-[10px] font-bold">AI</span>
                    </span>
                    <SortIcon column="ngd_decile" />
                    <Tooltip content="AI Classification: New (0-10% decile), Grower (11-40%), Stable (41-70%), Decliner (71-100%)" />
                  </div>
                </th>
                <th className="px-2 py-2 text-left text-[11px] font-medium text-gray-500 uppercase border-b cursor-pointer hover:bg-gray-100" onClick={() => handleSort('call_success_score')}>
                  <div className="flex items-center">
                    Call Success
                    <SortIcon column="call_success_score" />
                    <Tooltip content="Likelihood of prescription after sales call (ML prediction 0-100%)" />
                  </div>
                </th>
                <th className="px-2 py-2 text-left text-[11px] font-medium text-gray-500 uppercase border-b bg-purple-50 cursor-pointer hover:bg-gray-100" onClick={() => handleSort('value_score')}>
                  <div className="flex items-center gap-1">
                    <Sparkles className="h-3 w-3 text-purple-600" />
                    <span className="flex items-center gap-1">
                      HCP Power Score
                      <span className="px-1.5 py-0.5 bg-purple-200 text-purple-700 rounded text-[10px] font-bold">AI</span>
                    </span>
                    <SortIcon column="value_score" />
                    <Tooltip content="AI Prediction: ML model call success probability × 100 (higher = better engagement likelihood)" />
                  </div>
                </th>
                <th className="px-1 py-2 text-center text-[11px] font-medium text-gray-500 uppercase border-b bg-purple-50 cursor-pointer hover:bg-gray-100 w-20" onClick={() => handleSort('priority')}>
                  <div className="flex items-center justify-center gap-0.5">
                    <Bot className="h-3 w-3 text-purple-600" />
                    <span className="flex items-center gap-0.5">
                      Pri
                      <span className="px-1 py-0.5 bg-purple-200 text-purple-700 rounded text-[10px] font-bold">AI</span>
                    </span>
                    <SortIcon column="priority" />
                    <Tooltip content="AI Ranking: 60% Call Success + 30% Rx Lift + 10% (Tier & NGD) mapped to 1-5" />
                  </div>
                </th>
                <th className="px-2 py-2 text-left text-[11px] font-medium text-gray-500 uppercase border-b cursor-pointer hover:bg-gray-100" onClick={() => handleSort('trx_current')}>
                  <div className="flex items-center">
                    Total TRx (Product Mix)
                    <SortIcon column="trx_current" />
                    <Tooltip content="Total prescriptions with IBSA + Competitor product breakdown" />
                  </div>
                </th>
                <th className="px-2 py-2 text-left text-[11px] font-medium text-gray-500 uppercase border-b cursor-pointer hover:bg-gray-100" onClick={() => handleSort('ibsa_nrx_qtd')}>
                  <div className="flex items-center">
                    Total NRx (Product Mix)
                    <SortIcon column="ibsa_nrx_qtd" />
                    <Tooltip content="New prescriptions with IBSA + Competitor product breakdown" />
                  </div>
                </th>
                <th className="px-1 py-2 text-right text-[11px] font-medium text-gray-500 uppercase border-b bg-purple-50 cursor-pointer hover:bg-gray-100" onClick={() => handleSort('forecasted_lift')}>
                  <div className="flex items-center justify-end gap-0.5">
                    <Bot className="h-3 w-3 text-purple-600" />
                    <span className="flex items-center gap-0.5 text-[10px]">
                      Rx Lift
                      <span className="px-1 py-0.5 bg-purple-200 text-purple-700 rounded text-[9px] font-bold">AI</span>
                    </span>
                    <SortIcon column="forecasted_lift" />
                    <Tooltip content="ML Predicted TRx lift from successful engagement" />
                  </div>
                </th>
                <th className="px-1 py-2 text-right text-[11px] font-medium text-gray-500 uppercase border-b bg-purple-50 cursor-pointer hover:bg-gray-100" onClick={() => handleSort('expected_roi')}>
                  <div className="flex items-center justify-end gap-0.5">
                    <Sparkles className="h-3 w-3 text-purple-600" />
                    <span className="flex items-center gap-0.5 text-[10px]">
                      ROI
                      <span className="px-1 py-0.5 bg-purple-200 text-purple-700 rounded text-[9px] font-bold">AI</span>
                    </span>
                    <SortIcon column="expected_roi" />
                    <Tooltip content="ML Predicted return on investment score" />
                  </div>
                </th>
                <th className="px-2 py-2 text-left text-[11px] font-medium text-gray-500 uppercase border-b cursor-pointer hover:bg-gray-100" onClick={() => handleSort('tier')}>
                  <div className="flex items-center">
                    Tier
                    <SortIcon column="tier" />
                    <Tooltip content="Original tier value from data source" />
                  </div>
                </th>
                <th className="px-2 py-2 text-center text-[11px] font-medium text-gray-500 uppercase border-b">
                  <Tooltip content="Note: NGD Status showing 'New' for all records - phase7 classification needs recalibration" />
                </th>
              </tr>
            </thead>
            <tbody className="bg-white dark:bg-gray-900">
              {filteredData.slice(currentPage * pageSize, (currentPage + 1) * pageSize).map((hcp, index) => {
                const colors = {
                  New: 'bg-blue-100 text-blue-800 border-blue-300',
                  Grower: 'bg-green-100 text-green-800 border-green-300',
                  Stable: 'bg-gray-100 text-gray-800 border-gray-300',
                  Decliner: 'bg-red-100 text-red-800 border-red-300',
                }
                const powerScore = Math.round(hcp.value_score || 0) // From expected_roi (ML model output)
                const callSuccess = Math.round((hcp.call_success_score || 0) * 100) // Convert 0-1 to 0-100%
                
                return (
                  <tr 
                    key={`${hcp.npi}-${index}`} 
                    className="border-b hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer"
                    onClick={() => router.push(`/hcp/${hcp.npi}`)}
                  >
                    <td className="px-2 py-2 text-xs font-mono">{hcp.npi}</td>
                    <td className="px-2 py-2 text-xs font-semibold">{hcp.name}</td>
                    <td className="px-2 py-2 text-xs">
                      <Tooltip content={hcp.specialty}>
                        <span className="block max-w-[150px] truncate">
                          {hcp.specialty}
                        </span>
                      </Tooltip>
                    </td>
                    <td className="px-2 py-2 text-xs">{hcp.territory}</td>
                    <td className="px-2 py-2 bg-purple-50 border-l-2 border-r-2 border-purple-300">
                      <div className="flex items-center gap-1">
                        <Bot className="h-3 w-3 text-purple-600 flex-shrink-0" />
                        <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium border ${colors[hcp.ngd_classification as keyof typeof colors]}`}>
                          {hcp.ngd_classification}
                        </span>
                      </div>
                    </td>
                    <td className="px-2 py-2">
                      <div className="w-16">
                        <div className="w-full bg-gray-200 rounded-full h-1.5">
                          <div
                            className={`h-1.5 rounded-full ${
                              callSuccess >= 70 ? 'bg-green-500' :
                              callSuccess >= 40 ? 'bg-blue-500' :
                              'bg-gray-400'
                            }`}
                            style={{ width: `${callSuccess}%` }}
                          />
                        </div>
                        <span className="text-[10px] text-muted-foreground">{callSuccess}%</span>
                      </div>
                    </td>
                    <td className="px-2 py-2 text-center bg-purple-50 border-l-2 border-r-2 border-purple-300">
                      <div className="flex items-center justify-center gap-1">
                        <Sparkles className="h-3 w-3 text-purple-600 flex-shrink-0" />
                        <span className={`inline-flex items-center justify-center w-9 h-9 rounded-full text-xs font-bold ${
                          powerScore >= 75 ? 'bg-green-100 text-green-700' :
                          powerScore >= 50 ? 'bg-blue-100 text-blue-700' :
                          powerScore >= 25 ? 'bg-yellow-100 text-yellow-700' :
                          'bg-red-100 text-red-700'
                        }`}>
                          {powerScore}
                        </span>
                      </div>
                    </td>
                    <td className="px-1 py-2 text-center bg-purple-50 border-l-2 border-r-2 border-purple-300">
                      <div className="flex items-center justify-center">
                        <span className={`inline-flex items-center justify-center w-6 h-6 rounded-full text-xs font-bold ${
                          hcp.priority <= 1 ? 'bg-red-100 text-red-700' :
                          hcp.priority <= 3 ? 'bg-orange-100 text-orange-700' :
                          'bg-blue-100 text-blue-700'
                        }`}>
                          {hcp.priority}
                        </span>
                      </div>
                    </td>
                    <td className="px-3 py-3 text-xs min-w-[160px]">
                      <div className="flex flex-col gap-1">
                        {(() => {
                          const totalTrx = (hcp.tirosint_trx || 0) + (hcp.flector_trx || 0) + (hcp.licart_trx || 0) + ((hcp as any).competitor_trx || 0)
                          return <div className="font-bold text-gray-900 text-[15px] mb-1">{formatNumber(totalTrx)} TRx</div>
                        })()}
                        {hcp.trx_current > 0 && (
                          <div className="space-y-1.5">
                            {/* IBSA Products */}
                            {((hcp.tirosint_trx || 0) + (hcp.flector_trx || 0) + (hcp.licart_trx || 0)) > 0 && (
                              <div className="bg-blue-50 rounded px-2 py-1 border-l-2 border-blue-500">
                                <div className="font-semibold text-blue-700 text-[11px] mb-0.5">IBSA:</div>
                                <div className="text-[11px] text-gray-700 space-y-0.5">
                                  {(hcp.tirosint_trx || 0) > 0 && (
                                    <div className="flex justify-between">
                                      <span className="text-gray-600">Tirosint:</span>
                                      <span className="font-medium">{formatNumber(hcp.tirosint_trx || 0)}</span>
                                    </div>
                                  )}
                                  {(hcp.flector_trx || 0) > 0 && (
                                    <div className="flex justify-between">
                                      <span className="text-gray-600">Flector:</span>
                                      <span className="font-medium">{formatNumber(hcp.flector_trx || 0)}</span>
                                    </div>
                                  )}
                                  {(hcp.licart_trx || 0) > 0 && (
                                    <div className="flex justify-between">
                                      <span className="text-gray-600">Licart:</span>
                                      <span className="font-medium">{formatNumber(hcp.licart_trx || 0)}</span>
                                    </div>
                                  )}
                                </div>
                              </div>
                            )}
                            
                            {/* Competitor Products */}
                            {((hcp as any).competitor_trx || 0) > 0 && (
                              <div className="bg-orange-50 rounded px-2 py-1 border-l-2 border-orange-500">
                                <div className="font-semibold text-orange-700 text-[11px] mb-0.5">Competitor:</div>
                                <div className="text-[11px] text-gray-700 space-y-0.5">
                                  {((hcp as any).competitor_synthroid_levothyroxine || 0) > 0 && (
                                    <div className="flex justify-between">
                                      <span className="text-gray-600">Synthroid:</span>
                                      <span className="font-medium">{formatNumber((hcp as any).competitor_synthroid_levothyroxine || 0)}</span>
                                    </div>
                                  )}
                                  {((hcp as any).competitor_voltaren_diclofenac || 0) > 0 && (
                                    <div className="flex justify-between">
                                      <span className="text-gray-600">Voltaren:</span>
                                      <span className="font-medium">{formatNumber((hcp as any).competitor_voltaren_diclofenac || 0)}</span>
                                    </div>
                                  )}
                                  {((hcp as any).competitor_imdur_nitrates || 0) > 0 && (
                                    <div className="flex justify-between">
                                      <span className="text-gray-600">Imdur:</span>
                                      <span className="font-medium">{formatNumber((hcp as any).competitor_imdur_nitrates || 0)}</span>
                                    </div>
                                  )}
                                </div>
                              </div>
                            )}
                          </div>
                        )}
                      </div>
                    </td>
                    
                    {/* NRx Column */}
                    <td className="px-3 py-3 text-xs min-w-[160px]">
                      <div className="flex flex-col gap-1">
                        <div className="font-bold text-gray-900 text-[15px] mb-1">
                          {formatNumber(((hcp as any).ibsa_nrx_qtd || 0) + ((hcp as any).competitor_nrx || 0))} NRx
                        </div>
                        {(((hcp as any).ibsa_nrx_qtd || 0) + ((hcp as any).competitor_nrx || 0)) > 0 && (
                          <div className="space-y-1.5">
                            {/* IBSA NRx */}
                            {((hcp as any).ibsa_nrx_qtd || 0) > 0 && (
                              <div className="bg-blue-50 rounded px-2 py-1 border-l-2 border-blue-500">
                                <div className="font-semibold text-blue-700 text-[11px] mb-0.5">IBSA:</div>
                                <div className="text-[11px] text-gray-700">
                                  <div className="flex justify-between">
                                    <span className="text-gray-600">Total:</span>
                                    <span className="font-medium">{formatNumber((hcp as any).ibsa_nrx_qtd || 0)}</span>
                                  </div>
                                </div>
                              </div>
                            )}
                            
                            {/* Competitor NRx */}
                            {((hcp as any).competitor_nrx || 0) > 0 && (
                              <div className="bg-orange-50 rounded px-2 py-1 border-l-2 border-orange-500">
                                <div className="font-semibold text-orange-700 text-[11px] mb-0.5">Competitor:</div>
                                <div className="text-[11px] text-gray-700 space-y-0.5">
                                  {((hcp as any).competitor_nrx_synthroid_levothyroxine || 0) > 0 && (
                                    <div className="flex justify-between">
                                      <span className="text-gray-600">Synthroid:</span>
                                      <span className="font-medium">{formatNumber((hcp as any).competitor_nrx_synthroid_levothyroxine || 0)}</span>
                                    </div>
                                  )}
                                  {((hcp as any).competitor_nrx_voltaren_diclofenac || 0) > 0 && (
                                    <div className="flex justify-between">
                                      <span className="text-gray-600">Voltaren:</span>
                                      <span className="font-medium">{formatNumber((hcp as any).competitor_nrx_voltaren_diclofenac || 0)}</span>
                                    </div>
                                  )}
                                  {((hcp as any).competitor_nrx_imdur_nitrates || 0) > 0 && (
                                    <div className="flex justify-between">
                                      <span className="text-gray-600">Imdur:</span>
                                      <span className="font-medium">{formatNumber((hcp as any).competitor_nrx_imdur_nitrates || 0)}</span>
                                    </div>
                                  )}
                                </div>
                              </div>
                            )}
                          </div>
                        )}
                      </div>
                    </td>
                    
                    <td className="px-1 py-2 text-right text-xs font-mono bg-purple-50">
                      <span className={`font-semibold text-[11px] ${hcp.trx_growth > 0 ? 'text-green-600' : hcp.trx_growth < -0.01 ? 'text-red-600' : 'text-gray-400'}`}>
                        {hcp.trx_growth > 0.01 ? '+' + hcp.trx_growth.toFixed(1) : hcp.trx_growth < -0.01 ? hcp.trx_growth.toFixed(1) : '—'}
                      </span>
                    </td>
                    <td className="px-1 py-2 text-right text-xs font-mono bg-purple-50">
                      <span className={`font-semibold text-[11px] ${hcp.value_score >= 50 ? 'text-green-600' : hcp.value_score >= 25 ? 'text-blue-600' : hcp.value_score > 0.1 ? 'text-gray-600' : 'text-gray-400'}`}>
                        {hcp.value_score > 0.1 ? hcp.value_score.toFixed(0) : '—'}
                      </span>
                    </td>
                    <td className="px-2 py-2 text-xs font-medium text-gray-700">
                      {hcp.tier}
                    </td>
                  </tr>
                )
              })}
              {filteredData.length === 0 && (
                <tr>
                  <td colSpan={16} className="px-4 py-8 text-center text-muted-foreground">
                    No HCPs found matching your filters
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="flex items-center justify-between px-4 py-4 border-t bg-gray-50 dark:bg-gray-800/50">
          <div className="text-sm text-muted-foreground">
            Showing <span className="font-medium">{currentPage * pageSize + 1}</span> to{' '}
            <span className="font-medium">{Math.min((currentPage + 1) * pageSize, filteredData.length)}</span>{' '}
            of <span className="font-medium">{filteredData.length}</span> HCPs
          </div>
          
          <div className="flex items-center gap-2">
            <span className="text-sm text-muted-foreground">Rows per page:</span>
            <select
              value={pageSize}
              onChange={(e) => {
                setPageSize(Number(e.target.value))
                setCurrentPage(0)
              }}
              className="px-2 py-1 text-sm border rounded-md bg-white dark:bg-gray-900"
            >
              <option value={10}>10</option>
              <option value={25}>25</option>
              <option value={50}>50</option>
            </select>
          </div>
          
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage(0)}
              disabled={currentPage === 0}
            >
              {'<<'}
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage(currentPage - 1)}
              disabled={currentPage === 0}
            >
              Previous
            </Button>
            <span className="text-sm font-medium px-4 py-2 bg-white dark:bg-gray-900 border rounded-md">
              Page {currentPage + 1} of {Math.ceil(filteredData.length / pageSize)}
            </span>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage(currentPage + 1)}
              disabled={(currentPage + 1) * pageSize >= filteredData.length}
            >
              Next
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage(Math.ceil(filteredData.length / pageSize) - 1)}
              disabled={(currentPage + 1) * pageSize >= filteredData.length}
            >
              {'>>'}
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}
