import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { baggageItemsColumns } from '../columns'

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

describe('baggageItemsColumns', () => {
  it('should have 8 columns', () => {
    expect(baggageItemsColumns).toHaveLength(8)
  })

  it('renders id cell with truncated value', () => {
    renderCell(baggageItemsColumns, 'id', 'abcdefgh-1234-5678-9012')
    expect(screen.getByText('abcdefgh...')).toBeInTheDocument()
  })

  it('renders trip_title cell with value', () => {
    renderCell(baggageItemsColumns, 'trip_title', 'My Trip')
    expect(screen.getByText('My Trip')).toBeInTheDocument()
  })

  it('renders trip_title cell with fallback', () => {
    renderCell(baggageItemsColumns, 'trip_title', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders user_email cell', () => {
    renderCell(baggageItemsColumns, 'user_email', 'user@test.com')
    expect(screen.getByText('user@test.com')).toBeInTheDocument()
  })

  it('renders name cell', () => {
    renderCell(baggageItemsColumns, 'name', 'Passport')
    expect(screen.getByText('Passport')).toBeInTheDocument()
  })

  it('renders category cell with value', () => {
    renderCell(baggageItemsColumns, 'category', 'Documents')
    expect(screen.getByText('Documents')).toBeInTheDocument()
  })

  it('renders category cell with fallback', () => {
    renderCell(baggageItemsColumns, 'category', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders quantity cell with value', () => {
    renderCell(baggageItemsColumns, 'quantity', 3)
    expect(screen.getByText('3')).toBeInTheDocument()
  })

  it('renders quantity cell with null defaults to 1', () => {
    renderCell(baggageItemsColumns, 'quantity', null)
    expect(screen.getByText('1')).toBeInTheDocument()
  })

  it('renders is_packed cell true', () => {
    renderCell(baggageItemsColumns, 'is_packed', true)
    expect(screen.getByText('Oui')).toBeInTheDocument()
  })

  it('renders is_packed cell false', () => {
    renderCell(baggageItemsColumns, 'is_packed', false)
    expect(screen.getByText('Non')).toBeInTheDocument()
  })

  it('renders created_at cell', () => {
    const container = renderCell(baggageItemsColumns, 'created_at', '2024-01-15T10:30:00Z')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })
})
