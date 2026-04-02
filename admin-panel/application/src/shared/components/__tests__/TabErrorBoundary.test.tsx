import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { TabErrorBoundary } from '../TabErrorBoundary'

function ThrowingComponent() {
  throw new Error('test error')
  return null
}

describe('TabErrorBoundary', () => {
  let consoleError: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    consoleError = vi.spyOn(console, 'error').mockImplementation(() => {})
  })

  afterEach(() => {
    consoleError.mockRestore()
  })

  it('renders children when no error', () => {
    render(
      <TabErrorBoundary tabName="Test">
        <div>Child content</div>
      </TabErrorBoundary>
    )
    expect(screen.getByText('Child content')).toBeInTheDocument()
  })

  it('shows error message when child throws', () => {
    render(
      <TabErrorBoundary tabName="Test">
        <ThrowingComponent />
      </TabErrorBoundary>
    )
    expect(screen.getByText(/Erreur dans l'onglet Test/)).toBeInTheDocument()
    expect(screen.getByText('test error')).toBeInTheDocument()
  })

  it('retry button resets error state', () => {
    const { rerender } = render(
      <TabErrorBoundary tabName="Test">
        <ThrowingComponent />
      </TabErrorBoundary>
    )
    expect(screen.getByText(/Erreur dans l'onglet Test/)).toBeInTheDocument()

    fireEvent.click(screen.getByText('Réessayer'))
    // After reset, it will try to render children again, which will throw again
    expect(screen.getByText(/Erreur dans l'onglet Test/)).toBeInTheDocument()
  })
})
