import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useBaggageItemsTab({ enabled }: { enabled: boolean }) {
  return usePaginatedQuery({
    queryKey: ['admin', 'baggage-items'],
    queryFn: (params) => adminService.getAllBaggageItems(params),
    enabled,
  })
}
