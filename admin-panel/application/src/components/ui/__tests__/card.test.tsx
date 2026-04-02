import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '../card'

describe('Card components', () => {
  it('renders Card with correct className', () => {
    render(<Card data-testid="card">Content</Card>)
    const el = screen.getByTestId('card')
    expect(el.className).toContain('rounded-xl')
  })

  it('Card supports custom className', () => {
    render(<Card data-testid="card" className="custom">Content</Card>)
    expect(screen.getByTestId('card').className).toContain('custom')
  })

  it('renders CardHeader', () => {
    render(<CardHeader data-testid="header">Header</CardHeader>)
    const el = screen.getByTestId('header')
    expect(el.className).toContain('p-6')
  })

  it('renders CardTitle', () => {
    render(<CardTitle>Title</CardTitle>)
    expect(screen.getByText('Title')).toBeInTheDocument()
    expect(screen.getByText('Title').className).toContain('font-semibold')
  })

  it('renders CardDescription', () => {
    render(<CardDescription>Desc</CardDescription>)
    expect(screen.getByText('Desc').className).toContain('text-sm')
  })

  it('renders CardContent', () => {
    render(<CardContent data-testid="content">Body</CardContent>)
    expect(screen.getByTestId('content').className).toContain('p-6')
  })

  it('renders CardFooter', () => {
    render(<CardFooter data-testid="footer">Footer</CardFooter>)
    expect(screen.getByTestId('footer').className).toContain('flex')
  })
})
