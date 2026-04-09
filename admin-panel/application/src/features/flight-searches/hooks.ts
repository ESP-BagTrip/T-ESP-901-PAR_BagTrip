import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useFlightSearchesTab({ enabled }: { enabled: boolean }) {
  return usePaginatedQuery({
    queryKey: ['admin', 'flight-searches'],
    queryFn: params => adminService.getAllFlightSearches(params),
    enabled,
  })
}
