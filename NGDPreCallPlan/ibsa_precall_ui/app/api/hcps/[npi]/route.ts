import { NextRequest, NextResponse } from 'next/server'
import { getDataCached, findByNpi } from '@/lib/server/data-cache'
import { getHCPDetailFromRow } from '@/lib/server/hcp-detail-server'

export async function GET(request: NextRequest, { params }: { params: Promise<{ npi: string }> }) {
  try {
    const data = await getDataCached()
    const { npi } = await params
    const row = findByNpi(data as any, npi)
    
    if (!row) {
      return NextResponse.json({ error: 'HCP not found' }, { status: 404 })
    }
    
    // Get full HCP detail with call history
    const hcp = await getHCPDetailFromRow(row, npi)
    
    const res = NextResponse.json(hcp)
    res.headers.set('Cache-Control', 'public, s-maxage=3600, stale-while-revalidate=300')
    return res
  } catch (error) {
    console.error('Error in HCP API route:', error)
    return NextResponse.json({ error: String(error) }, { status: 500 })
  }
}
