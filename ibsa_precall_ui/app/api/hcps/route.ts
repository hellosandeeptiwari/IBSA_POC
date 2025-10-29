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
