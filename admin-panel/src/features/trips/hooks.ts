import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useTripsTab() {
  return usePaginatedQuery({
    queryKey: ['admin', 'trips'],
    queryFn: params => adminService.getAllTrips(params),
  })
}
