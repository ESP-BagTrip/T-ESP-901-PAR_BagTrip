import { apiClient } from '@/lib/axios';
import { API_ENDPOINTS } from '@/utils/constants';
import type { Feedback, FeedbackFilters, ApiResponse, PaginatedResponse, QueryParams } from '@/types';

interface FeedbackQueryParams extends QueryParams {
  filters?: FeedbackFilters;
}

export const feedbacksService = {
  async getFeedbacks(params?: FeedbackQueryParams): Promise<PaginatedResponse<Feedback>> {
    const response = await apiClient.get<ApiResponse<PaginatedResponse<Feedback>>>(
      API_ENDPOINTS.FEEDBACKS,
      { params }
    );
    return response.data.data;
  },

  async getFeedbackById(id: string): Promise<Feedback> {
    const response = await apiClient.get<ApiResponse<Feedback>>(
      `${API_ENDPOINTS.FEEDBACKS}/${id}`
    );
    return response.data.data;
  },

  async updateFeedbackStatus(id: string, status: 'pending' | 'resolved'): Promise<Feedback> {
    const response = await apiClient.patch<ApiResponse<Feedback>>(
      `${API_ENDPOINTS.FEEDBACKS}/${id}/status`,
      { status }
    );
    return response.data.data;
  },

  async deleteFeedback(id: string): Promise<void> {
    await apiClient.delete(`${API_ENDPOINTS.FEEDBACKS}/${id}`);
  },

  async exportFeedbacks(params?: FeedbackQueryParams): Promise<Blob> {
    const response = await apiClient.get(`${API_ENDPOINTS.FEEDBACKS}/export`, {
      params,
      responseType: 'blob',
    });
    return response.data;
  },
};