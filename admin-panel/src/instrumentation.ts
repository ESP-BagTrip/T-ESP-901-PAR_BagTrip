/**
 * Next.js instrumentation hook — registered automatically on server startup
 * (App Router 15+). We use it to wire up Prometheus default process metrics
 * (CPU, memory, GC, event loop lag, file descriptors) so they are available
 * on /api/metrics for Prometheus to scrape.
 *
 * Per-route RED metrics will land in Phase 3 via OpenTelemetry, which Next.js
 * supports natively through this same hook.
 */
export async function register(): Promise<void> {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    const { collectDefaultMetrics, register } = await import('prom-client')
    // Idempotent: re-registering the same metric throws, so we guard against
    // module reloads (HMR in dev).
    if (register.getSingleMetric('process_cpu_user_seconds_total') === undefined) {
      collectDefaultMetrics({ register })
    }
  }
}
