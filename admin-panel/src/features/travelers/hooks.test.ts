import { describe, it, expect, vi } from 'vitest'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'
import { useTravelersTab } from './hooks'

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
    getAllTravelers: vi.fn(),
  },
}))

describe('useTravelersTab', () => {
  it('calls usePaginatedQuery with correct queryKey', () => {
    useTravelersTab()
    expect(usePaginatedQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'travelers'],
        filterKeys: [],
      })
    )
  })
})
