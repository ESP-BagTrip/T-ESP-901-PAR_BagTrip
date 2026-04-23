import { describe, it, expect, vi, beforeEach } from 'vitest'
import { apiClient } from '@/lib/axios'
import { feedbacksService } from './feedbacks'

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
const mockDelete = vi.mocked(apiClient.delete)

beforeEach(() => {
  vi.clearAllMocks()
})

describe('feedbacksService', () => {
  describe('getFeedbacks', () => {
    it('should GET /admin/feedbacks with params and return response.data', async () => {
      const mockData = { items: [{ id: 'f1', message: 'Great app' }], total: 1 }
      mockGet.mockResolvedValue({ data: mockData })
      const params = { page: 1, limit: 10 }

      const result = await feedbacksService.getFeedbacks(params)

      expect(mockGet).toHaveBeenCalledWith('/admin/feedbacks', { params })
      expect(result).toEqual(mockData)
    })

    it('should call without params', async () => {
      mockGet.mockResolvedValue({ data: { items: [], total: 0 } })

      await feedbacksService.getFeedbacks()

      expect(mockGet).toHaveBeenCalledWith('/admin/feedbacks', { params: undefined })
    })
  })

  describe('deleteFeedback', () => {
    it('should DELETE /admin/feedbacks/{id}', async () => {
      mockDelete.mockResolvedValue({ data: {} })

      await feedbacksService.deleteFeedback('f1')

      expect(mockDelete).toHaveBeenCalledWith('/admin/feedbacks/f1')
    })
  })
})
