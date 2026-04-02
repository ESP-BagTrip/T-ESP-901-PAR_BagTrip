import { describe, it, expect, vi, beforeEach } from 'vitest'
import { feedbacksService } from '@/services/feedbacks'
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

describe('feedbacksService', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should call GET /admin/feedbacks on getFeedbacks', async () => {
    const mockResponse = { items: [{ id: '1', rating: 5 }], total: 1 }
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockResponse })

    const result = await feedbacksService.getFeedbacks({ page: 1, limit: 10 })

    expect(apiClient.get).toHaveBeenCalledWith('/admin/feedbacks', {
      params: { page: 1, limit: 10 },
    })
    expect(result).toEqual(mockResponse)
  })

  it('should call GET /admin/feedbacks without params', async () => {
    const mockResponse = { items: [], total: 0 }
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockResponse })

    const result = await feedbacksService.getFeedbacks()

    expect(apiClient.get).toHaveBeenCalledWith('/admin/feedbacks', { params: undefined })
    expect(result).toEqual(mockResponse)
  })

  it('should call DELETE /admin/feedbacks/:id on deleteFeedback', async () => {
    vi.mocked(apiClient.delete).mockResolvedValue({ data: {} })

    await feedbacksService.deleteFeedback('feedback-1')

    expect(apiClient.delete).toHaveBeenCalledWith('/admin/feedbacks/feedback-1')
  })
})
