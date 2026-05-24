import { describe, it, expect, vi, beforeAll } from 'vitest'
import { render, screen } from '@testing-library/react'

// cmdk uses ResizeObserver and scrollIntoView internally
beforeAll(() => {
  globalThis.ResizeObserver = class {
    observe() {}
    unobserve() {}
    disconnect() {}
  } as unknown as typeof ResizeObserver
  Element.prototype.scrollIntoView = vi.fn()
})

vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: vi.fn() }),
}))

vi.mock('next-themes', () => ({
  useTheme: () => ({ theme: 'light', setTheme: vi.fn() }),
}))

vi.mock('@/hooks', () => ({
  useAuth: () => ({ logout: vi.fn() }),
}))

vi.mock('@/config/navigation', () => ({
  NAV_SECTIONS: [
    {
      label: 'Test Section',
      items: [
        {
          href: '/app',
          label: 'Overview',
          icon: () => <span data-testid="icon" />,
          keywords: ['home'],
        },
      ],
    },
  ],
  SECONDARY_NAV: [
    {
      href: '/app/settings',
      label: 'Paramètres',
      icon: () => <span data-testid="icon" />,
      keywords: ['settings'],
    },
  ],
}))

import { CommandPalette } from './CommandPalette'

describe('CommandPalette', () => {
  it('renders without crashing when open', () => {
    render(<CommandPalette open={true} onOpenChange={vi.fn()} />)
    expect(screen.getByPlaceholderText(/tapez une commande/i)).toBeInTheDocument()
  })

  it('shows nav items when open', () => {
    render(<CommandPalette open={true} onOpenChange={vi.fn()} />)
    expect(screen.getByText('Overview')).toBeInTheDocument()
    expect(screen.getByText('Paramètres')).toBeInTheDocument()
  })

  it('does not render dialog content when closed', () => {
    render(<CommandPalette open={false} onOpenChange={vi.fn()} />)
    expect(screen.queryByPlaceholderText(/tapez une commande/i)).not.toBeInTheDocument()
  })
})
