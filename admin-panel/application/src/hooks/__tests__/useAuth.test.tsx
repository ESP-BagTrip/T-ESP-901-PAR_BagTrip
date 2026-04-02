import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook, waitFor, act } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { type ReactNode } from 'react'
import { useAuth } from '../useAuth'

const mockPush = vi.fn()

vi.mock('next/navigation', () => ({
  useRouter: () => ({
    push: mockPush,
    replace: vi.fn(),
    back: vi.fn(),
    prefetch: vi.fn(),
  }),
  usePathname: () => '/',
  useSearchParams: () => new URLSearchParams(),
  redirect: vi.fn(),
}))

vi.mock('@/services', () => ({
  authService: {
    getCurrentUser: vi.fn().mockResolvedValue({ id: '1', email: 'test@test.com', plan: 'ADMIN' }),
    login: vi.fn().mockResolvedValue({ user: { id: '1', email: 'test@test.com' }, access_token: 'token' }),
    register: vi.fn().mockResolvedValue({ user: { id: '1', email: 'test@test.com' }, access_token: 'token' }),
    logout: vi.fn().mockResolvedValue(undefined),
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

describe('useAuth', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    Object.defineProperty(document, 'cookie', {
      writable: true,
      value: 'auth-status=authenticated',
    })
  })

  it('returns user data when authenticated', async () => {
    const { result } = renderHook(() => useAuth(), { wrapper: createWrapper() })

    await waitFor(() => expect(result.current.isLoading).toBe(false))
    expect(result.current.user).toEqual({ id: '1', email: 'test@test.com', plan: 'ADMIN' })
    expect(result.current.isAuthenticated).toBe(true)
  })

  it('returns isLoading initially', () => {
    const { result } = renderHook(() => useAuth(), { wrapper: createWrapper() })
    expect(result.current.isLoading).toBe(true)
  })

  it('does not fetch user when no auth cookie', async () => {
    Object.defineProperty(document, 'cookie', { writable: true, value: '' })
    const { authService } = await import('@/services')

    const { result } = renderHook(() => useAuth(), { wrapper: createWrapper() })

    await waitFor(() => expect(result.current.isLoading).toBe(false))
    expect(result.current.isAuthenticated).toBe(false)
    expect(authService.getCurrentUser).not.toHaveBeenCalled()
  })

  it('login calls authService.login and navigates to dashboard', async () => {
    const { authService } = await import('@/services')

    const { result } = renderHook(() => useAuth(), { wrapper: createWrapper() })

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    act(() => {
      result.current.login({ email: 'test@test.com', password: 'password' })
    })

    await waitFor(() => expect(authService.login).toHaveBeenCalledWith({ email: 'test@test.com', password: 'password' }))
    await waitFor(() => expect(mockPush).toHaveBeenCalledWith('/dashboard'))
  })

  it('register calls authService.register and navigates to dashboard', async () => {
    const { authService } = await import('@/services')

    const { result } = renderHook(() => useAuth(), { wrapper: createWrapper() })

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    act(() => {
      result.current.register({ email: 'test@test.com', password: 'password', first_name: 'Test', last_name: 'User' })
    })

    await waitFor(() => expect(authService.register).toHaveBeenCalled())
    await waitFor(() => expect(mockPush).toHaveBeenCalledWith('/dashboard'))
  })

  it('logout calls authService.logout and navigates to login', async () => {
    const { authService } = await import('@/services')

    const { result } = renderHook(() => useAuth(), { wrapper: createWrapper() })

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    await act(async () => {
      await result.current.logout()
    })

    expect(authService.logout).toHaveBeenCalled()
    expect(mockPush).toHaveBeenCalledWith('/login')
  })

  it('logout navigates to login even when authService.logout throws', async () => {
    const { authService } = await import('@/services')
    vi.mocked(authService.logout).mockRejectedValueOnce(new Error('Network error'))

    const { result } = renderHook(() => useAuth(), { wrapper: createWrapper() })

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    await act(async () => {
      await result.current.logout()
    })

    expect(mockPush).toHaveBeenCalledWith('/login')
  })

  it('exposes mutation states', async () => {
    const { result } = renderHook(() => useAuth(), { wrapper: createWrapper() })

    await waitFor(() => expect(result.current.isLoading).toBe(false))

    expect(result.current.isLoggingIn).toBe(false)
    expect(result.current.isRegistering).toBe(false)
    expect(result.current.loginError).toBeNull()
    expect(result.current.registerError).toBeNull()
  })
})
