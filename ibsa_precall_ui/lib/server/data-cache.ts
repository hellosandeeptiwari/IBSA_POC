import Papa from 'papaparse'
import type { ModelReadyRow } from '@/lib/api/data-loader'

// Use a global cache to ensure a single dataset is reused across API routes
// This survives module reloads within the same Node.js process
declare global {
  // eslint-disable-next-line no-var
  var __IBSA_DATA_CACHE__: {
    data: ModelReadyRow[] | null
    fetchedAt: number
    ttlMs: number
  } | undefined
}

const DEFAULT_TTL = 60 * 60 * 1000 // 1 hour

function getCache() {
  if (!global.__IBSA_DATA_CACHE__) {
    global.__IBSA_DATA_CACHE__ = { data: null, fetchedAt: 0, ttlMs: DEFAULT_TTL }
  }
  return global.__IBSA_DATA_CACHE__
}

export async function getDataCached(ttlMs: number = DEFAULT_TTL): Promise<ModelReadyRow[]> {
  const cache = getCache()
  const now = Date.now()
  const valid = cache.data && now - cache.fetchedAt < cache.ttlMs

  if (valid) return cache.data as ModelReadyRow[]

  const BLOB_URL = process.env.NEXT_PUBLIC_BLOB_URL ||
    'https://ibsangdpocdata.blob.core.windows.net/ngddatasets/IBSA_ModelReady_Enhanced.csv'

  const res = await fetch(BLOB_URL)
  if (!res.ok) {
    throw new Error(`Blob fetch failed with status: ${res.status}`)
  }
  const csvText = await res.text()

  const parsed = Papa.parse<ModelReadyRow>(csvText, {
    header: true,
    dynamicTyping: true,
    skipEmptyLines: true
  })

  cache.data = parsed.data
  cache.fetchedAt = now
  cache.ttlMs = ttlMs
  return cache.data
}

export function findByNpi(rows: ModelReadyRow[], npi: string): ModelReadyRow | undefined {
  return rows.find((r) => {
    const prescriberId = String(r.PrescriberId).replace('.0', '')
    return prescriberId === npi || r.PrescriberId === (npi as any)
  })
}
