import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useProfilesTab({ enabled }: { enabled: boolean }) {
  return usePaginatedQuery({
    queryKey: ['admin', 'traveler-profiles'],
    queryFn: (params) => adminService.getAllTravelerProfiles(params),
    enabled,
  })
}
