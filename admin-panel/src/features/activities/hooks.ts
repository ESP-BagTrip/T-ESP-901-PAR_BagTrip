import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useActivitiesTab() {
  return usePaginatedQuery({
    queryKey: ['admin', 'activities'],
    queryFn: params => adminService.getAllActivities(params),
  })
}
