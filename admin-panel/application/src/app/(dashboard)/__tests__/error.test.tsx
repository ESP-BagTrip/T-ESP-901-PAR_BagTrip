import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import DashboardError from '../error'

describe('DashboardError', () => {
  it('renders dashboard error message', () => {
    const error = new Error('Dashboard failed')
    render(<DashboardError error={error} reset={vi.fn()} />)
    expect(screen.getByText('Erreur du tableau de bord')).toBeInTheDocument()
    expect(screen.getByText('Dashboard failed')).toBeInTheDocument()
  })

  it('calls reset on button click', () => {
    const reset = vi.fn()
    const error = new Error('fail')
    render(<DashboardError error={error} reset={reset} />)
    fireEvent.click(screen.getByText('Réessayer'))
    expect(reset).toHaveBeenCalledTimes(1)
  })
})
