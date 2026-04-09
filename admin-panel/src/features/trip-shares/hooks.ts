import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useTripSharesTab() {
  return usePaginatedQuery({
    queryKey: ['admin', 'trip-shares'],
    queryFn: params => adminService.getAllTripShares(params),
  })
}
