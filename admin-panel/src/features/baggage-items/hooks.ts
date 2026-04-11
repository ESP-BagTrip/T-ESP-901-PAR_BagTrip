import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useBaggageItemsTab() {
  return usePaginatedQuery({
    queryKey: ['admin', 'baggage-items'],
    queryFn: params => adminService.getAllBaggageItems(params),
    filterKeys: [],
  })
}
