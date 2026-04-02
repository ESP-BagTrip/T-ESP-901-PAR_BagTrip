import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import AuthError from '../error'

describe('AuthError', () => {
  it('renders auth error message', () => {
    const error = new Error('Auth failed')
    render(<AuthError error={error} reset={vi.fn()} />)
    expect(screen.getByText("Erreur d'authentification")).toBeInTheDocument()
    expect(screen.getByText('Auth failed')).toBeInTheDocument()
  })

  it('calls reset on button click', () => {
    const reset = vi.fn()
    const error = new Error('fail')
    render(<AuthError error={error} reset={reset} />)
    fireEvent.click(screen.getByText('Réessayer'))
    expect(reset).toHaveBeenCalledTimes(1)
  })
})
