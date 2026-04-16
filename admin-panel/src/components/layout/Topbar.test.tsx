import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'

vi.mock('./Breadcrumb', () => ({
  Breadcrumb: () => <nav data-testid="breadcrumb">Breadcrumb</nav>,
}))

import { Topbar } from './Topbar'

describe('Topbar', () => {
  it('renders breadcrumb navigation', () => {
    render(<Topbar />)
    expect(screen.getByTestId('breadcrumb')).toBeInTheDocument()
  })

  it('renders with header element', () => {
    const { container } = render(<Topbar />)
    expect(container.querySelector('header')).toBeInTheDocument()
  })
})
