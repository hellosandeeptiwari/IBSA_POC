import { NextRequest, NextResponse } from 'next/server'
import { getDataCached } from '@/lib/server/data-cache'

export async function GET(request: NextRequest) {
  try {
    const data = await getDataCached()
    
    // Get query params for filtering
    const { searchParams } = new URL(request.url)
    const limit = parseInt(searchParams.get('limit') || '50')  // Reduced from 100 to 50
    const offset = parseInt(searchParams.get('offset') || '0')
    const search = searchParams.get('search')
    const territory = searchParams.get('territory')
    const random = searchParams.get('random') === 'true' // New parameter for random sampling
    
    let filtered = data
    
    if (search) {
      const searchLower = search.toLowerCase()
      filtered = filtered.filter((row: any) => 
        String(row.PrescriberName || '').toLowerCase().includes(searchLower) ||
        String(row.PrescriberId || '').includes(search)
      )
    }
    
    if (territory) {
      filtered = filtered.filter((row: any) => row.State === territory)
    }
    
    // If random sampling requested and no search term, return stratified random sample
    let paginated
    if (random && !search && offset === 0) {
      // Stratified sampling: ensure diverse representation across key dimensions
      const totalRecords = filtered.length
      const sampleSize = Math.min(limit, totalRecords)
      
      // Group by key dimensions for diversity
      const byTier: Record<string, any[]> = {}
      const byTerritory: Record<string, any[]> = {}
      const bySpecialty: Record<string, any[]> = {}
      const byNGD: Record<string, any[]> = {}
      
      filtered.forEach((row: any) => {
        const tier = row.Tier || 'Unknown'
        const territory = row.State || 'Unknown'
        const specialty = row.Specialty || 'Unknown'
        const ngd = row.ngd_classification || 'Unknown'
        
        if (!byTier[tier]) byTier[tier] = []
        if (!byTerritory[territory]) byTerritory[territory] = []
        if (!bySpecialty[specialty]) bySpecialty[specialty] = []
        if (!byNGD[ngd]) byNGD[ngd] = []
        
        byTier[tier].push(row)
        byTerritory[territory].push(row)
        bySpecialty[specialty].push(row)
        byNGD[ngd].push(row)
      })
      
      // Calculate samples per stratum - prioritize NGD diversity for balanced view
      const ngdCategories = Object.keys(byNGD)
      const samplesPerNGD = Math.floor(sampleSize / Math.max(ngdCategories.length, 1))
      
      const selectedRecords = new Set<any>()
      
      // First, sample from each NGD category to ensure balanced representation
      ngdCategories.forEach(ngd => {
        const ngdRecords = byNGD[ngd]
        const ngdSampleSize = Math.min(samplesPerNGD, ngdRecords.length)
        
        // Within each NGD category, sample diverse tiers
        const ngdByTier: Record<string, any[]> = {}
        ngdRecords.forEach((record: any) => {
          const tier = record.Tier || 'Unknown'
          if (!ngdByTier[tier]) ngdByTier[tier] = []
          ngdByTier[tier].push(record)
        })
        
        const tiersInNGD = Object.keys(ngdByTier)
        const samplesPerTierInNGD = Math.floor(ngdSampleSize / Math.max(tiersInNGD.length, 1))
        
        // Sample from each tier within this NGD category
        tiersInNGD.forEach(tier => {
          const records = ngdByTier[tier]
          const tierSampleSize = Math.min(samplesPerTierInNGD, records.length)
          const shuffled = [...records].sort(() => Math.random() - 0.5)
          shuffled.slice(0, tierSampleSize).forEach(record => selectedRecords.add(record))
        })
      })
      
      // Fill remaining slots with random records to reach sampleSize
      if (selectedRecords.size < sampleSize) {
        const remaining = sampleSize - selectedRecords.size
        const availableRecords = filtered.filter((r: any) => !selectedRecords.has(r))
        const shuffled = [...availableRecords].sort(() => Math.random() - 0.5)
        shuffled.slice(0, remaining).forEach(record => selectedRecords.add(record))
      }
      
      paginated = Array.from(selectedRecords)
    } else {
      // Normal pagination
      paginated = filtered.slice(offset, offset + limit)
    }
    
    const res = NextResponse.json({
      data: paginated,
      total: filtered.length,
      limit,
      offset,
      cached: true  // Indicate data is from cache
    })
    // Aggressive caching - 2 hours at edge, 10 minutes stale-while-revalidate
    res.headers.set('Cache-Control', 'public, s-maxage=7200, stale-while-revalidate=600')
    return res
  } catch (error) {
    return NextResponse.json({ error: String(error) }, { status: 500 })
  }
}
