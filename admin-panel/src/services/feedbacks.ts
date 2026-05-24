import { apiClient } from '@/lib/axios'
import { API_ENDPOINTS } from '@/utils/constants'
import type { AdminListResponse } from '@/types'
import type { Feedback } from '@/types/feedback'
import type { QueryParams } from '@/types'

export const feedbacksService = {
  async getFeedbacks(params?: QueryParams): Promise<AdminListResponse<Feedback>> {
    const response = await apiClient.get<AdminListResponse<Feedback>>(API_ENDPOINTS.FEEDBACKS, {
      params,
    })
    return response.data
  },

  async deleteFeedback(id: string): Promise<void> {
    await apiClient.delete(`${API_ENDPOINTS.FEEDBACKS}/${id}`)
  },
}
