import { describe, it, expect, vi, beforeEach } from 'vitest'

describe('apiClient', () => {
  const mockInterceptorsUse = vi.fn()
  const mockCreate = vi.fn(() => ({
    interceptors: {
      response: { use: mockInterceptorsUse },
      request: { use: vi.fn() },
    },
  }))

  beforeEach(() => {
    vi.resetModules()
    vi.clearAllMocks()
  })

  async function loadModule() {
    vi.doMock('axios', () => ({
      default: { create: mockCreate },
    }))
    return import('@/lib/axios')
  }

  it('should create axios instance with correct baseURL', async () => {
    const { apiClient } = await loadModule()
    expect(apiClient).toBeDefined()
    expect(mockCreate).toHaveBeenCalledWith(
      expect.objectContaining({
        baseURL: expect.any(String),
      })
    )
  })

  it('should set Content-Type header to application/json', async () => {
    await loadModule()
    expect(mockCreate).toHaveBeenCalledWith(
      expect.objectContaining({
        headers: { 'Content-Type': 'application/json' },
      })
    )
  })

  it('should set withCredentials to true', async () => {
    await loadModule()
    expect(mockCreate).toHaveBeenCalledWith(
      expect.objectContaining({
        withCredentials: true,
      })
    )
  })

  it('should register a response interceptor', async () => {
    await loadModule()
    expect(mockInterceptorsUse).toHaveBeenCalledWith(
      expect.any(Function),
      expect.any(Function)
    )
  })

  it('should redirect to /login on 401 error', async () => {
    await loadModule()
    const errorHandler = mockInterceptorsUse.mock.calls[0][1]

    const originalLocation = window.location
    Object.defineProperty(window, 'location', {
      writable: true,
      value: { href: '' },
    })

    const error = { response: { status: 401 } }
    await expect(errorHandler(error)).rejects.toEqual(error)
    expect(window.location.href).toBe('/login')

    Object.defineProperty(window, 'location', {
      writable: true,
      value: originalLocation,
    })
  })
})
