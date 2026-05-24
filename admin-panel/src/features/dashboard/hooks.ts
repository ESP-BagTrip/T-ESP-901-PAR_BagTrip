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

/**
 * Recent activity feed — disabled until the backend creates
 * GET /admin/dashboard/activity. Returns empty data for now.
 */
export function useRecentActivity(_limit = 10) {
  return useQuery({
    queryKey: ['dashboard', 'activity'],
    queryFn: () =>
      Promise.resolve({
        data: [],
        pagination: { page: 1, limit: _limit, total: 0, total_pages: 0 },
      }),
    staleTime: STALE_TIME,
  })
}

/**
 * Fallback for the "trip status distribution" donut — groups the first 100 admin trips
 * by status client-side until we have a dedicated endpoint.
 */
export function useTripStatusDistribution() {
  return useQuery({
    queryKey: ['dashboard', 'trips-status-groupby'],
    queryFn: () => adminService.getAllTrips({ page: 1, limit: 100 }),
    staleTime: STALE_TIME,
  })
}
