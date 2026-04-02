import { describe, it, expect, vi, beforeEach } from 'vitest'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'
import { adminService } from '@/services'

vi.mock('@/shared/hooks/usePaginatedQuery', () => ({
  usePaginatedQuery: vi.fn(() => ({ data: null, isLoading: false, page: 1, setPage: vi.fn() })),
}))

vi.mock('@/services', () => ({
  adminService: { getAllTripShares: vi.fn() },
}))

describe('useTripSharesTab', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should call usePaginatedQuery with correct queryKey', async () => {
    const { useTripSharesTab } = await import('@/features/trip-shares/hooks')
    useTripSharesTab({ enabled: true })

    expect(usePaginatedQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'trip-shares'],
        enabled: true,
      })
    )
  })

  it('should pass enabled=false correctly', async () => {
    const { useTripSharesTab } = await import('@/features/trip-shares/hooks')
    useTripSharesTab({ enabled: false })

    expect(usePaginatedQuery).toHaveBeenCalledWith(
      expect.objectContaining({ enabled: false })
    )
  })

  it('should use adminService.getAllTripShares as queryFn', async () => {
    const { useTripSharesTab } = await import('@/features/trip-shares/hooks')
    useTripSharesTab({ enabled: true })

    const call = vi.mocked(usePaginatedQuery).mock.calls[0][0]
    const params = { page: 1, limit: 10 }
    call.queryFn(params)

    expect(adminService.getAllTripShares).toHaveBeenCalledWith(params)
  })
})
