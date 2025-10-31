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
        String(row.NPI || '').replace('.0', '').includes(search) ||
        String(row.Specialty || '').toLowerCase().includes(searchLower) ||
        String(row.Territory || row.State || '').toLowerCase().includes(searchLower)
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
      
      // Group by product mix categories for diversity (prioritize HCPs with NRx data)
      const onlyIBSA: any[] = []
      const onlyCompetitor: any[] = []
      const both: any[] = []
      const neither: any[] = []
      const withNRx: any[] = []
      
      filtered.forEach((row: any) => {
        const ibsaTrx = (Number(row.tirosint_trx) || 0) + (Number(row.flector_trx) || 0) + (Number(row.licart_trx) || 0)
        const compTrx = Number(row.competitor_trx) || 0
        const ibsaNrx = Number(row.ibsa_nrx_qtd) || 0
        const compNrx = Number(row.competitor_nrx) || 0
        
        // Track HCPs with NRx data separately
        if (ibsaNrx > 0 || compNrx > 0) {
          withNRx.push(row)
        }
        
        if (ibsaTrx > 0 && compTrx > 0) {
          both.push(row)
        } else if (ibsaTrx > 0 && compTrx === 0) {
          onlyIBSA.push(row)
        } else if (ibsaTrx === 0 && compTrx > 0) {
          onlyCompetitor.push(row)
        } else {
          neither.push(row)
        }
      })
      
      // Also group by key dimensions for diversity
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
      
      // Calculate samples per product mix category - ensure diversity + NRx representation
      const selectedRecords = new Set<any>()
      
      // Sample distribution: 30% with NRx, 30% both products, 20% only IBSA, 20% only competitor
      const nrxSample = Math.floor(sampleSize * 0.3)
      const bothSample = Math.floor(sampleSize * 0.3)
      const ibsaSample = Math.floor(sampleSize * 0.2)
      const compSample = Math.floor(sampleSize * 0.2)
      
      // First priority: Sample HCPs with NRx data
      const shuffledNRx = [...withNRx].sort(() => Math.random() - 0.5)
      shuffledNRx.slice(0, Math.min(nrxSample, withNRx.length)).forEach(record => selectedRecords.add(record))
      
      // Sample from HCPs with both IBSA and Competitor products
      const shuffledBoth = [...both].sort(() => Math.random() - 0.5)
      shuffledBoth.slice(0, Math.min(bothSample, both.length)).forEach(record => selectedRecords.add(record))
      
      // Sample from HCPs with only IBSA products
      const shuffledIBSA = [...onlyIBSA].sort(() => Math.random() - 0.5)
      shuffledIBSA.slice(0, Math.min(ibsaSample, onlyIBSA.length)).forEach(record => selectedRecords.add(record))
      
      // Sample from HCPs with only Competitor products
      const shuffledComp = [...onlyCompetitor].sort(() => Math.random() - 0.5)
      shuffledComp.slice(0, Math.min(compSample, onlyCompetitor.length)).forEach(record => selectedRecords.add(record))
      
      console.log(`📊 Product Mix Sampling: NRx=${withNRx.length} (selected ${Math.min(nrxSample, withNRx.length)}), Both=${both.length} (selected ${Math.min(bothSample, both.length)}), IBSA=${onlyIBSA.length} (selected ${Math.min(ibsaSample, onlyIBSA.length)}), Comp=${onlyCompetitor.length} (selected ${Math.min(compSample, onlyCompetitor.length)}), Neither=${neither.length}`)
      
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
