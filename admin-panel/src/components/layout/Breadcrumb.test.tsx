import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'

let mockPathname = '/app'

vi.mock('next/navigation', () => ({
  usePathname: () => mockPathname,
}))

vi.mock('next/link', () => ({
  default: ({ children, href }: { children: React.ReactNode; href: string }) => (
    <a href={href}>{children}</a>
  ),
}))

vi.mock('@/config/navigation', () => ({
  findNavItem: (pathname: string) => {
    const items: Record<string, { href: string; label: string }> = {
      '/app/users': { href: '/app/users', label: 'Utilisateurs' },
      '/app/trips': { href: '/app/trips', label: 'Voyages' },
    }
    // Exact match first
    if (items[pathname]) return items[pathname]
    // Prefix match for sub-paths like /app/trips/123
    for (const [key, value] of Object.entries(items)) {
      if (pathname.startsWith(`${key}/`)) return value
    }
    return undefined
  },
}))

import { Breadcrumb } from './Breadcrumb'

describe('Breadcrumb', () => {
  it('renders just Overview for /app', () => {
    mockPathname = '/app'
    render(<Breadcrumb />)
    expect(screen.getByText('Overview')).toBeInTheDocument()
  })

  it('renders Overview and Utilisateurs for /app/users', () => {
    mockPathname = '/app/users'
    render(<Breadcrumb />)
    expect(screen.getByText('Overview')).toBeInTheDocument()
    expect(screen.getByText('Utilisateurs')).toBeInTheDocument()
  })

  it('renders Overview and Voyages for /app/trips', () => {
    mockPathname = '/app/trips'
    render(<Breadcrumb />)
    expect(screen.getByText('Overview')).toBeInTheDocument()
    expect(screen.getByText('Voyages')).toBeInTheDocument()
  })

  it('renders Overview and Voyages for /app/trips/123 (sub-path)', () => {
    mockPathname = '/app/trips/123'
    render(<Breadcrumb />)
    expect(screen.getByText('Overview')).toBeInTheDocument()
    expect(screen.getByText('Voyages')).toBeInTheDocument()
  })

  it('falls back to pathname when no nav item matches', () => {
    mockPathname = '/app/unknown-page'
    render(<Breadcrumb />)
    expect(screen.getByText('Overview')).toBeInTheDocument()
    expect(screen.getByText('/app/unknown-page')).toBeInTheDocument()
  })

  it('renders Overview link pointing to /app', () => {
    mockPathname = '/app/users'
    render(<Breadcrumb />)
    const overviewLink = screen.getByText('Overview').closest('a')
    expect(overviewLink).toHaveAttribute('href', '/app')
  })
})
