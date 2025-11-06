import { useQuery } from '@tanstack/react-query'
import { dashboardService } from '@/services'
import type { QueryParams } from '@/types'

const QUERY_KEYS = {
  metrics: ['dashboard', 'metrics'],
  activity: (params?: QueryParams) => ['dashboard', 'activity', params],
  usersChart: (period: string) => ['dashboard', 'users-chart', period],
  revenueChart: (period: string) => ['dashboard', 'revenue-chart', period],
  feedbacksChart: ['dashboard', 'feedbacks-chart'],
}

export const useDashboardMetrics = () => {
  return useQuery({
    queryKey: QUERY_KEYS.metrics,
    queryFn: dashboardService.getMetrics,
    refetchInterval: 5 * 60 * 1000,
  })
}

export const useActivityLogs = (params?: QueryParams) => {
  return useQuery({
    queryKey: QUERY_KEYS.activity(params),
    queryFn: () => dashboardService.getActivityLogs(params),
  })
}

export const useUserRegistrationsChart = (period: 'week' | 'month' | 'year' = 'month') => {
  return useQuery({
    queryKey: QUERY_KEYS.usersChart(period),
    queryFn: () => dashboardService.getUserRegistrationsChart(period),
  })
}

export const useRevenueChart = (period: 'week' | 'month' | 'year' = 'month') => {
  return useQuery({
    queryKey: QUERY_KEYS.revenueChart(period),
    queryFn: () => dashboardService.getRevenueChart(period),
  })
}

export const useFeedbacksChart = () => {
  return useQuery({
    queryKey: QUERY_KEYS.feedbacksChart,
    queryFn: dashboardService.getFeedbacksChart,
  })
}
