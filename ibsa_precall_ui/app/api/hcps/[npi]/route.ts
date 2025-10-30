import { NextRequest, NextResponse } from 'next/server'
import { getDataCached, findByNpi } from '@/lib/server/data-cache'

export async function GET(request: NextRequest, { params }: { params: Promise<{ npi: string }> }) {
  try {
    const data = await getDataCached()
    const { npi } = await params
    const hcp = findByNpi(data as any, npi)
    
    if (!hcp) {
      return NextResponse.json({ error: 'HCP not found' }, { status: 404 })
    }
    
    const res = NextResponse.json(hcp)
    res.headers.set('Cache-Control', 'public, s-maxage=3600, stale-while-revalidate=300')
    return res
  } catch (error) {
    return NextResponse.json({ error: String(error) }, { status: 500 })
  }
}
