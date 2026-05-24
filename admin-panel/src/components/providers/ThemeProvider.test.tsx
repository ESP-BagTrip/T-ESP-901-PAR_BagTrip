import { render, screen } from '@testing-library/react'

vi.mock('next-themes', () => ({
  ThemeProvider: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}))

import { ThemeProvider } from './ThemeProvider'

describe('ThemeProvider', () => {
  it('renders children', () => {
    render(
      <ThemeProvider>
        <div data-testid="child">Theme content</div>
      </ThemeProvider>
    )
    expect(screen.getByTestId('child')).toBeInTheDocument()
    expect(screen.getByText('Theme content')).toBeInTheDocument()
  })
})
