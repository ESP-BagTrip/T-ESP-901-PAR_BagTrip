import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { Input } from '../input'

describe('Input', () => {
  it('renders an input element', () => {
    render(<Input data-testid="input" />)
    expect(screen.getByTestId('input').tagName).toBe('INPUT')
  })

  it('supports type prop', () => {
    render(<Input type="email" data-testid="input" />)
    expect(screen.getByTestId('input')).toHaveAttribute('type', 'email')
  })

  it('supports custom className', () => {
    render(<Input className="custom-class" data-testid="input" />)
    expect(screen.getByTestId('input').className).toContain('custom-class')
  })

  it('handles onChange', () => {
    const onChange = vi.fn()
    render(<Input onChange={onChange} data-testid="input" />)
    fireEvent.change(screen.getByTestId('input'), { target: { value: 'hello' } })
    expect(onChange).toHaveBeenCalled()
  })
})
