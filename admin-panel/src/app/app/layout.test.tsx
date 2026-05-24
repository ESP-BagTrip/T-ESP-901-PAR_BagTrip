import { render, screen } from '@testing-library/react'

vi.mock('@/components/layout/AuthGuard', () => ({
  AuthGuard: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="auth-guard">{children}</div>
  ),
}))
vi.mock('@/components/layout/AppShell', () => ({
  AppShell: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-shell">{children}</div>
  ),
}))

import AppLayout from './layout'

describe('AppLayout', () => {
  it('renders children within AuthGuard and AppShell', () => {
    render(
      <AppLayout>
        <div data-testid="child-content">Hello</div>
      </AppLayout>
    )
    expect(screen.getByTestId('auth-guard')).toBeInTheDocument()
    expect(screen.getByTestId('app-shell')).toBeInTheDocument()
    expect(screen.getByTestId('child-content')).toBeInTheDocument()
  })
})
