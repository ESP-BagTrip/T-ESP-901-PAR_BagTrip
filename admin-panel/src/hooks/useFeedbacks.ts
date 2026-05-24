import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { feedbacksService } from '@/services'
import { PAGINATION_DEFAULTS } from '@/utils/constants'
import type { QueryParams } from '@/types'

export const useFeedbacks = (params?: QueryParams) => {
  return useQuery({
    queryKey: ['feedbacks', params],
    queryFn: () =>
      feedbacksService.getFeedbacks({
        page: params?.page || PAGINATION_DEFAULTS.PAGE,
        limit: params?.limit || PAGINATION_DEFAULTS.LIMIT,
        ...params,
      }),
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
