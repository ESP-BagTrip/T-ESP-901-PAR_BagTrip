import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { QueryProvider } from '../QueryProvider'

describe('QueryProvider', () => {
  it('renders children', () => {
    render(
      <QueryProvider>
        <div>Child content</div>
      </QueryProvider>
    )
    expect(screen.getByText('Child content')).toBeInTheDocument()
  })
})
