import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { feedbacksService } from '@/services'
import type { FeedbackFilters, QueryParams } from '@/types'

interface FeedbackQueryParams extends QueryParams {
  filters?: FeedbackFilters
}

const QUERY_KEYS = {
  feedbacks: (params?: FeedbackQueryParams) => ['feedbacks', params],
  feedback: (id: string) => ['feedbacks', id],
}

export const useFeedbacks = (params?: FeedbackQueryParams) => {
  return useQuery({
    queryKey: QUERY_KEYS.feedbacks(params),
    queryFn: () => feedbacksService.getFeedbacks(params),
  })
}

export const useFeedback = (id: string) => {
  return useQuery({
    queryKey: QUERY_KEYS.feedback(id),
    queryFn: () => feedbacksService.getFeedbackById(id),
    enabled: !!id,
  })
}

export const useUpdateFeedbackStatus = () => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ id, status }: { id: string; status: 'pending' | 'resolved' }) =>
      feedbacksService.updateFeedbackStatus(id, status),
    onSuccess: updatedFeedback => {
      queryClient.setQueryData(QUERY_KEYS.feedback(updatedFeedback.id), updatedFeedback)
      queryClient.invalidateQueries({ queryKey: ['feedbacks'] })
    },
  })
}

export const useDeleteFeedback = () => {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: feedbacksService.deleteFeedback,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['feedbacks'] })
    },
  })
}

export const useExportFeedbacks = () => {
  return useMutation({
    mutationFn: (params?: FeedbackQueryParams) => feedbacksService.exportFeedbacks(params),
    onSuccess: blob => {
      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = `feedbacks-export-${new Date().toISOString().split('T')[0]}.csv`
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      window.URL.revokeObjectURL(url)
    },
  })
}
