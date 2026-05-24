import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import { collectDefaultMetrics, register } from 'prom-client'
import { GET } from '../route'

describe('GET /api/metrics', () => {
  beforeAll(() => {
    if (register.getSingleMetric('process_cpu_user_seconds_total') === undefined) {
      collectDefaultMetrics({ register })
    }
  })

  afterAll(() => {
    register.clear()
  })

  it('returns 200 with Prometheus text exposition', async () => {
    const response = await GET()

    expect(response.status).toBe(200)
    expect(response.headers.get('content-type')).toMatch(/text\/plain/)
  })

  it('exposes default Node.js process metrics', async () => {
    const response = await GET()
    const body = await response.text()

    expect(body).toContain('process_cpu_user_seconds_total')
    expect(body).toContain('nodejs_eventloop_lag_seconds')
    expect(body).toContain('nodejs_heap_size_total_bytes')
  })

  it('forbids caching', async () => {
    const response = await GET()
    expect(response.headers.get('cache-control')).toBe('no-store')
  })
})
