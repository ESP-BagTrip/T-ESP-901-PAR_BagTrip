import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { tripsColumns } from '../columns'

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

describe('tripsColumns', () => {
  it('should have 9 columns', () => {
    expect(tripsColumns).toHaveLength(9)
  })

  it('renders id cell with truncated value', () => {
    renderCell(tripsColumns, 'id', 'abcdefgh-1234-5678-9012')
    expect(screen.getByText('abcdefgh...')).toBeInTheDocument()
  })

  it('renders user_email cell', () => {
    renderCell(tripsColumns, 'user_email', 'user@test.com')
    expect(screen.getByText('user@test.com')).toBeInTheDocument()
  })

  it('renders title cell with value', () => {
    renderCell(tripsColumns, 'title', 'Paris Vacation')
    expect(screen.getByText('Paris Vacation')).toBeInTheDocument()
  })

  it('renders title cell with null', () => {
    renderCell(tripsColumns, 'title', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders origin_iata cell with value', () => {
    renderCell(tripsColumns, 'origin_iata', 'CDG')
    expect(screen.getByText('CDG')).toBeInTheDocument()
  })

  it('renders origin_iata cell with null', () => {
    renderCell(tripsColumns, 'origin_iata', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders destination_iata cell with value', () => {
    renderCell(tripsColumns, 'destination_iata', 'JFK')
    expect(screen.getByText('JFK')).toBeInTheDocument()
  })

  it('renders destination_iata cell with null', () => {
    renderCell(tripsColumns, 'destination_iata', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders start_date cell', () => {
    const container = renderCell(tripsColumns, 'start_date', '2024-06-15')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })

  it('renders end_date cell', () => {
    const container = renderCell(tripsColumns, 'end_date', '2024-06-20')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })

  it('renders status cell with DRAFT', () => {
    renderCell(tripsColumns, 'status', 'DRAFT')
    expect(screen.getByText('DRAFT')).toBeInTheDocument()
  })

  it('renders status cell with ONGOING', () => {
    renderCell(tripsColumns, 'status', 'ONGOING')
    expect(screen.getByText('ONGOING')).toBeInTheDocument()
  })

  it('renders status cell with COMPLETED', () => {
    renderCell(tripsColumns, 'status', 'COMPLETED')
    expect(screen.getByText('COMPLETED')).toBeInTheDocument()
  })

  it('renders status cell with null', () => {
    renderCell(tripsColumns, 'status', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders created_at cell', () => {
    const container = renderCell(tripsColumns, 'created_at', '2024-01-15T10:30:00Z')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })
})
