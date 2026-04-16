import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useNotificationsTab() {
  return usePaginatedQuery({
    queryKey: ['admin', 'notifications'],
    queryFn: params => adminService.getAllNotifications(params),
    filterKeys: [],
  })
}
