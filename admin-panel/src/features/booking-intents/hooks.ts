import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useBookingIntentsTab() {
  return usePaginatedQuery({
    queryKey: ['admin', 'booking-intents'],
    queryFn: params => adminService.getAllBookingIntents(params),
  })
}
