import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useTravelersTab() {
  return usePaginatedQuery({
    queryKey: ['admin', 'travelers'],
    queryFn: params => adminService.getAllTravelers(params),
  })
}
