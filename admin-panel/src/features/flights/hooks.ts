import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useFlightsTab() {
  return usePaginatedQuery({
    queryKey: ['admin', 'flight-bookings'],
    queryFn: params => adminService.getAllFlightBookings(params),
  })
}
