import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useBudgetItemsTab({ enabled }: { enabled: boolean }) {
  return usePaginatedQuery({
    queryKey: ['admin', 'budgetItems'],
    queryFn: params => adminService.getAllBudgetItems(params),
    enabled,
  })
}
