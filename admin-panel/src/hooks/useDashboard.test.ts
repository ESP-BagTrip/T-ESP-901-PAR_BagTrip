import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook } from '@testing-library/react'
import { useQuery } from '@tanstack/react-query'
import {
  useDashboardMetrics,
  useActivityLogs,
  useUserRegistrationsChart,
  useRevenueChart,
  useFeedbacksChart,
} from './useDashboard'

vi.mock('@tanstack/react-query', () => ({
  useQuery: vi.fn(() => ({
    data: undefined,
    isLoading: false,
    isError: false,
    error: null,
  })),
}))

vi.mock('@/services', () => ({
  dashboardService: {
    getMetrics: vi.fn(),
    getActivityLogs: vi.fn(),
    getUserRegistrationsChart: vi.fn(),
    getRevenueChart: vi.fn(),
    getFeedbacksChart: vi.fn(),
  },
}))

describe('useDashboard hooks', () => {
  beforeEach(() => {
    vi.mocked(useQuery).mockClear()
  })

  describe('useDashboardMetrics', () => {
    it('calls useQuery with correct queryKey and refetchInterval', () => {
      useDashboardMetrics()
      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['dashboard', 'metrics'],
          refetchInterval: 5 * 60 * 1000,
        })
      )
    })

    it('passes queryFn referencing dashboardService.getMetrics', () => {
      useDashboardMetrics()
      const opts = vi.mocked(useQuery).mock.calls[0][0]
      expect(opts.queryFn).toBeDefined()
    })

    it('returns data from useQuery via renderHook', () => {
      vi.mocked(useQuery).mockReturnValueOnce({
        data: { totalUsers: 100 },
        isLoading: false,
        isError: false,
        error: null,
      } as ReturnType<typeof useQuery>)

      const { result } = renderHook(() => useDashboardMetrics())
      expect(result.current.data).toEqual({ totalUsers: 100 })
    })
  })

  describe('useActivityLogs', () => {
    it('calls useQuery with queryKey including params', () => {
      const params = { page: 2, limit: 10 }
      useActivityLogs(params)
      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['dashboard', 'activity', params],
        })
      )
    })

    it('calls useQuery with undefined params when none provided', () => {
      useActivityLogs()
      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['dashboard', 'activity', undefined],
        })
      )
    })

    it('queryFn calls dashboardService.getActivityLogs with params', async () => {
      const { dashboardService } = await import('@/services')
      const params = { page: 1, limit: 5 }
      renderHook(() => useActivityLogs(params))
      const opts = vi.mocked(useQuery).mock.calls[0][0]
      opts.queryFn!({} as never)
      expect(dashboardService.getActivityLogs).toHaveBeenCalledWith(params)
    })
  })

  describe('useUserRegistrationsChart', () => {
    it('defaults to month period', () => {
      useUserRegistrationsChart()
      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['dashboard', 'users-chart', 'month'],
        })
      )
    })

    it('accepts week period', () => {
      useUserRegistrationsChart('week')
      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['dashboard', 'users-chart', 'week'],
        })
      )
    })

    it('accepts year period', () => {
      useUserRegistrationsChart('year')
      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['dashboard', 'users-chart', 'year'],
        })
      )
    })

    it('queryFn calls dashboardService.getUserRegistrationsChart with period', async () => {
      const { dashboardService } = await import('@/services')
      renderHook(() => useUserRegistrationsChart('week'))
      const opts = vi.mocked(useQuery).mock.calls[0][0]
      opts.queryFn!({} as never)
      expect(dashboardService.getUserRegistrationsChart).toHaveBeenCalledWith('week')
    })
  })

  describe('useRevenueChart', () => {
    it('defaults to month period', () => {
      useRevenueChart()
      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['dashboard', 'revenue-chart', 'month'],
        })
      )
    })

    it('accepts month period', () => {
      useRevenueChart('month')
      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['dashboard', 'revenue-chart', 'month'],
        })
      )
    })

    it('accepts year period', () => {
      useRevenueChart('year')
      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['dashboard', 'revenue-chart', 'year'],
        })
      )
    })

    it('queryFn calls dashboardService.getRevenueChart with period', async () => {
      const { dashboardService } = await import('@/services')
      renderHook(() => useRevenueChart('year'))
      const opts = vi.mocked(useQuery).mock.calls[0][0]
      opts.queryFn!({} as never)
      expect(dashboardService.getRevenueChart).toHaveBeenCalledWith('year')
    })
  })

  describe('useFeedbacksChart', () => {
    it('calls useQuery with correct queryKey', () => {
      useFeedbacksChart()
      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['dashboard', 'feedbacks-chart'],
        })
      )
    })

    it('passes queryFn referencing dashboardService.getFeedbacksChart', () => {
      useFeedbacksChart()
      const opts = vi.mocked(useQuery).mock.calls[0][0]
      expect(opts.queryFn).toBeDefined()
    })
  })
})
