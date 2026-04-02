import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { travelersColumns } from '../columns'

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

describe('travelersColumns', () => {
  it('should have 9 columns', () => {
    expect(travelersColumns).toHaveLength(9)
  })

  it('renders id cell with truncated value', () => {
    renderCell(travelersColumns, 'id', 'abcdefgh-1234-5678-9012')
    expect(screen.getByText('abcdefgh...')).toBeInTheDocument()
  })

  it('renders trip_title cell with value', () => {
    renderCell(travelersColumns, 'trip_title', 'My Trip')
    expect(screen.getByText('My Trip')).toBeInTheDocument()
  })

  it('renders trip_title cell with fallback', () => {
    renderCell(travelersColumns, 'trip_title', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders user_email cell', () => {
    renderCell(travelersColumns, 'user_email', 'user@test.com')
    expect(screen.getByText('user@test.com')).toBeInTheDocument()
  })

  it('renders first_name cell', () => {
    renderCell(travelersColumns, 'first_name', 'Jean')
    expect(screen.getByText('Jean')).toBeInTheDocument()
  })

  it('renders last_name cell', () => {
    renderCell(travelersColumns, 'last_name', 'Dupont')
    expect(screen.getByText('Dupont')).toBeInTheDocument()
  })

  it('renders traveler_type cell with ADULT', () => {
    renderCell(travelersColumns, 'traveler_type', 'ADULT')
    expect(screen.getByText('ADULT')).toBeInTheDocument()
  })

  it('renders traveler_type cell with CHILD', () => {
    renderCell(travelersColumns, 'traveler_type', 'CHILD')
    expect(screen.getByText('CHILD')).toBeInTheDocument()
  })

  it('renders traveler_type cell with INFANT', () => {
    renderCell(travelersColumns, 'traveler_type', 'INFANT')
    expect(screen.getByText('INFANT')).toBeInTheDocument()
  })

  it('renders traveler_type cell with unknown type', () => {
    renderCell(travelersColumns, 'traveler_type', 'SENIOR')
    expect(screen.getByText('SENIOR')).toBeInTheDocument()
  })

  it('renders date_of_birth cell', () => {
    const container = renderCell(travelersColumns, 'date_of_birth', '1990-05-15')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })

  it('renders date_of_birth cell with null', () => {
    const container = renderCell(travelersColumns, 'date_of_birth', null)
    expect(container?.querySelector('span')).toBeInTheDocument()
  })

  it('renders gender cell with value', () => {
    renderCell(travelersColumns, 'gender', 'MALE')
    expect(screen.getByText('MALE')).toBeInTheDocument()
  })

  it('renders gender cell with null', () => {
    renderCell(travelersColumns, 'gender', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders created_at cell', () => {
    const container = renderCell(travelersColumns, 'created_at', '2024-01-15T10:30:00Z')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })
})
