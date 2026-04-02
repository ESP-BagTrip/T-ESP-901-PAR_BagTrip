import { describe, it, expect, vi } from 'vitest'
import { queryClient } from '@/lib/query-client'
import { toast } from 'sonner'

describe('queryClient', () => {
  it('should have staleTime of 5 minutes', () => {
    const defaultOptions = queryClient.getDefaultOptions()
    expect(defaultOptions.queries?.staleTime).toBe(1000 * 60 * 5)
  })

  it('should have gcTime of 10 minutes', () => {
    const defaultOptions = queryClient.getDefaultOptions()
    expect(defaultOptions.queries?.gcTime).toBe(1000 * 60 * 10)
  })

  it('should call toast.error on mutation error', () => {
    const mutationCache = queryClient.getMutationCache()
    const config = mutationCache.config

    const error = { response: { data: { detail: 'Something went wrong' } } }
    config.onError?.(error, {} as never, {} as never, {} as never)

    expect(toast.error).toHaveBeenCalledWith('Something went wrong')
  })

  it('should use default error message when detail is not provided', () => {
    const mutationCache = queryClient.getMutationCache()
    const config = mutationCache.config

    config.onError?.({} as never, {} as never, {} as never, {} as never)

    expect(toast.error).toHaveBeenCalledWith('Une erreur est survenue')
  })

  describe('query retry function', () => {
    const getQueryRetry = () => {
      const defaultOptions = queryClient.getDefaultOptions()
      return defaultOptions.queries?.retry as (failureCount: number, error: unknown) => boolean
    }

    it('returns false for 401 errors', () => {
      const retry = getQueryRetry()
      const error = { response: { status: 401 } }
      expect(retry(0, error)).toBe(false)
    })

    it('returns false for 403 errors', () => {
      const retry = getQueryRetry()
      const error = { response: { status: 403 } }
      expect(retry(0, error)).toBe(false)
    })

    it('returns true for 500 errors when failureCount < 3', () => {
      const retry = getQueryRetry()
      const error = { response: { status: 500 } }
      expect(retry(0, error)).toBe(true)
      expect(retry(1, error)).toBe(true)
      expect(retry(2, error)).toBe(true)
    })

    it('returns false when failureCount >= 3', () => {
      const retry = getQueryRetry()
      const error = { response: { status: 500 } }
      expect(retry(3, error)).toBe(false)
    })

    it('returns true for errors without response when failureCount < 3', () => {
      const retry = getQueryRetry()
      expect(retry(0, new Error('Network error'))).toBe(true)
    })

    it('returns false for errors without response when failureCount >= 3', () => {
      const retry = getQueryRetry()
      expect(retry(3, new Error('Network error'))).toBe(false)
    })
  })

  describe('mutation retry function', () => {
    const getMutationRetry = () => {
      const defaultOptions = queryClient.getDefaultOptions()
      return defaultOptions.mutations?.retry as (failureCount: number, error: unknown) => boolean
    }

    it('returns false for 400 errors (4xx)', () => {
      const retry = getMutationRetry()
      const error = { response: { status: 400 } }
      expect(retry(0, error)).toBe(false)
    })

    it('returns false for 404 errors (4xx)', () => {
      const retry = getMutationRetry()
      const error = { response: { status: 404 } }
      expect(retry(0, error)).toBe(false)
    })

    it('returns false for 422 errors (4xx)', () => {
      const retry = getMutationRetry()
      const error = { response: { status: 422 } }
      expect(retry(0, error)).toBe(false)
    })

    it('returns true for 500 errors when failureCount < 3', () => {
      const retry = getMutationRetry()
      const error = { response: { status: 500 } }
      expect(retry(0, error)).toBe(true)
      expect(retry(2, error)).toBe(true)
    })

    it('returns false for 500 errors when failureCount >= 3', () => {
      const retry = getMutationRetry()
      const error = { response: { status: 500 } }
      expect(retry(3, error)).toBe(false)
    })

    it('returns true for errors without status when failureCount < 3', () => {
      const retry = getMutationRetry()
      expect(retry(0, new Error('Network error'))).toBe(true)
    })

    it('returns false for errors without status when failureCount >= 3', () => {
      const retry = getMutationRetry()
      expect(retry(3, new Error('Network error'))).toBe(false)
    })
  })
})
