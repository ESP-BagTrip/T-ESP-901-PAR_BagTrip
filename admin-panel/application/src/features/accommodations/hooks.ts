import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useAccommodationsTab({ enabled }: { enabled: boolean }) {
  return usePaginatedQuery({
    queryKey: ['admin', 'accommodations'],
    queryFn: (params) => adminService.getAllAccommodations(params),
    enabled,
  })
}
