import { describe, it, expect, vi, beforeEach } from 'vitest'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'
import { feedbacksService } from '@/services'

vi.mock('@/shared/hooks/usePaginatedQuery', () => ({
  usePaginatedQuery: vi.fn(() => ({ data: null, isLoading: false, page: 1, setPage: vi.fn() })),
}))

vi.mock('@/services', () => ({
  feedbacksService: { getFeedbacks: vi.fn() },
}))

describe('useFeedbacksTab', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should call usePaginatedQuery with correct queryKey', async () => {
    const { useFeedbacksTab } = await import('@/features/feedbacks/hooks')
    useFeedbacksTab({ enabled: true })

    expect(usePaginatedQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['feedbacks'],
        enabled: true,
      })
    )
  })

  it('should pass enabled=false correctly', async () => {
    const { useFeedbacksTab } = await import('@/features/feedbacks/hooks')
    useFeedbacksTab({ enabled: false })

    expect(usePaginatedQuery).toHaveBeenCalledWith(
      expect.objectContaining({ enabled: false })
    )
  })

  it('should use feedbacksService.getFeedbacks as queryFn', async () => {
    const { useFeedbacksTab } = await import('@/features/feedbacks/hooks')
    useFeedbacksTab({ enabled: true })

    const call = vi.mocked(usePaginatedQuery).mock.calls[0][0]
    const params = { page: 1, limit: 10 }
    call.queryFn(params)

    expect(feedbacksService.getFeedbacks).toHaveBeenCalledWith(params)
  })
})
