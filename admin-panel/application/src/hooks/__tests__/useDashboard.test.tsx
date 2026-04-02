import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { type ReactNode } from 'react'
import {
  useDashboardMetrics,
  useActivityLogs,
  useUserRegistrationsChart,
  useRevenueChart,
  useFeedbacksChart,
} from '../useDashboard'

const mockMetrics = { totalUsers: 100, totalTrips: 50, totalRevenue: 5000, totalFeedbacks: 20 }
const mockActivityLogs = { data: [], pagination: { page: 1, limit: 10, total: 0, total_pages: 0 } }
const mockChartData = [{ label: 'Jan', value: 10 }]

vi.mock('@/services', () => ({
  dashboardService: {
    getMetrics: vi.fn().mockResolvedValue({ totalUsers: 100, totalTrips: 50, totalRevenue: 5000, totalFeedbacks: 20 }),
    getActivityLogs: vi.fn().mockResolvedValue({ data: [], pagination: { page: 1, limit: 10, total: 0, total_pages: 0 } }),
    getUserRegistrationsChart: vi.fn().mockResolvedValue([{ label: 'Jan', value: 10 }]),
    getRevenueChart: vi.fn().mockResolvedValue([{ label: 'Jan', value: 10 }]),
    getFeedbacksChart: vi.fn().mockResolvedValue([{ label: 'Jan', value: 10 }]),
  },
}))

function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  })
  return ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

describe('useDashboard hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('useDashboardMetrics returns metrics data', async () => {
    const { result } = renderHook(() => useDashboardMetrics(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockMetrics)
  })

  it('useActivityLogs returns activity logs', async () => {
    const { result } = renderHook(() => useActivityLogs(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockActivityLogs)
  })

  it('useActivityLogs passes params', async () => {
    const { dashboardService } = await import('@/services')
    const params = { page: 2, limit: 5 }
    const { result } = renderHook(() => useActivityLogs(params), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(dashboardService.getActivityLogs).toHaveBeenCalledWith(params)
  })

  it('useUserRegistrationsChart returns chart data with default period', async () => {
    const { dashboardService } = await import('@/services')
    const { result } = renderHook(() => useUserRegistrationsChart(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockChartData)
    expect(dashboardService.getUserRegistrationsChart).toHaveBeenCalledWith('month')
  })

  it('useUserRegistrationsChart accepts custom period', async () => {
    const { dashboardService } = await import('@/services')
    const { result } = renderHook(() => useUserRegistrationsChart('week'), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(dashboardService.getUserRegistrationsChart).toHaveBeenCalledWith('week')
  })

  it('useRevenueChart returns chart data with default period', async () => {
    const { dashboardService } = await import('@/services')
    const { result } = renderHook(() => useRevenueChart(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockChartData)
    expect(dashboardService.getRevenueChart).toHaveBeenCalledWith('month')
  })

  it('useRevenueChart accepts custom period', async () => {
    const { dashboardService } = await import('@/services')
    const { result } = renderHook(() => useRevenueChart('year'), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(dashboardService.getRevenueChart).toHaveBeenCalledWith('year')
  })

  it('useFeedbacksChart returns chart data', async () => {
    const { result } = renderHook(() => useFeedbacksChart(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockChartData)
  })
})
