import { describe, it, expect, vi, beforeEach } from 'vitest'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'
import { adminService } from '@/services'

vi.mock('@/shared/hooks/usePaginatedQuery', () => ({
  usePaginatedQuery: vi.fn(() => ({ data: null, isLoading: false, page: 1, setPage: vi.fn() })),
}))

vi.mock('@/services', () => ({
  adminService: { getAllFlightBookings: vi.fn() },
}))

describe('useFlightsTab', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should call usePaginatedQuery with correct queryKey', async () => {
    const { useFlightsTab } = await import('@/features/flights/hooks')
    useFlightsTab({ enabled: true })

    expect(usePaginatedQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'flight-bookings'],
        enabled: true,
      })
    )
  })

  it('should pass enabled=false correctly', async () => {
    const { useFlightsTab } = await import('@/features/flights/hooks')
    useFlightsTab({ enabled: false })

    expect(usePaginatedQuery).toHaveBeenCalledWith(
      expect.objectContaining({ enabled: false })
    )
  })

  it('should use adminService.getAllFlightBookings as queryFn', async () => {
    const { useFlightsTab } = await import('@/features/flights/hooks')
    useFlightsTab({ enabled: true })

    const call = vi.mocked(usePaginatedQuery).mock.calls[0][0]
    const params = { page: 1, limit: 10 }
    call.queryFn(params)

    expect(adminService.getAllFlightBookings).toHaveBeenCalledWith(params)
  })
})
