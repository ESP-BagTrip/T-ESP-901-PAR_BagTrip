import { describe, it, expect, vi, beforeEach } from 'vitest'
import { usersService } from '@/services/users'
import { apiClient } from '@/lib/axios'

vi.mock('@/lib/axios', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}))

describe('usersService', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should call GET /admin/users on getUsers and transform response', async () => {
    const apiResponse = {
      items: [{ id: '1', email: 'a@b.com' }],
      total: 1,
      page: 1,
      limit: 10,
      total_pages: 1,
    }
    vi.mocked(apiClient.get).mockResolvedValue({ data: apiResponse })

    const result = await usersService.getUsers({ page: 1, limit: 10 })

    expect(apiClient.get).toHaveBeenCalledWith('/admin/users', { params: { page: 1, limit: 10 } })
    expect(result).toEqual({
      data: apiResponse.items,
      pagination: {
        page: 1,
        limit: 10,
        total: 1,
        total_pages: 1,
      },
    })
  })

  it('should call GET /admin/users/:id on getUserById', async () => {
    const mockUser = { id: '1', email: 'a@b.com' }
    vi.mocked(apiClient.get).mockResolvedValue({ data: { data: mockUser } })

    const result = await usersService.getUserById('1')

    expect(apiClient.get).toHaveBeenCalledWith('/admin/users/1')
    expect(result).toEqual(mockUser)
  })

  it('should call PUT /admin/users/:id on updateUser', async () => {
    const mockUser = { id: '1', email: 'new@b.com' }
    vi.mocked(apiClient.put).mockResolvedValue({ data: { data: mockUser } })

    const result = await usersService.updateUser('1', { email: 'new@b.com' })

    expect(apiClient.put).toHaveBeenCalledWith('/admin/users/1', { email: 'new@b.com' })
    expect(result).toEqual(mockUser)
  })

  it('should call DELETE /admin/users/:id on deleteUser', async () => {
    vi.mocked(apiClient.delete).mockResolvedValue({ data: {} })

    await usersService.deleteUser('1')

    expect(apiClient.delete).toHaveBeenCalledWith('/admin/users/1')
  })

  it('should call PATCH /admin/users/:id/toggle-status on toggleUserStatus', async () => {
    const mockUser = { id: '1', is_active: false }
    vi.mocked(apiClient.patch).mockResolvedValue({ data: { data: mockUser } })

    const result = await usersService.toggleUserStatus('1')

    expect(apiClient.patch).toHaveBeenCalledWith('/admin/users/1/toggle-status')
    expect(result).toEqual(mockUser)
  })

  it('should call GET /admin/users/export on exportUsers', async () => {
    const mockBlob = new Blob(['data'])
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockBlob })

    const result = await usersService.exportUsers({ page: 1 })

    expect(apiClient.get).toHaveBeenCalledWith('/admin/users/export', {
      params: { page: 1 },
      responseType: 'blob',
    })
    expect(result).toEqual(mockBlob)
  })
})
