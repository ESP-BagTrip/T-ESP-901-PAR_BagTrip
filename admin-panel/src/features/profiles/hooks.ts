import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useProfilesTab() {
  return usePaginatedQuery({
    queryKey: ['admin', 'traveler-profiles'],
    queryFn: params => adminService.getAllTravelerProfiles(params),
    filterKeys: [],
  })
}
