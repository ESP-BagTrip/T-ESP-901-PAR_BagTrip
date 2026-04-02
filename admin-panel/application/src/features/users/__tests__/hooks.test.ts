import { describe, it, expect, vi, beforeEach } from 'vitest'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'
import { usersService } from '@/services'

vi.mock('@/shared/hooks/usePaginatedQuery', () => ({
  usePaginatedQuery: vi.fn(() => ({ data: null, isLoading: false, page: 1, setPage: vi.fn() })),
}))

vi.mock('@/services', () => ({
  usersService: { getUsers: vi.fn() },
}))

describe('useUsersTab', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should call usePaginatedQuery with correct queryKey', async () => {
    const { useUsersTab } = await import('@/features/users/hooks')
    useUsersTab({ enabled: true })

    expect(usePaginatedQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['users'],
        enabled: true,
      })
    )
  })

  it('should pass enabled=false correctly', async () => {
    const { useUsersTab } = await import('@/features/users/hooks')
    useUsersTab({ enabled: false })

    expect(usePaginatedQuery).toHaveBeenCalledWith(
      expect.objectContaining({ enabled: false })
    )
  })

  it('should use usersService.getUsers as queryFn', async () => {
    const { useUsersTab } = await import('@/features/users/hooks')
    useUsersTab({ enabled: true })

    const call = vi.mocked(usePaginatedQuery).mock.calls[0][0]
    const params = { page: 1, limit: 10 }
    call.queryFn(params)

    expect(usersService.getUsers).toHaveBeenCalledWith(params)
  })
})
