import { describe, it, expect, vi, beforeEach } from 'vitest'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'
import { adminService } from '@/services'

vi.mock('@/shared/hooks/usePaginatedQuery', () => ({
  usePaginatedQuery: vi.fn(() => ({ data: null, isLoading: false, page: 1, setPage: vi.fn() })),
}))

vi.mock('@/services', () => ({
  adminService: { getAllActivities: vi.fn() },
}))

describe('useActivitiesTab', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should call usePaginatedQuery with correct queryKey', async () => {
    const { useActivitiesTab } = await import('@/features/activities/hooks')
    useActivitiesTab({ enabled: true })

    expect(usePaginatedQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'activities'],
        enabled: true,
      })
    )
  })

  it('should pass enabled=false correctly', async () => {
    const { useActivitiesTab } = await import('@/features/activities/hooks')
    useActivitiesTab({ enabled: false })

    expect(usePaginatedQuery).toHaveBeenCalledWith(
      expect.objectContaining({ enabled: false })
    )
  })

  it('should use adminService.getAllActivities as queryFn', async () => {
    const { useActivitiesTab } = await import('@/features/activities/hooks')
    useActivitiesTab({ enabled: true })

    const call = vi.mocked(usePaginatedQuery).mock.calls[0][0]
    const params = { page: 1, limit: 10 }
    call.queryFn(params)

    expect(adminService.getAllActivities).toHaveBeenCalledWith(params)
  })
})
