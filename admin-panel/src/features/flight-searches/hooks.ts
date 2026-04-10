import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useFlightSearchesTab() {
  return usePaginatedQuery({
    queryKey: ['admin', 'flight-searches'],
    queryFn: params => adminService.getAllFlightSearches(params),
    filterKeys: [],
  })
}
