import { describe, it, expect, vi, beforeEach } from 'vitest'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'
import { adminService } from '@/services'

vi.mock('@/shared/hooks/usePaginatedQuery', () => ({
  usePaginatedQuery: vi.fn(() => ({ data: null, isLoading: false, page: 1, setPage: vi.fn() })),
}))

vi.mock('@/services', () => ({
  adminService: { getAllBookingIntents: vi.fn() },
}))

describe('useBookingIntentsTab', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should call usePaginatedQuery with correct queryKey', async () => {
    const { useBookingIntentsTab } = await import('@/features/booking-intents/hooks')
    useBookingIntentsTab({ enabled: true })

    expect(usePaginatedQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'booking-intents'],
        enabled: true,
      })
    )
  })

  it('should pass enabled=false correctly', async () => {
    const { useBookingIntentsTab } = await import('@/features/booking-intents/hooks')
    useBookingIntentsTab({ enabled: false })

    expect(usePaginatedQuery).toHaveBeenCalledWith(
      expect.objectContaining({ enabled: false })
    )
  })

  it('should use adminService.getAllBookingIntents as queryFn', async () => {
    const { useBookingIntentsTab } = await import('@/features/booking-intents/hooks')
    useBookingIntentsTab({ enabled: true })

    const call = vi.mocked(usePaginatedQuery).mock.calls[0][0]
    const params = { page: 1, limit: 10 }
    call.queryFn(params)

    expect(adminService.getAllBookingIntents).toHaveBeenCalledWith(params)
  })
})
