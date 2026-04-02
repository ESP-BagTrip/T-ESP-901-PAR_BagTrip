import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook, waitFor, act } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { type ReactNode } from 'react'
import { useFeedbacks, useDeleteFeedback } from '../useFeedbacks'

const mockFeedbacksResponse = { items: [], total: 0, page: 1, limit: 10, total_pages: 0 }

vi.mock('@/services', () => ({
  feedbacksService: {
    getFeedbacks: vi.fn().mockResolvedValue({ items: [], total: 0, page: 1, limit: 10, total_pages: 0 }),
    deleteFeedback: vi.fn().mockResolvedValue(undefined),
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

describe('useFeedbacks hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('useFeedbacks returns feedbacks data', async () => {
    const { result } = renderHook(() => useFeedbacks(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockFeedbacksResponse)
  })

  it('useFeedbacks passes params to service', async () => {
    const { feedbacksService } = await import('@/services')
    const params = { page: 2, limit: 20 }
    const { result } = renderHook(() => useFeedbacks(params), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(feedbacksService.getFeedbacks).toHaveBeenCalledWith(
      expect.objectContaining({ page: 2, limit: 20 })
    )
  })

  it('useDeleteFeedback calls deleteFeedback service', async () => {
    const { feedbacksService } = await import('@/services')

    const { result } = renderHook(() => useDeleteFeedback(), { wrapper: createWrapper() })

    act(() => {
      result.current.mutate('feedback-1')
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(feedbacksService.deleteFeedback).toHaveBeenCalledWith('feedback-1')
  })
})
