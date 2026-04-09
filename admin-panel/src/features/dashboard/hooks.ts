import { useQuery } from '@tanstack/react-query'

import { dashboardService, adminService } from '@/services'

const STALE_TIME = 60_000 // 1min

export function useDashboardMetrics() {
  return useQuery({
    queryKey: ['dashboard', 'metrics'],
    queryFn: () => dashboardService.getMetrics(),
    staleTime: STALE_TIME,
  })
}

export function useUserRegistrationsChart(period: 'week' | 'month' | 'year' = 'month') {
  return useQuery({
    queryKey: ['dashboard', 'users-chart', period],
    queryFn: () => dashboardService.getUserRegistrationsChart(period),
    staleTime: STALE_TIME,
  })
}

export function useRevenueChart(period: 'week' | 'month' | 'year' = 'month') {
  return useQuery({
    queryKey: ['dashboard', 'revenue-chart', period],
    queryFn: () => dashboardService.getRevenueChart(period),
    staleTime: STALE_TIME,
  })
}

export function useFeedbacksChart() {
  return useQuery({
    queryKey: ['dashboard', 'feedbacks-chart'],
    queryFn: () => dashboardService.getFeedbacksChart(),
    staleTime: STALE_TIME,
  })
}

export function useRecentActivity(limit = 10) {
  return useQuery({
    queryKey: ['dashboard', 'activity', { limit }],
    queryFn: () => dashboardService.getActivityLogs({ page: 1, limit }),
    staleTime: STALE_TIME,
  })
}

/**
 * Fallback for the "trip status distribution" donut — groups the first 200 admin trips
 * by status client-side until we have a dedicated endpoint.
 */
export function useTripStatusDistribution() {
  return useQuery({
    queryKey: ['dashboard', 'trips-status-groupby'],
    queryFn: () => adminService.getAllTrips({ page: 1, limit: 200 }),
    staleTime: STALE_TIME,
  })
}
