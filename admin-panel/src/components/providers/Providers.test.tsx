import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'

vi.mock('sonner', () => ({
  Toaster: () => <div data-testid="toaster" />,
}))

vi.mock('./QueryProvider', () => ({
  QueryProvider: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="query-provider">{children}</div>
  ),
}))

vi.mock('./ThemeProvider', () => ({
  ThemeProvider: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="theme-provider">{children}</div>
  ),
}))

vi.mock('@/components/ui/tooltip', () => ({
  TooltipProvider: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="tooltip-provider">{children}</div>
  ),
}))

import { Providers } from './Providers'
import { QueryProvider } from './QueryProvider'
import { ThemeProvider } from './ThemeProvider'

describe('Providers', () => {
  it('renders children', () => {
    render(
      <Providers>
        <div data-testid="child">Hello</div>
      </Providers>
    )

    expect(screen.getByTestId('child')).toBeInTheDocument()
    expect(screen.getByText('Hello')).toBeInTheDocument()
  })

  it('wraps with ThemeProvider', () => {
    render(
      <Providers>
        <div>Content</div>
      </Providers>
    )

    expect(screen.getByTestId('theme-provider')).toBeInTheDocument()
  })

  it('wraps with QueryProvider', () => {
    render(
      <Providers>
        <div>Content</div>
      </Providers>
    )

    expect(screen.getByTestId('query-provider')).toBeInTheDocument()
  })

  it('wraps with TooltipProvider', () => {
    render(
      <Providers>
        <div>Content</div>
      </Providers>
    )

    expect(screen.getByTestId('tooltip-provider')).toBeInTheDocument()
  })
})

describe('QueryProvider', () => {
  it('renders children', () => {
    render(
      <QueryProvider>
        <div data-testid="qp-child">Test</div>
      </QueryProvider>
    )

    expect(screen.getByTestId('qp-child')).toBeInTheDocument()
  })
})

describe('ThemeProvider', () => {
  it('renders children', () => {
    render(
      <ThemeProvider>
        <div data-testid="tp-child">Test</div>
      </ThemeProvider>
    )

    expect(screen.getByTestId('tp-child')).toBeInTheDocument()
  })
})
