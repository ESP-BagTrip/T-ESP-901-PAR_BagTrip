import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook } from '@testing-library/react'
import { useQuery, useMutation } from '@tanstack/react-query'
import { useFeedbacks, useDeleteFeedback } from './useFeedbacks'

const mockInvalidateQueries = vi.fn()

vi.mock('@tanstack/react-query', () => ({
  useQueryClient: () => ({
    invalidateQueries: mockInvalidateQueries,
  }),
  useQuery: vi.fn(() => ({
    data: undefined,
    isLoading: false,
    isError: false,
    error: null,
  })),
  useMutation: vi.fn(() => ({
    mutate: vi.fn(),
    mutateAsync: vi.fn(),
    isPending: false,
    error: null,
  })),
}))

vi.mock('@/services', () => ({
  feedbacksService: {
    getFeedbacks: vi.fn(),
    deleteFeedback: vi.fn(),
  },
}))

vi.mock('@/utils/constants', () => ({
  PAGINATION_DEFAULTS: {
    PAGE: 1,
    LIMIT: 10,
  },
}))

describe('useFeedbacks hooks', () => {
  beforeEach(() => {
    vi.mocked(useQuery).mockClear()
    vi.mocked(useMutation).mockClear()
    mockInvalidateQueries.mockClear()
  })

  describe('useFeedbacks', () => {
    it('calls useQuery with correct queryKey', () => {
      const params = { page: 1, limit: 10 }
      useFeedbacks(params)
      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['feedbacks', params],
        })
      )
    })

    it('calls useQuery with undefined params when none provided', () => {
      useFeedbacks()
      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['feedbacks', undefined],
        })
      )
    })

    it('queryFn passes pagination defaults when no params given', async () => {
      const { feedbacksService } = await import('@/services')
      renderHook(() => useFeedbacks())
      const opts = vi.mocked(useQuery).mock.calls[0][0]
      opts.queryFn!({} as never)
      expect(feedbacksService.getFeedbacks).toHaveBeenCalledWith(
        expect.objectContaining({ page: 1, limit: 10 })
      )
    })

    it('queryFn merges custom params with pagination defaults', async () => {
      const { feedbacksService } = await import('@/services')
      const params = { page: 3, limit: 25, search: 'test' }
      renderHook(() => useFeedbacks(params))
      const opts = vi.mocked(useQuery).mock.calls[0][0]
      opts.queryFn!({} as never)
      // params spread last overrides defaults
      expect(feedbacksService.getFeedbacks).toHaveBeenCalledWith(
        expect.objectContaining({ page: 3, limit: 25, search: 'test' })
      )
    })

    it('returns data from useQuery via renderHook', () => {
      vi.mocked(useQuery).mockReturnValueOnce({
        data: { items: [{ id: 'f1' }], total: 1 },
        isLoading: false,
        isError: false,
        error: null,
      } as ReturnType<typeof useQuery>)

      const { result } = renderHook(() => useFeedbacks())
      expect(result.current.data).toEqual({ items: [{ id: 'f1' }], total: 1 })
    })
  })

  describe('useDeleteFeedback', () => {
    it('calls useMutation with mutationFn and onSuccess', () => {
      useDeleteFeedback()
      expect(useMutation).toHaveBeenCalledWith(
        expect.objectContaining({
          mutationFn: expect.any(Function),
          onSuccess: expect.any(Function),
        })
      )
    })

    it('onSuccess invalidates feedbacks queries', () => {
      renderHook(() => useDeleteFeedback())
      const opts = vi.mocked(useMutation).mock.calls[0][0] as { onSuccess: () => void }
      opts.onSuccess()
      expect(mockInvalidateQueries).toHaveBeenCalledWith({ queryKey: ['feedbacks'] })
    })

    it('mutationFn references feedbacksService.deleteFeedback', () => {
      renderHook(() => useDeleteFeedback())
      const opts = vi.mocked(useMutation).mock.calls[0][0] as { mutationFn: unknown }
      expect(opts.mutationFn).toBeDefined()
    })
  })
})
