import { describe, it, expect, vi, beforeEach } from 'vitest'
import { apiClient } from '@/lib/axios'
import { dashboardService } from './dashboard'

vi.mock('@/lib/axios', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}))

const mockGet = vi.mocked(apiClient.get)

beforeEach(() => {
  vi.clearAllMocks()
})

describe('dashboardService', () => {
  describe('getMetrics', () => {
    it('should GET /admin/dashboard/metrics and return response.data.data', async () => {
      const metrics = { totalUsers: 100, totalTrips: 50 }
      mockGet.mockResolvedValue({ data: { data: metrics } })

      const result = await dashboardService.getMetrics()

      expect(mockGet).toHaveBeenCalledWith('/admin/dashboard/metrics')
      expect(result).toEqual(metrics)
    })
  })

  describe('getActivityLogs', () => {
    it('should GET /admin/dashboard/activity with params and return response.data.data', async () => {
      const logs = { items: [{ id: 'log1' }], total: 1 }
      mockGet.mockResolvedValue({ data: { data: logs } })
      const params = { page: 1, limit: 20 }

      const result = await dashboardService.getActivityLogs(params)

      expect(mockGet).toHaveBeenCalledWith('/admin/dashboard/activity', { params })
      expect(result).toEqual(logs)
    })

    it('should call without params', async () => {
      mockGet.mockResolvedValue({ data: { data: { items: [] } } })

      await dashboardService.getActivityLogs()

      expect(mockGet).toHaveBeenCalledWith('/admin/dashboard/activity', { params: undefined })
    })
  })

  describe('getUserRegistrationsChart', () => {
    it('should GET metrics/users-chart with period param and return response.data.data', async () => {
      const chartData = [{ date: '2024-01', count: 10 }]
      mockGet.mockResolvedValue({ data: { data: chartData } })

      const result = await dashboardService.getUserRegistrationsChart('week')

      expect(mockGet).toHaveBeenCalledWith('/admin/dashboard/metrics/users-chart', {
        params: { period: 'week' },
      })
      expect(result).toEqual(chartData)
    })

    it('should default period to month', async () => {
      mockGet.mockResolvedValue({ data: { data: [] } })

      await dashboardService.getUserRegistrationsChart()

      expect(mockGet).toHaveBeenCalledWith('/admin/dashboard/metrics/users-chart', {
        params: { period: 'month' },
      })
    })
  })

  describe('getRevenueChart', () => {
    it('should GET metrics/revenue-chart with period and return response.data.data', async () => {
      const chartData = [{ date: '2024-01', revenue: 5000 }]
      mockGet.mockResolvedValue({ data: { data: chartData } })

      const result = await dashboardService.getRevenueChart('year')

      expect(mockGet).toHaveBeenCalledWith('/admin/dashboard/metrics/revenue-chart', {
        params: { period: 'year' },
      })
      expect(result).toEqual(chartData)
    })

    it('should default period to month', async () => {
      mockGet.mockResolvedValue({ data: { data: [] } })

      await dashboardService.getRevenueChart()

      expect(mockGet).toHaveBeenCalledWith('/admin/dashboard/metrics/revenue-chart', {
        params: { period: 'month' },
      })
    })
  })

  describe('getFeedbacksChart', () => {
    it('should GET metrics/feedbacks-chart and return response.data.data', async () => {
      const chartData = [{ date: '2024-01', count: 5 }]
      mockGet.mockResolvedValue({ data: { data: chartData } })

      const result = await dashboardService.getFeedbacksChart()

      expect(mockGet).toHaveBeenCalledWith('/admin/dashboard/metrics/feedbacks-chart')
      expect(result).toEqual(chartData)
    })
  })
})
