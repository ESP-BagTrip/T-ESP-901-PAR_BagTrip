import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook } from '@testing-library/react'
import { useQuery, useMutation } from '@tanstack/react-query'
import {
  useUsers,
  useUser,
  useUpdateUser,
  useDeleteUser,
  useToggleUserStatus,
  useExportUsers,
} from './useUsers'

const mockSetQueryData = vi.fn()
const mockInvalidateQueries = vi.fn()

vi.mock('@tanstack/react-query', () => ({
  useQueryClient: () => ({
    setQueryData: mockSetQueryData,
    invalidateQueries: mockInvalidateQueries,
  }),
  useQuery: vi.fn(() => ({
    data: undefined,
    isLoading: false,
    isError: false,
    error: null,
  })),
  useMutation: vi.fn(() => ({
    mutate: vi.fn(),
    mutateAsync: vi.fn(),
    isPending: false,
    error: null,
  })),
}))

vi.mock('@/services', () => ({
  usersService: {
    getUsers: vi.fn(),
    getUserById: vi.fn(),
    updateUser: vi.fn(),
    deleteUser: vi.fn(),
    toggleUserStatus: vi.fn(),
    exportUsers: vi.fn(),
  },
}))

describe('useUsers hooks', () => {
  beforeEach(() => {
    vi.mocked(useQuery).mockClear()
    vi.mocked(useMutation).mockClear()
    mockSetQueryData.mockClear()
    mockInvalidateQueries.mockClear()
  })

  describe('useUsers', () => {
    it('calls useQuery with correct queryKey', () => {
      const params = { page: 1, limit: 10 }
      useUsers(params)
      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['users', params],
        })
      )
    })

    it('calls useQuery with undefined params when none provided', () => {
      useUsers()
      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['users', undefined],
        })
      )
    })

    it('queryFn calls usersService.getUsers with params', async () => {
      const { usersService } = await import('@/services')
      const params = { page: 2, limit: 20 }
      renderHook(() => useUsers(params))
      const opts = vi.mocked(useQuery).mock.calls[0][0]
      opts.queryFn!({} as never)
      expect(usersService.getUsers).toHaveBeenCalledWith(params)
    })

    it('returns data when useQuery resolves', () => {
      vi.mocked(useQuery).mockReturnValueOnce({
        data: { items: [{ id: '1' }], total: 1 },
        isLoading: false,
        isError: false,
        error: null,
      } as ReturnType<typeof useQuery>)

      const { result } = renderHook(() => useUsers())
      expect(result.current.data).toEqual({ items: [{ id: '1' }], total: 1 })
    })
  })

  describe('useUser', () => {
    it('calls useQuery with correct queryKey and enabled flag', () => {
      useUser('user-123')
      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['users', 'user-123'],
          enabled: true,
        })
      )
    })

    it('has enabled: false when id is empty string', () => {
      useUser('')
      expect(useQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          queryKey: ['users', ''],
          enabled: false,
        })
      )
    })

    it('queryFn calls usersService.getUserById with id', async () => {
      const { usersService } = await import('@/services')
      renderHook(() => useUser('abc'))
      const opts = vi.mocked(useQuery).mock.calls[0][0]
      opts.queryFn!({} as never)
      expect(usersService.getUserById).toHaveBeenCalledWith('abc')
    })
  })

  describe('useUpdateUser', () => {
    it('calls useMutation with mutationFn and onSuccess', () => {
      useUpdateUser()
      expect(useMutation).toHaveBeenCalledWith(
        expect.objectContaining({
          mutationFn: expect.any(Function),
          onSuccess: expect.any(Function),
        })
      )
    })

    it('mutationFn calls usersService.updateUser with id and data', async () => {
      const { usersService } = await import('@/services')
      renderHook(() => useUpdateUser())
      const opts = vi.mocked(useMutation).mock.calls[0][0] as { mutationFn: (args: { id: string; data: object }) => void }
      opts.mutationFn({ id: 'u1', data: { email: 'new@x.com' } })
      expect(usersService.updateUser).toHaveBeenCalledWith('u1', { email: 'new@x.com' })
    })

    it('onSuccess sets query data and invalidates users queries', () => {
      renderHook(() => useUpdateUser())
      const opts = vi.mocked(useMutation).mock.calls[0][0] as { onSuccess: (user: { id: string }) => void }
      const updatedUser = { id: 'u1', email: 'new@x.com' }
      opts.onSuccess(updatedUser)
      expect(mockSetQueryData).toHaveBeenCalledWith(['users', 'u1'], updatedUser)
      expect(mockInvalidateQueries).toHaveBeenCalledWith({ queryKey: ['users'] })
    })
  })

  describe('useDeleteUser', () => {
    it('calls useMutation', () => {
      useDeleteUser()
      expect(useMutation).toHaveBeenCalledWith(
        expect.objectContaining({
          mutationFn: expect.any(Function),
          onSuccess: expect.any(Function),
        })
      )
    })

    it('onSuccess invalidates users queries', () => {
      renderHook(() => useDeleteUser())
      const opts = vi.mocked(useMutation).mock.calls[0][0] as { onSuccess: () => void }
      opts.onSuccess()
      expect(mockInvalidateQueries).toHaveBeenCalledWith({ queryKey: ['users'] })
    })
  })

  describe('useToggleUserStatus', () => {
    it('calls useMutation', () => {
      useToggleUserStatus()
      expect(useMutation).toHaveBeenCalledWith(
        expect.objectContaining({
          mutationFn: expect.any(Function),
          onSuccess: expect.any(Function),
        })
      )
    })

    it('onSuccess sets query data and invalidates users queries', () => {
      renderHook(() => useToggleUserStatus())
      const opts = vi.mocked(useMutation).mock.calls[0][0] as { onSuccess: (user: { id: string }) => void }
      const updatedUser = { id: 'u2', is_active: false }
      opts.onSuccess(updatedUser)
      expect(mockSetQueryData).toHaveBeenCalledWith(['users', 'u2'], updatedUser)
      expect(mockInvalidateQueries).toHaveBeenCalledWith({ queryKey: ['users'] })
    })
  })

  describe('useExportUsers', () => {
    it('calls useMutation with mutationFn and onSuccess', () => {
      useExportUsers()
      expect(useMutation).toHaveBeenCalledWith(
        expect.objectContaining({
          mutationFn: expect.any(Function),
          onSuccess: expect.any(Function),
        })
      )
    })

    it('onSuccess creates a download link and triggers click', () => {
      const mockBlob = new Blob(['csv-data'], { type: 'text/csv' })
      const mockUrl = 'blob:http://localhost/fake'
      const mockClick = vi.fn()
      const mockLink = { href: '', download: '', click: mockClick } as unknown as HTMLAnchorElement

      const createObjectURLSpy = vi.spyOn(window.URL, 'createObjectURL').mockReturnValue(mockUrl)
      const revokeObjectURLSpy = vi.spyOn(window.URL, 'revokeObjectURL').mockImplementation(vi.fn())
      const createElementSpy = vi.spyOn(document, 'createElement').mockReturnValue(mockLink as never)
      const appendChildSpy = vi.spyOn(document.body, 'appendChild').mockImplementation(vi.fn() as never)
      const removeChildSpy = vi.spyOn(document.body, 'removeChild').mockImplementation(vi.fn() as never)

      // Call the hook function directly (not via renderHook) to avoid DOM container issues
      useExportUsers()
      const opts = vi.mocked(useMutation).mock.calls[0][0] as { onSuccess: (blob: Blob) => void }
      opts.onSuccess(mockBlob)

      expect(createObjectURLSpy).toHaveBeenCalledWith(mockBlob)
      expect(mockClick).toHaveBeenCalled()
      expect(revokeObjectURLSpy).toHaveBeenCalledWith(mockUrl)

      createObjectURLSpy.mockRestore()
      revokeObjectURLSpy.mockRestore()
      createElementSpy.mockRestore()
      appendChildSpy.mockRestore()
      removeChildSpy.mockRestore()
    })
  })
})
