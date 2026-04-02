import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { feedbacksColumns } from '../columns'

function renderCell(columns: any[], accessorKey: string, value: any) {
  const col = columns.find((c: any) => c.accessorKey === accessorKey)
  if (!col?.cell) return null
  const mockRow = {
    getValue: (key: string) => (key === accessorKey ? value : undefined),
    original: {},
  }
  const { container } = render(<>{(col.cell as Function)({ row: mockRow })}</>)
  return container
}

describe('feedbacksColumns', () => {
  it('should have 8 columns', () => {
    expect(feedbacksColumns).toHaveLength(8)
  })

  it('renders id cell with truncated value', () => {
    renderCell(feedbacksColumns, 'id', 'abcdefgh-1234-5678-9012')
    expect(screen.getByText('abcdefgh...')).toBeInTheDocument()
  })

  it('renders trip_title cell with value', () => {
    renderCell(feedbacksColumns, 'trip_title', 'Trip Paris')
    expect(screen.getByText('Trip Paris')).toBeInTheDocument()
  })

  it('renders trip_title cell with fallback', () => {
    renderCell(feedbacksColumns, 'trip_title', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders user_email cell', () => {
    renderCell(feedbacksColumns, 'user_email', 'user@test.com')
    expect(screen.getByText('user@test.com')).toBeInTheDocument()
  })

  it('renders overall_rating cell with stars', () => {
    renderCell(feedbacksColumns, 'overall_rating', 3)
    expect(screen.getByText('★★★☆☆')).toBeInTheDocument()
  })

  it('renders overall_rating cell with 5 stars', () => {
    renderCell(feedbacksColumns, 'overall_rating', 5)
    expect(screen.getByText('★★★★★')).toBeInTheDocument()
  })

  it('renders highlights cell with text', () => {
    renderCell(feedbacksColumns, 'highlights', 'Great views')
    expect(screen.getByText('Great views')).toBeInTheDocument()
  })

  it('renders highlights cell with null', () => {
    renderCell(feedbacksColumns, 'highlights', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders lowlights cell with text', () => {
    renderCell(feedbacksColumns, 'lowlights', 'Too crowded')
    expect(screen.getByText('Too crowded')).toBeInTheDocument()
  })

  it('renders lowlights cell with null', () => {
    renderCell(feedbacksColumns, 'lowlights', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders would_recommend cell true', () => {
    renderCell(feedbacksColumns, 'would_recommend', true)
    expect(screen.getByText('Oui')).toBeInTheDocument()
  })

  it('renders would_recommend cell false', () => {
    renderCell(feedbacksColumns, 'would_recommend', false)
    expect(screen.getByText('Non')).toBeInTheDocument()
  })

  it('renders created_at cell', () => {
    const container = renderCell(feedbacksColumns, 'created_at', '2024-01-15T10:30:00Z')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })
})
