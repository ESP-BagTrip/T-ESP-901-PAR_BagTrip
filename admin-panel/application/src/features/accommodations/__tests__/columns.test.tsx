import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { accommodationsColumns } from '../columns'

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

describe('accommodationsColumns', () => {
  it('should have 8 columns', () => {
    expect(accommodationsColumns).toHaveLength(8)
  })

  it('renders id cell with truncated value', () => {
    renderCell(accommodationsColumns, 'id', 'abcdefgh-1234-5678-9012')
    expect(screen.getByText('abcdefgh...')).toBeInTheDocument()
  })

  it('renders trip_title cell with value', () => {
    renderCell(accommodationsColumns, 'trip_title', 'My Trip')
    expect(screen.getByText('My Trip')).toBeInTheDocument()
  })

  it('renders trip_title cell with fallback', () => {
    renderCell(accommodationsColumns, 'trip_title', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders user_email cell', () => {
    renderCell(accommodationsColumns, 'user_email', 'test@example.com')
    expect(screen.getByText('test@example.com')).toBeInTheDocument()
  })

  it('renders name cell', () => {
    renderCell(accommodationsColumns, 'name', 'Hotel Paris')
    expect(screen.getByText('Hotel Paris')).toBeInTheDocument()
  })

  it('renders check_in cell with date', () => {
    const container = renderCell(accommodationsColumns, 'check_in', '2024-01-15')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })

  it('renders check_in cell with null', () => {
    const container = renderCell(accommodationsColumns, 'check_in', null)
    expect(container?.querySelector('span')).toBeInTheDocument()
  })

  it('renders check_out cell with date', () => {
    const container = renderCell(accommodationsColumns, 'check_out', '2024-01-20')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })

  it('renders price_per_night cell with value', () => {
    renderCell(accommodationsColumns, 'price_per_night', 99.5)
    expect(screen.getByText('99.50 €')).toBeInTheDocument()
  })

  it('renders price_per_night cell with null', () => {
    renderCell(accommodationsColumns, 'price_per_night', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders created_at cell', () => {
    const container = renderCell(accommodationsColumns, 'created_at', '2024-01-15T10:30:00Z')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })
})
