import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'

const mockReplace = vi.fn()
const mockLogout = vi.fn()

vi.mock('next/navigation', () => ({
  useRouter: () => ({ replace: mockReplace }),
}))

let mockAuth = {
  user: { email: 'admin@test.com', plan: 'ADMIN' } as { email: string; plan: string } | null,
  isLoading: false,
  isAuthenticated: true,
  isAdmin: true,
  logout: mockLogout,
}

vi.mock('@/hooks', () => ({
  useAuth: () => mockAuth,
}))

import { AuthGuard } from './AuthGuard'

describe('AuthGuard', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockAuth = {
      user: { email: 'admin@test.com', plan: 'ADMIN' },
      isLoading: false,
      isAuthenticated: true,
      isAdmin: true,
      logout: mockLogout,
    }
  })

  it('renders children when user is authenticated and admin', () => {
    render(
      <AuthGuard>
        <p>Protected content</p>
      </AuthGuard>
    )
    expect(screen.getByText('Protected content')).toBeInTheDocument()
  })

  it('shows loading spinner when isLoading is true', () => {
    mockAuth = { ...mockAuth, isLoading: true, user: null }
    const { container } = render(
      <AuthGuard>
        <p>Protected content</p>
      </AuthGuard>
    )
    expect(container.querySelector('.animate-spin')).toBeInTheDocument()
    expect(screen.queryByText('Protected content')).not.toBeInTheDocument()
  })

  it('redirects to /login when not authenticated', () => {
    mockAuth = { ...mockAuth, isAuthenticated: false, user: null, isAdmin: false }
    render(
      <AuthGuard>
        <p>Protected content</p>
      </AuthGuard>
    )
    expect(mockReplace).toHaveBeenCalledWith('/login')
  })

  it('calls logout when user is not admin', () => {
    mockAuth = {
      ...mockAuth,
      isAdmin: false,
      user: { email: 'user@test.com', plan: 'FREE' },
    }
    render(
      <AuthGuard>
        <p>Protected content</p>
      </AuthGuard>
    )
    expect(mockLogout).toHaveBeenCalled()
  })
})
