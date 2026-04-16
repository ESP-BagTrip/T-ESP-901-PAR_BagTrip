import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'

vi.mock('@/stores/useUIStore', () => ({
  useUIStore: () => false,
}))

vi.mock('./Sidebar', () => ({
  Sidebar: ({ onOpenCommandPalette }: { onOpenCommandPalette: () => void }) => (
    <aside data-testid="sidebar" onClick={onOpenCommandPalette} />
  ),
}))

vi.mock('./Topbar', () => ({
  Topbar: () => <header data-testid="topbar" />,
}))

vi.mock('./CommandPalette', () => ({
  CommandPalette: ({ open }: { open: boolean }) => (
    <div data-testid="command-palette" data-open={open} />
  ),
}))

import { AppShell } from './AppShell'

describe('AppShell', () => {
  it('renders children inside the main content area', () => {
    render(
      <AppShell>
        <p>Dashboard content</p>
      </AppShell>
    )
    expect(screen.getByText('Dashboard content')).toBeInTheDocument()
  })

  it('renders Sidebar, Topbar and CommandPalette', () => {
    render(
      <AppShell>
        <p>Content</p>
      </AppShell>
    )
    expect(screen.getByTestId('sidebar')).toBeInTheDocument()
    expect(screen.getByTestId('topbar')).toBeInTheDocument()
    expect(screen.getByTestId('command-palette')).toBeInTheDocument()
  })
})
