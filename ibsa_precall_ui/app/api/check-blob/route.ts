import { NextResponse } from 'next/server'

export async function GET() {
  const BLOB_URL = process.env.NEXT_PUBLIC_BLOB_URL || 'https://ibsangdpocdata.blob.core.windows.net/ngddatasets/IBSA_ModelReady_Enhanced.csv'
  try {
    const res = await fetch(BLOB_URL, { method: 'HEAD' })
    return NextResponse.json({ ok: res.ok, status: res.status, url: BLOB_URL })
  } catch (err) {
    return NextResponse.json({ ok: false, error: String(err), url: BLOB_URL }, { status: 500 })
  }
}
