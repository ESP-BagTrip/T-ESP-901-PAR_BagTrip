import { describe, it, expect, vi } from 'vitest'
import { useQuery } from '@tanstack/react-query'
import {
  useDashboardMetrics,
  useUserRegistrationsChart,
  useRevenueChart,
  useFeedbacksChart,
  useRecentActivity,
  useTripStatusDistribution,
} from './hooks'

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
    getUserRegistrationsChart: vi.fn(),
    getRevenueChart: vi.fn(),
    getFeedbacksChart: vi.fn(),
  },
  adminService: {
    getAllTrips: vi.fn(),
  },
}))

describe('dashboard hooks', () => {
  it('useDashboardMetrics uses correct queryKey', () => {
    useDashboardMetrics()
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['dashboard', 'metrics'],
        staleTime: 60_000,
      })
    )
  })

  it('useUserRegistrationsChart defaults to month', () => {
    vi.mocked(useQuery).mockClear()
    useUserRegistrationsChart()
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['dashboard', 'users-chart', 'month'],
      })
    )
  })

  it('useUserRegistrationsChart accepts week period', () => {
    vi.mocked(useQuery).mockClear()
    useUserRegistrationsChart('week')
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['dashboard', 'users-chart', 'week'],
      })
    )
  })

  it('useRevenueChart defaults to month', () => {
    vi.mocked(useQuery).mockClear()
    useRevenueChart()
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['dashboard', 'revenue-chart', 'month'],
      })
    )
  })

  it('useRevenueChart accepts year period', () => {
    vi.mocked(useQuery).mockClear()
    useRevenueChart('year')
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['dashboard', 'revenue-chart', 'year'],
      })
    )
  })

  it('useFeedbacksChart uses correct queryKey', () => {
    vi.mocked(useQuery).mockClear()
    useFeedbacksChart()
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['dashboard', 'feedbacks-chart'],
      })
    )
  })

  it('useRecentActivity uses correct queryKey', () => {
    vi.mocked(useQuery).mockClear()
    useRecentActivity()
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['dashboard', 'activity'],
      })
    )
  })

  it('useTripStatusDistribution uses correct queryKey', () => {
    vi.mocked(useQuery).mockClear()
    useTripStatusDistribution()
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['dashboard', 'trips-status-groupby'],
      })
    )
  })
})
