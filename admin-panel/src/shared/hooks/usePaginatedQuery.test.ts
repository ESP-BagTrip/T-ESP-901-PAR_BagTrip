import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook } from '@testing-library/react'
import { useQuery } from '@tanstack/react-query'

const mockReplace = vi.fn()

vi.mock('next/navigation', () => ({
  useRouter: () => ({ replace: mockReplace }),
  usePathname: () => '/test',
  useSearchParams: () => new URLSearchParams(),
}))

vi.mock('@/utils/constants', () => ({
  PAGINATION_DEFAULTS: { PAGE: 1, LIMIT: 10 },
}))

let capturedQueryOpts: Record<string, unknown> = {}

vi.mock('@tanstack/react-query', () => ({
  useQuery: vi.fn((opts: Record<string, unknown>) => {
    capturedQueryOpts = opts
    return {
      data: undefined,
      isLoading: false,
      isError: false,
      error: null,
      refetch: vi.fn(),
    }
  }),
}))

const mockUseQuery = vi.mocked(useQuery)

import { usePaginatedQuery } from './usePaginatedQuery'

beforeEach(() => {
  vi.clearAllMocks()
  capturedQueryOpts = {}
  mockUseQuery.mockImplementation((opts: Record<string, unknown>) => {
    capturedQueryOpts = opts
    return {
      data: undefined,
      isLoading: false,
      isError: false,
      error: null,
      refetch: vi.fn(),
    } as ReturnType<typeof useQuery>
  })
})

function callHook(overrides: Partial<Parameters<typeof usePaginatedQuery>[0]> = {}) {
  const queryFn = vi.fn().mockResolvedValue({})
  const { result } = renderHook(() =>
    usePaginatedQuery({
      queryKey: ['test'],
      queryFn,
      ...overrides,
    })
  )
  return result.current
}

describe('usePaginatedQuery', () => {
  describe('default state', () => {
    it('returns empty rows and default pagination when data is undefined', () => {
      const result = callHook()
      expect(result.rows).toEqual([])
      expect(result.page).toBe(1)
      expect(result.limit).toBe(10)
      expect(result.total).toBe(0)
      expect(result.total_pages).toBe(0)
    })

    it('returns isLoading and isError from the underlying query', () => {
      const result = callHook()
      expect(result.isLoading).toBe(false)
      expect(result.isError).toBe(false)
      expect(result.error).toBeNull()
    })

    it('returns empty search by default', () => {
      const result = callHook()
      expect(result.search).toBe('')
    })
  })

  describe('normalize with PaginatedResponse shape', () => {
    it('extracts rows and pagination from { data, pagination } response', () => {
      mockUseQuery.mockImplementationOnce(
        () =>
          ({
            data: {
              data: [{ id: 1 }, { id: 2 }],
              pagination: { page: 2, limit: 5, total: 12, total_pages: 3 },
            },
            isLoading: false,
            isError: false,
            error: null,
            refetch: vi.fn(),
          }) as ReturnType<typeof useQuery>
      )

      const result = callHook()
      expect(result.rows).toEqual([{ id: 1 }, { id: 2 }])
      expect(result.page).toBe(2)
      expect(result.limit).toBe(5)
      expect(result.total).toBe(12)
      expect(result.total_pages).toBe(3)
    })
  })

  describe('normalize with AdminListResponse shape', () => {
    it('extracts rows from { items, page, limit, total, total_pages } response', () => {
      mockUseQuery.mockImplementationOnce(
        () =>
          ({
            data: {
              items: [{ id: 10 }, { id: 20 }],
              page: 3,
              limit: 15,
              total: 45,
              total_pages: 3,
            },
            isLoading: false,
            isError: false,
            error: null,
            refetch: vi.fn(),
          }) as ReturnType<typeof useQuery>
      )

      const result = callHook()
      expect(result.rows).toEqual([{ id: 10 }, { id: 20 }])
      expect(result.page).toBe(3)
      expect(result.limit).toBe(15)
      expect(result.total).toBe(45)
    })
  })

  describe('queryKey composition', () => {
    it('appends apiParams to the provided queryKey', () => {
      callHook({ queryKey: ['users'] })
      const key = capturedQueryOpts.queryKey as unknown[]
      expect(key[0]).toBe('users')
      expect(key[1]).toEqual({ page: 1, limit: 10 })
    })
  })

  describe('setPage', () => {
    it('is a function', () => {
      const result = callHook()
      expect(typeof result.setPage).toBe('function')
    })
  })

  describe('filters', () => {
    it('returns empty filters when no filterKeys provided', () => {
      const result = callHook()
      expect(result.filters).toEqual({})
    })

    it('returns undefined for declared filterKeys not in URL', () => {
      const result = callHook({ filterKeys: ['status', 'plan'] })
      expect(result.filters).toEqual({ status: undefined, plan: undefined })
    })
  })

  describe('defaultLimit', () => {
    it('uses provided defaultLimit instead of PAGINATION_DEFAULTS.LIMIT', () => {
      callHook({ defaultLimit: 25 })
      const key = capturedQueryOpts.queryKey as unknown[]
      expect((key[1] as Record<string, unknown>).limit).toBe(25)
    })
  })

  describe('resetFilters and setFilter', () => {
    it('exposes resetFilters as a function', () => {
      const result = callHook()
      expect(typeof result.resetFilters).toBe('function')
    })

    it('exposes setFilter as a function', () => {
      const result = callHook()
      expect(typeof result.setFilter).toBe('function')
    })
  })
})
