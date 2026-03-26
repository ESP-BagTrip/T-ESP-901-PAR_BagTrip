import { feedbacksService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useFeedbacksTab({ enabled }: { enabled: boolean }) {
  return usePaginatedQuery({
    queryKey: ['feedbacks'],
    queryFn: (params) => feedbacksService.getFeedbacks(params),
    enabled,
  })
}
