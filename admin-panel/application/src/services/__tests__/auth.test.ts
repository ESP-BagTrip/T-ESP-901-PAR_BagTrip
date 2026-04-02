import { describe, it, expect, vi, beforeEach } from 'vitest'
import { authService } from '@/services/auth'
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

describe('authService', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should call POST /v1/auth/register on register', async () => {
    const mockResponse = { data: { token: 'abc', user: { id: '1' } } }
    vi.mocked(apiClient.post).mockResolvedValue(mockResponse)

    const credentials = { email: 'test@test.com', password: 'pass123' }
    const result = await authService.register(credentials)

    expect(apiClient.post).toHaveBeenCalledWith('/v1/auth/register', credentials)
    expect(result).toEqual(mockResponse.data)
  })

  it('should call POST /v1/auth/login on login', async () => {
    const mockResponse = { data: { token: 'abc', user: { id: '1' } } }
    vi.mocked(apiClient.post).mockResolvedValue(mockResponse)

    const credentials = { email: 'test@test.com', password: 'pass123' }
    const result = await authService.login(credentials)

    expect(apiClient.post).toHaveBeenCalledWith('/v1/auth/login', credentials)
    expect(result).toEqual(mockResponse.data)
  })

  it('should call GET /v1/auth/me on getCurrentUser', async () => {
    const mockUser = { id: '1', email: 'test@test.com' }
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockUser })

    const result = await authService.getCurrentUser()

    expect(apiClient.get).toHaveBeenCalledWith('/v1/auth/me')
    expect(result).toEqual(mockUser)
  })

  it('should call POST /v1/auth/logout on logout', async () => {
    vi.mocked(apiClient.post).mockResolvedValue({ data: {} })

    await authService.logout()

    expect(apiClient.post).toHaveBeenCalledWith('/v1/auth/logout')
  })
})
