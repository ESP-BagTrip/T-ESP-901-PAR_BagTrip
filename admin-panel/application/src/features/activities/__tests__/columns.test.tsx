import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { activitiesColumns } from '../columns'

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

describe('activitiesColumns', () => {
  it('should have 9 columns', () => {
    expect(activitiesColumns).toHaveLength(9)
  })

  it('renders id cell with truncated value', () => {
    renderCell(activitiesColumns, 'id', 'abcdefgh-1234-5678-9012')
    expect(screen.getByText('abcdefgh...')).toBeInTheDocument()
  })

  it('renders trip_title cell with value', () => {
    renderCell(activitiesColumns, 'trip_title', 'My Trip')
    expect(screen.getByText('My Trip')).toBeInTheDocument()
  })

  it('renders trip_title cell with fallback', () => {
    renderCell(activitiesColumns, 'trip_title', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders user_email cell', () => {
    renderCell(activitiesColumns, 'user_email', 'user@test.com')
    expect(screen.getByText('user@test.com')).toBeInTheDocument()
  })

  it('renders title cell', () => {
    renderCell(activitiesColumns, 'title', 'Eiffel Tower Visit')
    expect(screen.getByText('Eiffel Tower Visit')).toBeInTheDocument()
  })

  it('renders date cell', () => {
    const container = renderCell(activitiesColumns, 'date', '2024-03-20')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })

  it('renders category cell with known category', () => {
    renderCell(activitiesColumns, 'category', 'VISIT')
    expect(screen.getByText('VISIT')).toBeInTheDocument()
  })

  it('renders category cell with RESTAURANT', () => {
    renderCell(activitiesColumns, 'category', 'RESTAURANT')
    expect(screen.getByText('RESTAURANT')).toBeInTheDocument()
  })

  it('renders category cell with unknown category', () => {
    renderCell(activitiesColumns, 'category', 'UNKNOWN')
    expect(screen.getByText('UNKNOWN')).toBeInTheDocument()
  })

  it('renders estimated_cost cell with value', () => {
    const container = renderCell(activitiesColumns, 'estimated_cost', 25.5)
    expect(container?.textContent).toBe('25.50 €')
  })

  it('renders estimated_cost cell with null', () => {
    const container = renderCell(activitiesColumns, 'estimated_cost', null)
    expect(container?.textContent).toBe('—')
  })

  it('renders is_booked cell true', () => {
    renderCell(activitiesColumns, 'is_booked', true)
    expect(screen.getByText('Oui')).toBeInTheDocument()
  })

  it('renders is_booked cell false', () => {
    renderCell(activitiesColumns, 'is_booked', false)
    expect(screen.getByText('Non')).toBeInTheDocument()
  })

  it('renders created_at cell', () => {
    const container = renderCell(activitiesColumns, 'created_at', '2024-01-15T10:30:00Z')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })
})
