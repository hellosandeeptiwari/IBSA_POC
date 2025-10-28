import { NextRequest, NextResponse } from 'next/server'
import Papa from 'papaparse'

let cachedData: any[] = []
let lastFetch = 0
const CACHE_TTL = 5 * 60 * 1000 // 5 minutes

async function loadData() {
  const now = Date.now()
  if (cachedData.length > 0 && now - lastFetch < CACHE_TTL) {
    return cachedData
  }

  const BLOB_URL = process.env.NEXT_PUBLIC_BLOB_URL || 'https://ibsangdpocdata.blob.core.windows.net/ngddatasets/IBSA_ModelReady_Enhanced.csv'
  const response = await fetch(BLOB_URL)
  const csvText = await response.text()
  
  const parsed = Papa.parse(csvText, {
    header: true,
    dynamicTyping: true,
    skipEmptyLines: true
  })

  cachedData = parsed.data
  lastFetch = now
  return cachedData
}

export async function GET(request: NextRequest) {
  try {
    const data = await loadData()
    
    // Get query params for filtering
    const { searchParams } = new URL(request.url)
    const limit = parseInt(searchParams.get('limit') || '100')
    const offset = parseInt(searchParams.get('offset') || '0')
    const search = searchParams.get('search')
    const territory = searchParams.get('territory')
    
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
    
    const paginated = filtered.slice(offset, offset + limit)
    
    return NextResponse.json({
      data: paginated,
      total: filtered.length,
      limit,
      offset
    })
  } catch (error) {
    return NextResponse.json({ error: String(error) }, { status: 500 })
  }
}
