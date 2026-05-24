/**
 * Next.js instrumentation hook — fires once at server startup. We register
 * Prometheus default process metrics (CPU, memory, GC, event loop lag, FDs)
 * so they are available on /api/metrics for Prometheus to scrape.
 *
 * Per-route RED metrics land in Phase 3 via OpenTelemetry, through this same
 * hook.
 */
export async function register(): Promise<void> {
  // The hook fires both for the Node.js runtime and the Edge runtime; the
  // prom-client library only works in Node.js. We accept anything that's not
  // explicitly 'edge' so that builds where NEXT_RUNTIME isn't surfaced still
  // wire up the metrics.
  if (process.env.NEXT_RUNTIME === 'edge') {
    return
  }

  const promClient = await import('prom-client')
  const registry = promClient.register

  // Idempotent: re-registering the same metric throws, so we guard against
  // module reloads (HMR in dev, double-invocation in standalone bundles).
  if (registry.getSingleMetric('process_cpu_user_seconds_total') === undefined) {
    promClient.collectDefaultMetrics({ register: registry })
  }
}
