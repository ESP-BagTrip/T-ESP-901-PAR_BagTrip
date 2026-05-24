import { describe, it, expect, vi, beforeEach } from 'vitest'
import { apiClient } from '@/lib/axios'
import { authService } from './auth'

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
const mockPost = vi.mocked(apiClient.post)

beforeEach(() => {
  vi.clearAllMocks()
})

describe('authService', () => {
  describe('login', () => {
    it('should POST credentials to /v1/auth/login and return response.data', async () => {
      const credentials = { email: 'admin@test.com', password: 'secret' }
      const mockData = { access_token: 'tok123', user: { id: '1' } }
      mockPost.mockResolvedValue({ data: mockData })

      const result = await authService.login(credentials)

      expect(mockPost).toHaveBeenCalledWith('/v1/auth/login', credentials)
      expect(result).toEqual(mockData)
    })
  })

  describe('getCurrentUser', () => {
    it('should GET /v1/auth/me and return response.data', async () => {
      const mockUser = { id: '1', email: 'admin@test.com', role: 'admin' }
      mockGet.mockResolvedValue({ data: mockUser })

      const result = await authService.getCurrentUser()

      expect(mockGet).toHaveBeenCalledWith('/v1/auth/me')
      expect(result).toEqual(mockUser)
    })
  })

  describe('logout', () => {
    it('should POST to /v1/auth/logout', async () => {
      mockPost.mockResolvedValue({ data: {} })

      await authService.logout()

      expect(mockPost).toHaveBeenCalledWith('/v1/auth/logout')
    })
  })
})
