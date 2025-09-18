import { apiClient } from '@/lib/axios';
import { API_ENDPOINTS } from '@/utils/constants';
import type { DashboardMetrics, ActivityLog, ChartData, ApiResponse, PaginatedResponse, QueryParams } from '@/types';

export const dashboardService = {
  async getMetrics(): Promise<DashboardMetrics> {
    const response = await apiClient.get<ApiResponse<DashboardMetrics>>(
      API_ENDPOINTS.DASHBOARD.METRICS
    );
    return response.data.data;
  },

  async getActivityLogs(params?: QueryParams): Promise<PaginatedResponse<ActivityLog>> {
    const response = await apiClient.get<ApiResponse<PaginatedResponse<ActivityLog>>>(
      API_ENDPOINTS.DASHBOARD.ACTIVITY,
      { params }
    );
    return response.data.data;
  },

  async getUserRegistrationsChart(period: 'week' | 'month' | 'year' = 'month'): Promise<ChartData[]> {
    const response = await apiClient.get<ApiResponse<ChartData[]>>(
      `${API_ENDPOINTS.DASHBOARD.METRICS}/users-chart`,
      { params: { period } }
    );
    return response.data.data;
  },

  async getRevenueChart(period: 'week' | 'month' | 'year' = 'month'): Promise<ChartData[]> {
    const response = await apiClient.get<ApiResponse<ChartData[]>>(
      `${API_ENDPOINTS.DASHBOARD.METRICS}/revenue-chart`,
      { params: { period } }
    );
    return response.data.data;
  },

  async getFeedbacksChart(): Promise<ChartData[]> {
    const response = await apiClient.get<ApiResponse<ChartData[]>>(
      `${API_ENDPOINTS.DASHBOARD.METRICS}/feedbacks-chart`
    );
    return response.data.data;
  },
};