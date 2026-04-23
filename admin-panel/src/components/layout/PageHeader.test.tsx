import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { PageHeader } from './PageHeader'

describe('PageHeader', () => {
  it('renders title', () => {
    render(<PageHeader title="Users" />)
    expect(screen.getByText('Users')).toBeInTheDocument()
  })

  it('renders title as h1', () => {
    render(<PageHeader title="Users" />)
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('Users')
  })

  it('renders description when provided', () => {
    render(<PageHeader title="Users" description="Manage all users" />)
    expect(screen.getByText('Manage all users')).toBeInTheDocument()
  })

  it('does not render description when not provided', () => {
    const { container } = render(<PageHeader title="Users" />)
    const paragraphs = container.querySelectorAll('p')
    expect(paragraphs).toHaveLength(0)
  })

  it('renders actions slot', () => {
    render(<PageHeader title="Users" actions={<button>Add user</button>} />)
    expect(screen.getByText('Add user')).toBeInTheDocument()
  })

  it('applies custom className', () => {
    render(<PageHeader title="Users" className="custom-class" />)
    const header = screen.getByRole('banner')
    expect(header.className).toContain('custom-class')
  })
})
