import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { useAuth } from '@/hooks'

vi.mock('@/hooks', () => ({
  useAuth: vi.fn(),
}))

vi.mock('@/stores/useDashboardStore', () => ({
  useDashboardStore: vi.fn(() => ({
    activeTab: 'dashboard',
    setActiveTab: vi.fn(),
  })),
}))

vi.mock('@/features/registry', () => ({
  TAB_REGISTRY: [
    {
      id: 'dashboard',
      name: 'Dashboard',
      component: ({ isActive }: { isActive: boolean }) => (
        <div>Dashboard Content {isActive ? 'active' : ''}</div>
      ),
    },
  ],
}))

import DashboardPage from '../page'

describe('DashboardPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('shows loading spinner when user is null', () => {
    vi.mocked(useAuth).mockReturnValue({
      user: null,
      logout: vi.fn(),
    } as unknown as ReturnType<typeof useAuth>)

    const { container } = render(<DashboardPage />)
    const spinner = container.querySelector('.animate-spin')
    expect(spinner).toBeInTheDocument()
  })

  it('renders dashboard with user email when user exists', () => {
    vi.mocked(useAuth).mockReturnValue({
      user: { email: 'test@test.com' },
      logout: vi.fn(),
    } as unknown as ReturnType<typeof useAuth>)

    render(<DashboardPage />)
    expect(screen.getByText(/test@test.com/)).toBeInTheDocument()
  })

  it('shows logout button', () => {
    vi.mocked(useAuth).mockReturnValue({
      user: { email: 'test@test.com' },
      logout: vi.fn(),
    } as unknown as ReturnType<typeof useAuth>)

    render(<DashboardPage />)
    expect(screen.getByText('Déconnexion')).toBeInTheDocument()
  })

  it('renders tab navigation', () => {
    vi.mocked(useAuth).mockReturnValue({
      user: { email: 'test@test.com' },
      logout: vi.fn(),
    } as unknown as ReturnType<typeof useAuth>)

    render(<DashboardPage />)
    expect(screen.getByText('Dashboard')).toBeInTheDocument()
  })
})
