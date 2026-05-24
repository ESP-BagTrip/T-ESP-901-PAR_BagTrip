import { describe, it, expect, vi } from 'vitest'
import { QueryClient } from '@tanstack/react-query'

vi.mock('sonner', () => ({
  toast: {
    error: vi.fn(),
  },
}))

import { queryClient } from '@/lib/query-client'
import { toast } from 'sonner'

describe('queryClient', () => {
  it('is an instance of QueryClient', () => {
    expect(queryClient).toBeInstanceOf(QueryClient)
  })

  describe('queries defaults', () => {
    const defaults = queryClient.getDefaultOptions()

    it('has staleTime of 5 minutes', () => {
      expect(defaults.queries?.staleTime).toBe(1000 * 60 * 5)
    })

    it('has gcTime of 10 minutes', () => {
      expect(defaults.queries?.gcTime).toBe(1000 * 60 * 10)
    })

    describe('retry logic', () => {
      const retry = defaults.queries?.retry as (failureCount: number, error: unknown) => boolean

      it('returns false for 401 errors', () => {
        expect(retry(0, { response: { status: 401 } })).toBe(false)
      })

      it('returns false for 403 errors', () => {
        expect(retry(0, { response: { status: 403 } })).toBe(false)
      })

      it('returns true when failureCount < 3 for other errors', () => {
        expect(retry(0, { response: { status: 500 } })).toBe(true)
        expect(retry(1, { response: { status: 500 } })).toBe(true)
        expect(retry(2, { response: { status: 500 } })).toBe(true)
      })

      it('returns false when failureCount >= 3', () => {
        expect(retry(3, { response: { status: 500 } })).toBe(false)
      })
    })
  })

  describe('mutations defaults', () => {
    const defaults = queryClient.getDefaultOptions()

    describe('retry logic', () => {
      const retry = defaults.mutations?.retry as (failureCount: number, error: unknown) => boolean

      it('returns false for 400 errors', () => {
        expect(retry(0, { response: { status: 400 } })).toBe(false)
      })

      it('returns false for 404 errors', () => {
        expect(retry(0, { response: { status: 404 } })).toBe(false)
      })

      it('returns false for 422 errors', () => {
        expect(retry(0, { response: { status: 422 } })).toBe(false)
      })

      it('returns false for 499 errors', () => {
        expect(retry(0, { response: { status: 499 } })).toBe(false)
      })

      it('returns true for 5xx errors when failureCount < 3', () => {
        expect(retry(0, { response: { status: 500 } })).toBe(true)
        expect(retry(2, { response: { status: 503 } })).toBe(true)
      })

      it('returns false when failureCount >= 3', () => {
        expect(retry(3, { response: { status: 500 } })).toBe(false)
      })
    })
  })

  describe('mutation cache error handler', () => {
    it('shows toast with error detail from response', () => {
      const cache = queryClient.getMutationCache()
      const config = cache.config

      config.onError?.(
        { response: { data: { detail: 'Custom error' } } } as unknown as Error,
        '' as unknown as never,
        '' as unknown as never,
        '' as unknown as never
      )

      expect(toast.error).toHaveBeenCalledWith('Custom error')
    })

    it('shows default toast when no detail present', () => {
      const cache = queryClient.getMutationCache()
      const config = cache.config

      config.onError?.(
        {} as unknown as Error,
        '' as unknown as never,
        '' as unknown as never,
        '' as unknown as never
      )

      expect(toast.error).toHaveBeenCalledWith('Une erreur est survenue')
    })
  })
})
