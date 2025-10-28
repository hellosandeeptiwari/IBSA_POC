import { NextRequest, NextResponse } from 'next/server'
import Papa from 'papaparse'

let cachedData: any[] = []
let lastFetch = 0
const CACHE_TTL = 5 * 60 * 1000

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

export async function GET(request: NextRequest, { params }: { params: { npi: string } }) {
  try {
    const data = await loadData()
    const npi = params.npi
    
    const hcp = data.find((row: any) => {
      const prescriberId = String(row.PrescriberId).replace('.0', '')
      return prescriberId === npi || row.PrescriberId === npi
    })
    
    if (!hcp) {
      return NextResponse.json({ error: 'HCP not found' }, { status: 404 })
    }
    
    return NextResponse.json(hcp)
  } catch (error) {
    return NextResponse.json({ error: String(error) }, { status: 500 })
  }
}
