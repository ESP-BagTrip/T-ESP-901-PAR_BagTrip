import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import GlobalError from '../error'

describe('GlobalError', () => {
  it('renders error message', () => {
    const error = new Error('Something broke')
    render(<GlobalError error={error} reset={vi.fn()} />)
    expect(screen.getByText('Une erreur est survenue')).toBeInTheDocument()
    expect(screen.getByText('Something broke')).toBeInTheDocument()
  })

  it('calls reset on button click', () => {
    const reset = vi.fn()
    const error = new Error('fail')
    render(<GlobalError error={error} reset={reset} />)
    fireEvent.click(screen.getByText('Réessayer'))
    expect(reset).toHaveBeenCalledTimes(1)
  })
})
