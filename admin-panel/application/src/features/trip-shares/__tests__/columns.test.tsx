import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { tripSharesColumns } from '../columns'

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

describe('tripSharesColumns', () => {
  it('should have 5 columns', () => {
    expect(tripSharesColumns).toHaveLength(5)
  })

  it('renders id cell with truncated value', () => {
    renderCell(tripSharesColumns, 'id', 'abcdefgh-1234-5678-9012')
    expect(screen.getByText('abcdefgh...')).toBeInTheDocument()
  })

  it('renders trip_title cell with value', () => {
    renderCell(tripSharesColumns, 'trip_title', 'My Trip')
    expect(screen.getByText('My Trip')).toBeInTheDocument()
  })

  it('renders trip_title cell with fallback', () => {
    renderCell(tripSharesColumns, 'trip_title', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders user_email cell', () => {
    renderCell(tripSharesColumns, 'user_email', 'user@test.com')
    expect(screen.getByText('user@test.com')).toBeInTheDocument()
  })

  it('renders role cell', () => {
    renderCell(tripSharesColumns, 'role', 'EDITOR')
    expect(screen.getByText('EDITOR')).toBeInTheDocument()
  })

  it('renders invited_at cell with date', () => {
    const container = renderCell(tripSharesColumns, 'invited_at', '2024-01-15T10:30:00Z')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })

  it('renders invited_at cell with null', () => {
    const container = renderCell(tripSharesColumns, 'invited_at', null)
    expect(container?.querySelector('span')).toBeInTheDocument()
  })
})
