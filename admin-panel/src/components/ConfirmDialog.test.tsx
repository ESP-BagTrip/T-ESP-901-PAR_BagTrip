import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { ConfirmDialog } from './ConfirmDialog'

describe('ConfirmDialog', () => {
  const defaultProps = {
    open: true,
    onOpenChange: vi.fn(),
    title: 'Delete item?',
    description: 'This action cannot be undone.',
    onConfirm: vi.fn(),
  }

  it('renders title and description when open', () => {
    render(<ConfirmDialog {...defaultProps} />)

    expect(screen.getByText('Delete item?')).toBeInTheDocument()
    expect(screen.getByText('This action cannot be undone.')).toBeInTheDocument()
  })

  it('does not render content when closed', () => {
    render(<ConfirmDialog {...defaultProps} open={false} />)

    expect(screen.queryByText('Delete item?')).not.toBeInTheDocument()
  })

  it('renders default button labels', () => {
    render(<ConfirmDialog {...defaultProps} />)

    expect(screen.getByText('Confirmer')).toBeInTheDocument()
    expect(screen.getByText('Annuler')).toBeInTheDocument()
  })

  it('renders custom button labels', () => {
    render(<ConfirmDialog {...defaultProps} confirmLabel="Yes, delete" cancelLabel="No, keep" />)

    expect(screen.getByText('Yes, delete')).toBeInTheDocument()
    expect(screen.getByText('No, keep')).toBeInTheDocument()
  })

  it('calls onConfirm when confirm button clicked', () => {
    const onConfirm = vi.fn()
    render(<ConfirmDialog {...defaultProps} onConfirm={onConfirm} />)

    fireEvent.click(screen.getByText('Confirmer'))
    expect(onConfirm).toHaveBeenCalledOnce()
  })

  it('disables buttons when isPending', () => {
    render(<ConfirmDialog {...defaultProps} isPending={true} />)

    expect(screen.getByText('Confirmer').closest('button')).toBeDisabled()
    expect(screen.getByText('Annuler').closest('button')).toBeDisabled()
  })

  it('shows loader icon when isPending', () => {
    const { container } = render(<ConfirmDialog {...defaultProps} isPending={true} />)

    // Loader2 renders an SVG — check for svg element inside the confirm button
    const confirmBtn = screen.getByText('Confirmer').closest('button')!
    const svg = confirmBtn.querySelector('svg')
    expect(svg).toBeInTheDocument()
  })
})
