import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook } from '@testing-library/react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useAuth, NotAdminError } from './useAuth'

const mockPush = vi.fn()
const mockSetQueryData = vi.fn()
const mockRemoveQueries = vi.fn()
const mockClear = vi.fn()
const mockInvalidateQueries = vi.fn()

vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: mockPush }),
}))

const mockUseQuery = vi.fn(() => ({
  data: undefined,
  isLoading: true,
  error: null,
}))

const mockUseMutation = vi.fn(({ mutationFn }: { mutationFn: unknown }) => ({
  mutate: mutationFn,
  isPending: false,
  error: null,
}))

vi.mock('@tanstack/react-query', () => ({
  useQueryClient: () => ({
    setQueryData: mockSetQueryData,
    removeQueries: mockRemoveQueries,
    clear: mockClear,
    invalidateQueries: mockInvalidateQueries,
  }),
  useQuery: (...args: unknown[]) => mockUseQuery(...(args as [never])),
  useMutation: (...args: unknown[]) => mockUseMutation(...(args as [never])),
}))

vi.mock('@/services', () => ({
  authService: {
    getCurrentUser: vi.fn(),
    login: vi.fn(),
    logout: vi.fn(),
  },
}))

describe('isAdminUser (tested via useAuth)', () => {
  beforeEach(() => {
    mockUseQuery.mockClear()
    mockUseMutation.mockClear()
  })

  it('returns isAdmin false when user is undefined (initial state)', () => {
    mockUseQuery.mockReturnValueOnce({
      data: undefined,
      isLoading: true,
      error: null,
    })

    const { result } = renderHook(() => useAuth())
    expect(result.current.isAdmin).toBe(false)
  })

  it('returns isAdmin true when user has ADMIN plan', () => {
    mockUseQuery.mockReturnValueOnce({
      data: { id: '1', email: 'admin@test.com', plan: 'ADMIN', created_at: '', updated_at: null },
      isLoading: false,
      error: null,
    })

    const { result } = renderHook(() => useAuth())
    expect(result.current.isAdmin).toBe(true)
  })

  it('returns isAdmin false when user has FREE plan', () => {
    mockUseQuery.mockReturnValueOnce({
      data: { id: '2', email: 'user@test.com', plan: 'FREE', created_at: '', updated_at: null },
      isLoading: false,
      error: null,
    })

    const { result } = renderHook(() => useAuth())
    expect(result.current.isAdmin).toBe(false)
  })
})

describe('NotAdminError', () => {
  it('has correct name', () => {
    const error = new NotAdminError()
    expect(error.name).toBe('NotAdminError')
  })

  it('has correct message', () => {
    const error = new NotAdminError()
    expect(error.message).toBe('Accès réservé aux administrateurs.')
  })

  it('is an instance of Error', () => {
    const error = new NotAdminError()
    expect(error).toBeInstanceOf(Error)
  })
})

describe('hasAuthCookie (tested indirectly via useAuth)', () => {
  beforeEach(() => {
    mockUseQuery.mockClear()
  })

  it('useQuery is called with enabled: false when no auth cookie is present', () => {
    // document.cookie is empty by default in jsdom
    Object.defineProperty(document, 'cookie', { value: '', writable: true })

    renderHook(() => useAuth())

    expect(mockUseQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['auth', 'currentUser'],
        enabled: false,
        retry: false,
      })
    )
  })
})

describe('useAuth', () => {
  beforeEach(() => {
    mockUseQuery.mockClear()
    mockUseMutation.mockClear()
    mockPush.mockClear()
    mockClear.mockClear()
    mockSetQueryData.mockClear()
    mockRemoveQueries.mockClear()
    mockUseQuery.mockReturnValue({
      data: undefined,
      isLoading: true,
      error: null,
    })
  })

  it('returns initial loading state', () => {
    const { result } = renderHook(() => useAuth())
    expect(result.current.isLoading).toBe(true)
    expect(result.current.user).toBeUndefined()
    expect(result.current.isAuthenticated).toBe(false)
    expect(result.current.isAdmin).toBe(false)
  })

  it('returns isAuthenticated true when user data is present', () => {
    mockUseQuery.mockReturnValueOnce({
      data: { id: '1', email: 'a@b.com', plan: 'ADMIN', created_at: '', updated_at: null },
      isLoading: false,
      error: null,
    })

    const { result } = renderHook(() => useAuth())
    expect(result.current.isAuthenticated).toBe(true)
    expect(result.current.user).toBeDefined()
  })

  it('exposes login and logout functions', () => {
    const { result } = renderHook(() => useAuth())
    expect(typeof result.current.login).toBe('function')
    expect(typeof result.current.logout).toBe('function')
  })

  it('returns isLoggingIn and loginError from mutation', () => {
    const { result } = renderHook(() => useAuth())
    expect(result.current.isLoggingIn).toBe(false)
    expect(result.current.loginError).toBeNull()
  })

  it('useQuery is called with enabled: true when auth cookie is present', () => {
    Object.defineProperty(document, 'cookie', {
      value: 'auth-status=authenticated',
      writable: true,
    })

    renderHook(() => useAuth())

    expect(mockUseQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['auth', 'currentUser'],
        enabled: true,
        retry: false,
      })
    )
  })

  it('useQuery queryFn references authService.getCurrentUser', () => {
    renderHook(() => useAuth())

    const queryOpts = mockUseQuery.mock.calls[0][0]
    expect(queryOpts.queryFn).toBeDefined()
  })

  it('login calls the mutation mutate with credentials', () => {
    const mutateCapture = vi.fn()
    mockUseMutation.mockReturnValueOnce({
      mutate: mutateCapture,
      isPending: false,
      error: null,
    })

    const { result } = renderHook(() => useAuth())
    result.current.login({ email: 'test@test.com', password: 'pw' })
    expect(mutateCapture).toHaveBeenCalledWith({ email: 'test@test.com', password: 'pw' })
  })

  it('useMutation is called with mutationFn and onSuccess', () => {
    renderHook(() => useAuth())
    expect(mockUseMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        mutationFn: expect.any(Function),
        onSuccess: expect.any(Function),
      })
    )
  })

  it('logout calls authService.logout, clears cache, and redirects to /login', async () => {
    const { authService } = await import('@/services')
    vi.mocked(authService.logout).mockResolvedValueOnce(undefined as never)

    const { result } = renderHook(() => useAuth())
    await result.current.logout()

    expect(authService.logout).toHaveBeenCalled()
    expect(mockClear).toHaveBeenCalled()
    expect(mockPush).toHaveBeenCalledWith('/login')
  })

  it('logout still clears and redirects when authService.logout throws', async () => {
    const { authService } = await import('@/services')
    vi.mocked(authService.logout).mockRejectedValueOnce(new Error('network'))

    const { result } = renderHook(() => useAuth())
    await result.current.logout()

    expect(mockClear).toHaveBeenCalled()
    expect(mockPush).toHaveBeenCalledWith('/login')
  })

  it('returns error from useQuery', () => {
    const testError = new Error('query failed')
    mockUseQuery.mockReturnValueOnce({
      data: undefined,
      isLoading: false,
      error: testError,
    })

    const { result } = renderHook(() => useAuth())
    expect(result.current.error).toBe(testError)
  })

  it('isAdmin is false when user plan is PREMIUM', () => {
    mockUseQuery.mockReturnValueOnce({
      data: { id: '3', email: 'p@p.com', plan: 'PREMIUM', created_at: '', updated_at: null },
      isLoading: false,
      error: null,
    })

    const { result } = renderHook(() => useAuth())
    expect(result.current.isAdmin).toBe(false)
  })

  it('isAdmin is false when user is null', () => {
    mockUseQuery.mockReturnValueOnce({
      data: null,
      isLoading: false,
      error: null,
    })

    const { result } = renderHook(() => useAuth())
    expect(result.current.isAdmin).toBe(false)
  })
})
