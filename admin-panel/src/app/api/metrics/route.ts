import { register } from 'prom-client'

/**
 * Prometheus exposition endpoint.
 *
 * Public access is blocked at the inner Caddyfile; Prometheus scrapes the
 * container directly through the internal Docker network, so this endpoint
 * is only reachable from sibling services on the bagtrip stack.
 */
export const dynamic = 'force-dynamic'
export const runtime = 'nodejs'

export async function GET(): Promise<Response> {
  const body = await register.metrics()
  return new Response(body, {
    status: 200,
    headers: {
      'Content-Type': register.contentType,
      'Cache-Control': 'no-store',
    },
  })
}
