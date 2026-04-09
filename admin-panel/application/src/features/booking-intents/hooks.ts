import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useBookingIntentsTab({ enabled }: { enabled: boolean }) {
  return usePaginatedQuery({
    queryKey: ['admin', 'booking-intents'],
    queryFn: params => adminService.getAllBookingIntents(params),
    enabled,
  })
}
