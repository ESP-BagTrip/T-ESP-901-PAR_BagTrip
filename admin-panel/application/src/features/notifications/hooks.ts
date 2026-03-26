import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useNotificationsTab({ enabled }: { enabled: boolean }) {
  return usePaginatedQuery({
    queryKey: ['admin', 'notifications'],
    queryFn: (params) => adminService.getAllNotifications(params),
    enabled,
  })
}
