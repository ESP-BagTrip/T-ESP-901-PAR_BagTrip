import { describe, it, expect, vi, beforeEach } from 'vitest'
import { apiClient } from '@/lib/axios'

describe('apiClient', () => {
  it('has the correct default baseURL', () => {
    expect(apiClient.defaults.baseURL).toBe('http://localhost:3000')
  })

  it('has withCredentials set to true', () => {
    expect(apiClient.defaults.withCredentials).toBe(true)
  })

  it('has Content-Type header set to application/json', () => {
    expect(apiClient.defaults.headers['Content-Type']).toBe('application/json')
  })

  it('has a response interceptor registered', () => {
    // Axios stores interceptors internally; we check there is at least one
    const interceptors = (apiClient.interceptors.response as unknown as { handlers: unknown[] })
      .handlers
    expect(interceptors.length).toBeGreaterThanOrEqual(1)
  })

  describe('401 interceptor', () => {
    let errorHandler: (error: unknown) => Promise<unknown>

    beforeEach(() => {
      // Extract the error handler from the registered interceptor
      const handlers = (
        apiClient.interceptors.response as unknown as {
          handlers: Array<{ rejected: (error: unknown) => Promise<unknown> }>
        }
      ).handlers
      errorHandler = handlers[0].rejected
    })

    it('redirects to /login on 401 error', async () => {
      const originalLocation = window.location
      Object.defineProperty(window, 'location', {
        writable: true,
        value: { href: '' },
      })

      const error = { response: { status: 401 } }
      await expect(errorHandler(error)).rejects.toBe(error)
      expect(window.location.href).toBe('/login')

      Object.defineProperty(window, 'location', {
        writable: true,
        value: originalLocation,
      })
    })

    it('does not redirect on non-401 errors', async () => {
      const originalHref = window.location.href
      const error = { response: { status: 500 } }
      await expect(errorHandler(error)).rejects.toBe(error)
      expect(window.location.href).toBe(originalHref)
    })

    it('does not redirect on errors without response', async () => {
      const originalHref = window.location.href
      const error = { message: 'Network error' }
      await expect(errorHandler(error)).rejects.toBe(error)
      expect(window.location.href).toBe(originalHref)
    })
  })

  describe('success interceptor', () => {
    it('passes through successful responses', () => {
      const handlers = (
        apiClient.interceptors.response as unknown as {
          handlers: Array<{ fulfilled: (response: unknown) => unknown }>
        }
      ).handlers
      const successHandler = handlers[0].fulfilled

      const response = { status: 200, data: 'ok' }
      expect(successHandler(response)).toBe(response)
    })
  })
})
