import Papa from 'papaparse'
import type { ModelReadyRow } from '@/lib/api/data-loader'
import fs from 'fs'
import path from 'path'

// NO CACHE - Read fresh data each time to avoid memory buildup
// For large datasets (350K rows), streaming would be better but for now we optimize parsing

export async function getDataCached(): Promise<ModelReadyRow[]> {
  const BLOB_URL = process.env.NEXT_PUBLIC_BLOB_URL ||
    'https://ibsangdpocdata.blob.core.windows.net/ngddatasets/IBSA_ModelReady_Enhanced_WithPredictions.csv'

  let csvText: string

  // Check if using local file path (starts with /)
  if (BLOB_URL.startsWith('/')) {
    // Read from local file system
    const filePath = path.join(process.cwd(), 'public', BLOB_URL)
    console.log(`📂 [Server] Reading from local file: ${filePath}`)
    csvText = fs.readFileSync(filePath, 'utf-8')
  } else {
    // Fetch from remote URL
    console.log(`📥 [Server] Fetching from Azure Blob: ${BLOB_URL}`)
    const res = await fetch(BLOB_URL)
    if (!res.ok) {
      throw new Error(`Blob fetch failed with status: ${res.status}`)
    }
    csvText = await res.text()
  }

  // Parse with memory-efficient options
  const parsed = Papa.parse<ModelReadyRow>(csvText, {
    header: true,
    dynamicTyping: true,
    skipEmptyLines: true
  })

  return parsed.data
}

export function findByNpi(rows: ModelReadyRow[], npi: string): ModelReadyRow | undefined {
  return rows.find((r) => {
    // Handle both NPI and PrescriberId columns
    const prescriberId = String(r.NPI || r.PrescriberId || '').replace('.0', '')
    return prescriberId === npi || String(r.NPI) === npi || r.PrescriberId === (npi as any)
  })
}
