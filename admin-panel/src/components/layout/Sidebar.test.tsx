import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen } from '@testing-library/react'
import { TooltipProvider } from '@/components/ui/tooltip'

vi.mock('next/navigation', () => ({
  usePathname: () => '/app',
}))

vi.mock('next/link', () => ({
  default: ({
    children,
    href,
    ...props
  }: {
    children: React.ReactNode
    href: string
    [key: string]: unknown
  }) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
}))

const mockToggle = vi.fn()
let mockCollapsed = false

vi.mock('@/stores/useUIStore', () => ({
  useUIStore: (selector: (s: { sidebarCollapsed: boolean; toggleSidebarCollapsed: () => void }) => unknown) =>
    selector({ sidebarCollapsed: mockCollapsed, toggleSidebarCollapsed: mockToggle }),
}))

vi.mock('@/config/navigation', () => ({
  NAV_SECTIONS: [
    {
      label: 'Main',
      items: [
        {
          href: '/app',
          label: 'Overview',
          icon: () => <span data-testid="icon-overview" />,
          keywords: ['home'],
        },
        {
          href: '/app/users',
          label: 'Utilisateurs',
          icon: () => <span data-testid="icon-users" />,
          keywords: ['users'],
        },
      ],
    },
  ],
  SECONDARY_NAV: [
    {
      href: '/app/settings',
      label: 'Paramètres',
      icon: () => <span data-testid="icon-settings" />,
      keywords: ['settings'],
    },
  ],
}))

vi.mock('./SidebarFooter', () => ({
  SidebarFooter: ({ collapsed }: { collapsed: boolean }) => (
    <div data-testid="sidebar-footer" data-collapsed={collapsed} />
  ),
}))

import { Sidebar } from './Sidebar'

function renderWithProviders(ui: React.ReactElement) {
  return render(<TooltipProvider>{ui}</TooltipProvider>)
}

describe('Sidebar', () => {
  const onOpenCommandPalette = vi.fn()

  beforeEach(() => {
    mockCollapsed = false
    vi.clearAllMocks()
  })

  it('renders navigation items', () => {
    renderWithProviders(<Sidebar onOpenCommandPalette={onOpenCommandPalette} />)
    expect(screen.getByText('Overview')).toBeInTheDocument()
    expect(screen.getByText('Utilisateurs')).toBeInTheDocument()
    expect(screen.getByText('Paramètres')).toBeInTheDocument()
  })

  it('renders the BagTrip brand when expanded', () => {
    renderWithProviders(<Sidebar onOpenCommandPalette={onOpenCommandPalette} />)
    expect(screen.getByText('BagTrip')).toBeInTheDocument()
    expect(screen.getByText('Admin')).toBeInTheDocument()
  })

  it('renders SidebarFooter', () => {
    renderWithProviders(<Sidebar onOpenCommandPalette={onOpenCommandPalette} />)
    expect(screen.getByTestId('sidebar-footer')).toBeInTheDocument()
  })
})
