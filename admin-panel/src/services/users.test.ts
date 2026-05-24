import { describe, it, expect, vi, beforeEach } from 'vitest'
import { apiClient } from '@/lib/axios'
import { usersService } from './users'

vi.mock('@/lib/axios', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}))

const mockGet = vi.mocked(apiClient.get)
const mockPut = vi.mocked(apiClient.put)
const mockPatch = vi.mocked(apiClient.patch)
const mockDelete = vi.mocked(apiClient.delete)

beforeEach(() => {
  vi.clearAllMocks()
})

describe('usersService', () => {
  describe('getUsers', () => {
    it('should GET /admin/users with params and transform response to PaginatedResponse', async () => {
      const apiResponse = {
        items: [{ id: 'u1', email: 'a@b.com' }],
        total: 50,
        page: 2,
        limit: 10,
        total_pages: 5,
      }
      mockGet.mockResolvedValue({ data: apiResponse })
      const params = { page: 2, limit: 10 }

      const result = await usersService.getUsers(params)

      expect(mockGet).toHaveBeenCalledWith('/admin/users', { params })
      expect(result).toEqual({
        data: apiResponse.items,
        pagination: {
          page: 2,
          limit: 10,
          total: 50,
          total_pages: 5,
        },
      })
    })

    it('should call without params', async () => {
      mockGet.mockResolvedValue({
        data: { items: [], total: 0, page: 1, limit: 10, total_pages: 0 },
      })

      await usersService.getUsers()

      expect(mockGet).toHaveBeenCalledWith('/admin/users', { params: undefined })
    })
  })

  describe('getUserById', () => {
    it('should GET /admin/users/{id} and return response.data.data', async () => {
      const user = { id: 'u1', email: 'a@b.com' }
      mockGet.mockResolvedValue({ data: { data: user } })

      const result = await usersService.getUserById('u1')

      expect(mockGet).toHaveBeenCalledWith('/admin/users/u1')
      expect(result).toEqual(user)
    })
  })

  describe('updateUser', () => {
    it('should PUT /admin/users/{id} with data and return response.data.data', async () => {
      const updatedUser = { id: 'u1', first_name: 'John' }
      mockPut.mockResolvedValue({ data: { data: updatedUser } })
      const data = { first_name: 'John' }

      const result = await usersService.updateUser('u1', data)

      expect(mockPut).toHaveBeenCalledWith('/admin/users/u1', data)
      expect(result).toEqual(updatedUser)
    })
  })

  describe('deleteUser', () => {
    it('should DELETE /admin/users/{id}', async () => {
      mockDelete.mockResolvedValue({ data: {} })

      await usersService.deleteUser('u1')

      expect(mockDelete).toHaveBeenCalledWith('/admin/users/u1')
    })
  })

  describe('toggleUserStatus', () => {
    it('should PATCH /admin/users/{id}/toggle-status and return response.data.data', async () => {
      const user = { id: 'u1', is_active: false }
      mockPatch.mockResolvedValue({ data: { data: user } })

      const result = await usersService.toggleUserStatus('u1')

      expect(mockPatch).toHaveBeenCalledWith('/admin/users/u1/toggle-status')
      expect(result).toEqual(user)
    })
  })

  describe('exportUsers', () => {
    it('should GET /admin/users/export with responseType blob and return response.data', async () => {
      const blob = new Blob(['csv-data'])
      mockGet.mockResolvedValue({ data: blob })
      const params = { role: 'user' }

      const result = await usersService.exportUsers(params)

      expect(mockGet).toHaveBeenCalledWith('/admin/users/export', {
        params,
        responseType: 'blob',
      })
      expect(result).toBe(blob)
    })

    it('should call without params', async () => {
      const blob = new Blob(['csv-data'])
      mockGet.mockResolvedValue({ data: blob })

      await usersService.exportUsers()

      expect(mockGet).toHaveBeenCalledWith('/admin/users/export', {
        params: undefined,
        responseType: 'blob',
      })
    })
  })
})
