import { usersService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

export function useUsersTab() {
  return usePaginatedQuery({
    queryKey: ['users'],
    queryFn: params => usersService.getUsers(params),
  })
}
