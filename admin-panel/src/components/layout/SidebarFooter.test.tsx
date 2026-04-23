import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { TooltipProvider } from '@/components/ui/tooltip'

const mockLogout = vi.fn()

let mockUser: { email: string; plan: string } | null = {
  email: 'admin@test.com',
  plan: 'ADMIN',
}

vi.mock('@/hooks', () => ({
  useAuth: () => ({ user: mockUser, logout: mockLogout }),
}))

vi.mock('./UserPill', () => ({
  UserPill: ({ user, collapsed }: { user: { email: string }; collapsed: boolean }) => (
    <div data-testid="user-pill" data-collapsed={collapsed}>
      {user.email}
    </div>
  ),
}))

vi.mock('./ThemeToggle', () => ({
  ThemeToggle: () => <button data-testid="theme-toggle">Theme</button>,
}))

import { SidebarFooter } from './SidebarFooter'

function renderWithProviders(ui: React.ReactElement) {
  return render(<TooltipProvider>{ui}</TooltipProvider>)
}

describe('SidebarFooter', () => {
  beforeEach(() => {
    mockUser = { email: 'admin@test.com', plan: 'ADMIN' }
  })

  it('renders UserPill with user info', () => {
    renderWithProviders(<SidebarFooter collapsed={false} />)
    expect(screen.getByTestId('user-pill')).toBeInTheDocument()
    expect(screen.getByText('admin@test.com')).toBeInTheDocument()
  })

  it('renders ThemeToggle', () => {
    renderWithProviders(<SidebarFooter collapsed={false} />)
    expect(screen.getByTestId('theme-toggle')).toBeInTheDocument()
  })

  it('returns null when user is null', () => {
    mockUser = null
    const { container } = renderWithProviders(<SidebarFooter collapsed={false} />)
    expect(container.innerHTML).toBe('')
  })

  it('passes collapsed prop to UserPill', () => {
    renderWithProviders(<SidebarFooter collapsed={true} />)
    expect(screen.getByTestId('user-pill')).toHaveAttribute('data-collapsed', 'true')
  })
})
