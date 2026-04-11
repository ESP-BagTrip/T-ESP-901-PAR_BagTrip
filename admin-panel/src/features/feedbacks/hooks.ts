import { feedbacksService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useFeedbacksTab() {
  return usePaginatedQuery({
    queryKey: ['feedbacks'],
    queryFn: params => feedbacksService.getFeedbacks(params),
    filterKeys: [],
  })
}
