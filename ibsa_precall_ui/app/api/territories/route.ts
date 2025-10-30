import { NextRequest, NextResponse } from 'next/server'
import Papa from 'papaparse'
import fs from 'fs'
import path from 'path'

/**
 * Territory Analytics API
 * Returns pre-aggregated territory-level statistics for fast dashboard loading
 * Instead of loading 221K HCPs on client, we aggregate on server
 */
export async function GET(request: NextRequest) {
  try {
    const csvPath = path.join(process.cwd(), 'public', 'data', 'IBSA_ModelReady_Enhanced_WithPredictions.csv')
    
    if (!fs.existsSync(csvPath)) {
      return NextResponse.json({ error: 'CSV file not found' }, { status: 404 })
    }

    const fileContent = fs.readFileSync(csvPath, 'utf-8')
    
    // Parse CSV
    const { data } = Papa.parse(fileContent, {
      header: true,
      skipEmptyLines: true,
      dynamicTyping: true
    })

    // Aggregate by territory
    const territoryMap = new Map<string, any>()

    data.forEach((row: any) => {
      const territory = String(row.Territory || row.TerritoryName || row.State || 'Unknown')
      
      if (!territoryMap.has(territory)) {
        territoryMap.set(territory, {
          territory,
          hcpCount: 0,
          totalTRx: 0,
          totalPriorTRx: 0,
          totalIBSAShare: 0,
          highPriority: 0,
          newCount: 0,
          growerCount: 0,
          stableCount: 0,
          declinerCount: 0,
          platinumCount: 0,
          goldCount: 0,
          silverCount: 0,
          bronzeCount: 0,
          totalCallSuccess: 0,
          totalPowerScore: 0,
          // Product-specific
          tirosintTRx: 0,
          flectorTRx: 0,
          licartTRx: 0,
          // Competitor
          competitorTRx: 0,
          synthroidTRx: 0,
          voltarenTRx: 0,
          imdurTRx: 0,
          // NRx
          ibsaNRx: 0,
          competitorNRx: 0
        })
      }

      const territoryData = territoryMap.get(territory)!
      
      territoryData.hcpCount++
      territoryData.totalTRx += Number(row.TRx_Current || row.trx_current_qtd) || 0
      territoryData.totalPriorTRx += Number(row.trx_prior_qtd) || 0
      territoryData.totalIBSAShare += Number(row.ibsa_share) || 0
      
      // Priority and NGD
      if (Number(row.Priority) <= 2) territoryData.highPriority++
      
      const ngd = String(row.ngd_classification || 'Stable')
      if (ngd === 'New') territoryData.newCount++
      else if (ngd === 'Grower') territoryData.growerCount++
      else if (ngd === 'Stable') territoryData.stableCount++
      else if (ngd === 'Decliner') territoryData.declinerCount++
      
      // Tier
      const tier = String(row.Tier || 'N/A')
      if (tier === 'Platinum') territoryData.platinumCount++
      else if (tier === 'Gold') territoryData.goldCount++
      else if (tier === 'Silver') territoryData.silverCount++
      else if (tier === 'Bronze') territoryData.bronzeCount++
      
      // Scores
      territoryData.totalCallSuccess += Number(row.call_success_prob) || 0
      territoryData.totalPowerScore += Number(row.expected_roi) || 0
      
      // Products
      territoryData.tirosintTRx += Number(row.tirosint_trx) || 0
      territoryData.flectorTRx += Number(row.flector_trx) || 0
      territoryData.licartTRx += Number(row.licart_trx) || 0
      
      // Competitors
      territoryData.competitorTRx += Number(row.competitor_trx) || 0
      territoryData.synthroidTRx += Number(row.competitor_synthroid_levothyroxine) || 0
      territoryData.voltarenTRx += Number(row.competitor_voltaren_diclofenac) || 0
      territoryData.imdurTRx += Number(row.competitor_imdur_nitrates) || 0
      
      // NRx
      territoryData.ibsaNRx += Number(row.ibsa_nrx_qtd) || 0
      territoryData.competitorNRx += Number(row.competitor_nrx) || 0
    })

    // Calculate derived metrics
    const territories = Array.from(territoryMap.values()).map(t => {
      const ibsaTotalTRx = t.tirosintTRx + t.flectorTRx + t.licartTRx
      const totalMarketTRx = ibsaTotalTRx + t.competitorTRx
      
      return {
        ...t,
        avgMarketShare: t.hcpCount > 0 ? t.totalIBSAShare / t.hcpCount : 0,
        avgTRxPerHCP: t.hcpCount > 0 ? t.totalTRx / t.hcpCount : 0,
        growth: t.totalPriorTRx > 0 ? ((t.totalTRx - t.totalPriorTRx) / t.totalPriorTRx) * 100 : 0,
        newGrowers: t.newCount + t.growerCount,
        newGrowersPct: t.hcpCount > 0 ? ((t.newCount + t.growerCount) / t.hcpCount) * 100 : 0,
        avgCallSuccess: t.hcpCount > 0 ? (t.totalCallSuccess / t.hcpCount) * 100 : 0,
        avgPowerScore: t.hcpCount > 0 ? t.totalPowerScore / t.hcpCount : 0,
        ibsaTotalTRx,
        marketShare: totalMarketTRx > 0 ? (ibsaTotalTRx / totalMarketTRx) * 100 : 0
      }
    }).sort((a, b) => b.totalTRx - a.totalTRx)

    return NextResponse.json({
      territories,
      totalHCPs: data.length,
      totalTerritories: territories.length
    })

  } catch (error) {
    console.error('Error fetching territory analytics:', error)
    return NextResponse.json({ 
      error: 'Failed to load territory analytics',
      details: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 })
  }
}
