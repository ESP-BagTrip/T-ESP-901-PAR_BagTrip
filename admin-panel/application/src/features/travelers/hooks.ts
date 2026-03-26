import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useTravelersTab({ enabled }: { enabled: boolean }) {
  return usePaginatedQuery({
    queryKey: ['admin', 'travelers'],
    queryFn: (params) => adminService.getAllTravelers(params),
    enabled,
  })
}
