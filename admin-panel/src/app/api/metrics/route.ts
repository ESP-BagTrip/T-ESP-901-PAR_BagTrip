import { collectDefaultMetrics, register } from 'prom-client'

/**
 * Prometheus exposition endpoint.
 *
 * Public access is blocked at the inner Caddyfile; Prometheus scrapes the
 * container directly through the internal Docker network, so this endpoint
 * is only reachable from sibling services on the bagtrip stack.
 *
 * collectDefaultMetrics is initialised lazily on the first request rather
 * than from instrumentation.ts because the standalone Next.js build doesn't
 * always invoke the instrumentation hook before the first scrape (observed
 * in 16.2.4 with output: 'standalone'). The guard makes initialisation
 * idempotent across hot reloads and process restarts.
 */
export const dynamic = 'force-dynamic'
export const runtime = 'nodejs'

let metricsInitialised = false

function ensureMetricsInitialised(): void {
  if (metricsInitialised) return
  if (register.getSingleMetric('process_cpu_user_seconds_total') === undefined) {
    collectDefaultMetrics({ register })
  }
  metricsInitialised = true
}

export async function GET(): Promise<Response> {
  ensureMetricsInitialised()
  const body = await register.metrics()
  return new Response(body, {
    status: 200,
    headers: {
      'Content-Type': register.contentType,
      'Cache-Control': 'no-store',
    },
  })
}
