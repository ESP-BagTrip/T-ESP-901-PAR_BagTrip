import { describe, it, expect, vi, beforeEach } from 'vitest'
import { useQuery } from '@tanstack/react-query'
import { dashboardService } from '@/services'

vi.mock('@tanstack/react-query', () => ({
  useQuery: vi.fn(() => ({ data: null, isLoading: false, isError: false })),
}))

vi.mock('@/services', () => ({
  dashboardService: {
    getMetrics: vi.fn(),
    getUserRegistrationsChart: vi.fn(),
    getRevenueChart: vi.fn(),
    getFeedbacksChart: vi.fn(),
  },
}))

describe('dashboard hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('useDashboardMetrics', () => {
    it('should call useQuery with correct queryKey and enabled', async () => {
      const { useDashboardMetrics } = await import('@/features/dashboard/hooks')
      useDashboardMetrics({ enabled: true })

      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['dashboard', 'metrics'],
          enabled: true,
        })
      )
    })

    it('should use dashboardService.getMetrics as queryFn', async () => {
      const { useDashboardMetrics } = await import('@/features/dashboard/hooks')
      useDashboardMetrics({ enabled: true })

      const call = vi.mocked(useQuery).mock.calls[0][0]
      call.queryFn!({} as never)

      expect(dashboardService.getMetrics).toHaveBeenCalled()
    })
  })

  describe('useUserRegistrationsChart', () => {
    it('should call useQuery with correct queryKey including period', async () => {
      const { useUserRegistrationsChart } = await import('@/features/dashboard/hooks')
      useUserRegistrationsChart({ enabled: true, period: 'week' })

      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['dashboard', 'users-chart', 'week'],
          enabled: true,
        })
      )
    })

    it('should default period to month', async () => {
      const { useUserRegistrationsChart } = await import('@/features/dashboard/hooks')
      useUserRegistrationsChart({ enabled: true })

      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['dashboard', 'users-chart', 'month'],
        })
      )
    })

    it('should use dashboardService.getUserRegistrationsChart as queryFn', async () => {
      const { useUserRegistrationsChart } = await import('@/features/dashboard/hooks')
      useUserRegistrationsChart({ enabled: true, period: 'year' })

      const call = vi.mocked(useQuery).mock.calls[0][0]
      call.queryFn!({} as never)

      expect(dashboardService.getUserRegistrationsChart).toHaveBeenCalledWith('year')
    })
  })

  describe('useRevenueChart', () => {
    it('should call useQuery with correct queryKey including period', async () => {
      const { useRevenueChart } = await import('@/features/dashboard/hooks')
      useRevenueChart({ enabled: true, period: 'year' })

      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['dashboard', 'revenue-chart', 'year'],
          enabled: true,
        })
      )
    })

    it('should default period to month', async () => {
      const { useRevenueChart } = await import('@/features/dashboard/hooks')
      useRevenueChart({ enabled: true })

      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['dashboard', 'revenue-chart', 'month'],
        })
      )
    })

    it('should use dashboardService.getRevenueChart as queryFn', async () => {
      const { useRevenueChart } = await import('@/features/dashboard/hooks')
      useRevenueChart({ enabled: true, period: 'week' })

      const call = vi.mocked(useQuery).mock.calls[0][0]
      call.queryFn!({} as never)

      expect(dashboardService.getRevenueChart).toHaveBeenCalledWith('week')
    })
  })

  describe('useFeedbacksChart', () => {
    it('should call useQuery with correct queryKey', async () => {
      const { useFeedbacksChart } = await import('@/features/dashboard/hooks')
      useFeedbacksChart({ enabled: true })

      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['dashboard', 'feedbacks-chart'],
          enabled: true,
        })
      )
    })

    it('should use dashboardService.getFeedbacksChart as queryFn', async () => {
      const { useFeedbacksChart } = await import('@/features/dashboard/hooks')
      useFeedbacksChart({ enabled: true })

      const call = vi.mocked(useQuery).mock.calls[0][0]
      call.queryFn!({} as never)

      expect(dashboardService.getFeedbacksChart).toHaveBeenCalled()
    })
  })
})
