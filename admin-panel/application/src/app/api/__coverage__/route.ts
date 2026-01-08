import { NextResponse } from 'next/server'

declare global {
  // eslint-disable-next-line no-var
  var __coverage__: Record<string, unknown> | undefined
}

export async function GET() {
  if (process.env.CYPRESS_COVERAGE !== 'true') {
    return NextResponse.json({ error: 'Coverage not enabled' }, { status: 404 })
  }

  return NextResponse.json({
    coverage: global.__coverage__ || null,
  })
}
