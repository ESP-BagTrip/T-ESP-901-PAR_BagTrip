import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useFlightsTab({ enabled }: { enabled: boolean }) {
  return usePaginatedQuery({
    queryKey: ['admin', 'flight-bookings'],
    queryFn: params => adminService.getAllFlightBookings(params),
    enabled,
  })
}
