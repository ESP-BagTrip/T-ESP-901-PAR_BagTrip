import { apiClient } from '@/lib/axios'
import { API_ENDPOINTS } from '@/utils/constants'
import type { User, ApiResponse, PaginatedResponse, QueryParams } from '@/types'

export const usersService = {
  async getUsers(params?: QueryParams): Promise<PaginatedResponse<User>> {
    // API returns { items, total, page, limit, total_pages } directly (not wrapped)
    // Note: API uses snake_case (total_pages) but we convert to camelCase (total_pages)
    const response = await apiClient.get<{
      items: User[]
      total: number
      page: number
      limit: number
      total_pages: number
    }>(API_ENDPOINTS.USERS, { params })
    // Convert to PaginatedResponse format
    return {
      data: response.data.items,
      pagination: {
        page: response.data.page,
        limit: response.data.limit,
        total: response.data.total,
        total_pages: response.data.total_pages,
      },
    }
  },

  async getUserById(id: string): Promise<User> {
    const response = await apiClient.get<ApiResponse<User>>(`${API_ENDPOINTS.USERS}/${id}`)
    return response.data.data
  },

  async updateUser(id: string, data: Partial<User>): Promise<User> {
    const response = await apiClient.put<ApiResponse<User>>(`${API_ENDPOINTS.USERS}/${id}`, data)
    return response.data.data
  },

  async deleteUser(id: string): Promise<void> {
    await apiClient.delete(`${API_ENDPOINTS.USERS}/${id}`)
  },

  async toggleUserStatus(id: string): Promise<User> {
    const response = await apiClient.patch<ApiResponse<User>>(
      `${API_ENDPOINTS.USERS}/${id}/toggle-status`
    )
    return response.data.data
  },

  async exportUsers(params?: QueryParams): Promise<Blob> {
    const response = await apiClient.get(`${API_ENDPOINTS.USERS}/export`, {
      params,
      responseType: 'blob',
    })
    return response.data
  },
}
