import { render, screen } from '@testing-library/react'
import { useQueryClient } from '@tanstack/react-query'
import { QueryProvider } from './QueryProvider'

function TestConsumer() {
  const client = useQueryClient()
  return <div data-testid="has-client">{client ? 'yes' : 'no'}</div>
}

describe('QueryProvider', () => {
  it('renders children', () => {
    render(
      <QueryProvider>
        <div data-testid="child">Content</div>
      </QueryProvider>
    )
    expect(screen.getByTestId('child')).toBeInTheDocument()
  })

  it('provides query client context', () => {
    render(
      <QueryProvider>
        <TestConsumer />
      </QueryProvider>
    )
    expect(screen.getByTestId('has-client')).toHaveTextContent('yes')
  })
})
