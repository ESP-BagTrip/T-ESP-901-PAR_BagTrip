import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { Providers } from '../Providers'

describe('Providers', () => {
  it('renders children', () => {
    render(
      <Providers>
        <div>Child content</div>
      </Providers>
    )
    expect(screen.getByText('Child content')).toBeInTheDocument()
  })
})
