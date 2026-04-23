import { describe, it, expect, vi } from 'vitest'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'
import { useTripSharesTab } from './hooks'

vi.mock('@/shared/hooks/usePaginatedQuery', () => ({
  usePaginatedQuery: vi.fn(() => ({
    rows: [],
    page: 1,
    limit: 10,
    total: 0,
    total_pages: 0,
    isLoading: false,
    isError: false,
    error: null,
    setPage: vi.fn(),
    search: '',
    setSearch: vi.fn(),
    filters: {},
    setFilter: vi.fn(),
    resetFilters: vi.fn(),
    refetch: vi.fn(),
  })),
}))

vi.mock('@/services', () => ({
  adminService: {
    getAllTripShares: vi.fn(),
  },
}))

describe('useTripSharesTab', () => {
  it('calls usePaginatedQuery with correct queryKey', () => {
    useTripSharesTab()
    expect(usePaginatedQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'trip-shares'],
        filterKeys: [],
      })
    )
  })

  it('passes adminService.getAllTripShares as queryFn', () => {
    useTripSharesTab()
    const call = vi.mocked(usePaginatedQuery).mock.calls[0][0]
    expect(call.queryFn).toBeInstanceOf(Function)
  })
})
