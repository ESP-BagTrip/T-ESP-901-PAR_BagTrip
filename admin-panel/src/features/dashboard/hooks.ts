import { useQuery } from '@tanstack/react-query'
import { dashboardService } from '@/services'

export function useDashboardMetrics({ enabled }: { enabled: boolean }) {
  return useQuery({
    queryKey: ['dashboard', 'metrics'],
    queryFn: () => dashboardService.getMetrics(),
    enabled,
  })
}

export function useUserRegistrationsChart({
  enabled,
  period = 'month',
}: {
  enabled: boolean
  period?: 'week' | 'month' | 'year'
}) {
  return useQuery({
    queryKey: ['dashboard', 'users-chart', period],
    queryFn: () => dashboardService.getUserRegistrationsChart(period),
    enabled,
  })
}

export function useRevenueChart({
  enabled,
  period = 'month',
}: {
  enabled: boolean
  period?: 'week' | 'month' | 'year'
}) {
  return useQuery({
    queryKey: ['dashboard', 'revenue-chart', period],
    queryFn: () => dashboardService.getRevenueChart(period),
    enabled,
  })
}

export function useFeedbacksChart({ enabled }: { enabled: boolean }) {
  return useQuery({
    queryKey: ['dashboard', 'feedbacks-chart'],
    queryFn: () => dashboardService.getFeedbacksChart(),
    enabled,
  })
}
