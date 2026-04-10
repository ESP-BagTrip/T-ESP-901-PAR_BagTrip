import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook, waitFor, act } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { type ReactNode } from 'react'
import { useUsers, useUser, useUpdateUser, useDeleteUser, useToggleUserStatus, useExportUsers } from '../useUsers'

const mockUsersResponse = { data: [], pagination: { page: 1, limit: 10, total: 0, total_pages: 0 } }
const mockUser = { id: '1', email: 'test@test.com', first_name: 'Test', last_name: 'User' }

vi.mock('@/services', () => ({
  usersService: {
    getUsers: vi.fn().mockResolvedValue({ data: [], pagination: { page: 1, limit: 10, total: 0, total_pages: 0 } }),
    getUserById: vi.fn().mockResolvedValue({ id: '1', email: 'test@test.com', first_name: 'Test', last_name: 'User' }),
    updateUser: vi.fn().mockResolvedValue({ id: '1', email: 'test@test.com', first_name: 'Test', last_name: 'User' }),
    deleteUser: vi.fn().mockResolvedValue(undefined),
    toggleUserStatus: vi.fn().mockResolvedValue({ id: '1', email: 'test@test.com', first_name: 'Test', last_name: 'User' }),
    exportUsers: vi.fn().mockResolvedValue(new Blob(['csv data'], { type: 'text/csv' })),
  },
}))

function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  })
  return ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

describe('useUsers hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('useUsers returns users data', async () => {
    const { result } = renderHook(() => useUsers(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockUsersResponse)
  })

  it('useUsers passes params to service', async () => {
    const { usersService } = await import('@/services')
    const params = { page: 2, limit: 5 }
    const { result } = renderHook(() => useUsers(params), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(usersService.getUsers).toHaveBeenCalledWith(params)
  })

  it('useUser returns a single user by id', async () => {
    const { result } = renderHook(() => useUser('1'), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockUser)
  })

  it('useUser does not fetch when id is empty', async () => {
    const { usersService } = await import('@/services')
    const { result } = renderHook(() => useUser(''), { wrapper: createWrapper() })
    // Should not fetch since enabled: !!id is false
    await waitFor(() => expect(result.current.fetchStatus).toBe('idle'))
    expect(usersService.getUserById).not.toHaveBeenCalled()
  })

  it('useUpdateUser calls updateUser service', async () => {
    const { usersService } = await import('@/services')
    const { result } = renderHook(() => useUpdateUser(), { wrapper: createWrapper() })

    act(() => {
      result.current.mutate({ id: '1', data: { first_name: 'Updated' } })
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(usersService.updateUser).toHaveBeenCalledWith('1', { first_name: 'Updated' })
  })

  it('useDeleteUser calls deleteUser service', async () => {
    const { usersService } = await import('@/services')
    const { result } = renderHook(() => useDeleteUser(), { wrapper: createWrapper() })

    act(() => {
      result.current.mutate('1')
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(usersService.deleteUser).toHaveBeenCalledWith('1', expect.anything())
    })

    it('useToggleUserStatus calls toggleUserStatus service', async () => {
    const { usersService } = await import('@/services')

    const { result } = renderHook(() => useToggleUserStatus(), { wrapper: createWrapper() })

    act(() => {
      result.current.mutate('1')
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(usersService.toggleUserStatus).toHaveBeenCalledWith('1', expect.anything())
    })

  it('useExportUsers calls exportUsers and triggers download', async () => {
    const { usersService } = await import('@/services')

    const mockCreateObjectURL = vi.fn().mockReturnValue('blob:url')
    const mockRevokeObjectURL = vi.fn()
    window.URL.createObjectURL = mockCreateObjectURL
    window.URL.revokeObjectURL = mockRevokeObjectURL

    const mockClick = vi.fn()
    const originalCreateElement = document.createElement.bind(document)
    vi.spyOn(document, 'createElement').mockImplementation((tag: string) => {
      if (tag === 'a') {
        return { href: '', download: '', click: mockClick } as unknown as HTMLElement
      }
      return originalCreateElement(tag)
    })
    const originalAppendChild = document.body.appendChild.bind(document.body)
    const originalRemoveChild = document.body.removeChild.bind(document.body)
    vi.spyOn(document.body, 'appendChild').mockImplementation((node: Node) => {
      if ((node as HTMLElement).tagName === undefined) return node
      return originalAppendChild(node)
    })
    vi.spyOn(document.body, 'removeChild').mockImplementation((node: Node) => {
      if ((node as HTMLElement).tagName === undefined) return node
      return originalRemoveChild(node)
    })

    const { result } = renderHook(() => useExportUsers(), { wrapper: createWrapper() })

    act(() => {
      result.current.mutate()
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(usersService.exportUsers).toHaveBeenCalled()
    expect(mockCreateObjectURL).toHaveBeenCalled()
    expect(mockClick).toHaveBeenCalled()
    expect(mockRevokeObjectURL).toHaveBeenCalled()
  })
})
