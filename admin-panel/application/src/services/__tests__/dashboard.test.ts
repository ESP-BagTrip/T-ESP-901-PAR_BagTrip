import { describe, it, expect, vi, beforeEach } from 'vitest'
import { dashboardService } from '@/services/dashboard'
import { apiClient } from '@/lib/axios'

vi.mock('@/lib/axios', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}))

describe('dashboardService', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should call GET /admin/dashboard/metrics on getMetrics', async () => {
    const mockMetrics = { totalUsers: 100, totalTrips: 50 }
    vi.mocked(apiClient.get).mockResolvedValue({ data: { data: mockMetrics } })

    const result = await dashboardService.getMetrics()

    expect(apiClient.get).toHaveBeenCalledWith('/admin/dashboard/metrics')
    expect(result).toEqual(mockMetrics)
  })

  it('should call GET /admin/dashboard/activity on getActivityLogs', async () => {
    const mockLogs = { data: [{ id: '1', action: 'login' }], pagination: { total: 1 } }
    vi.mocked(apiClient.get).mockResolvedValue({ data: { data: mockLogs } })

    const result = await dashboardService.getActivityLogs({ page: 1 })

    expect(apiClient.get).toHaveBeenCalledWith('/admin/dashboard/activity', {
      params: { page: 1 },
    })
    expect(result).toEqual(mockLogs)
  })

  it('should call GET /admin/dashboard/metrics/users-chart on getUserRegistrationsChart', async () => {
    const mockChart = [{ label: 'Jan', value: 10 }]
    vi.mocked(apiClient.get).mockResolvedValue({ data: { data: mockChart } })

    const result = await dashboardService.getUserRegistrationsChart('month')

    expect(apiClient.get).toHaveBeenCalledWith('/admin/dashboard/metrics/users-chart', {
      params: { period: 'month' },
    })
    expect(result).toEqual(mockChart)
  })

  it('should call GET /admin/dashboard/metrics/revenue-chart on getRevenueChart', async () => {
    const mockChart = [{ label: 'Jan', value: 5000 }]
    vi.mocked(apiClient.get).mockResolvedValue({ data: { data: mockChart } })

    const result = await dashboardService.getRevenueChart('week')

    expect(apiClient.get).toHaveBeenCalledWith('/admin/dashboard/metrics/revenue-chart', {
      params: { period: 'week' },
    })
    expect(result).toEqual(mockChart)
  })

  it('should call GET /admin/dashboard/metrics/feedbacks-chart on getFeedbacksChart', async () => {
    const mockChart = [{ label: 'Good', value: 80 }]
    vi.mocked(apiClient.get).mockResolvedValue({ data: { data: mockChart } })

    const result = await dashboardService.getFeedbacksChart()

    expect(apiClient.get).toHaveBeenCalledWith('/admin/dashboard/metrics/feedbacks-chart')
    expect(result).toEqual(mockChart)
  })
})
