import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { flightSearchesColumns } from '../columns'

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

describe('flightSearchesColumns', () => {
  it('should have 10 columns', () => {
    expect(flightSearchesColumns).toHaveLength(10)
  })

  it('renders id cell with truncated value', () => {
    renderCell(flightSearchesColumns, 'id', 'abcdefgh-1234-5678-9012')
    expect(screen.getByText('abcdefgh...')).toBeInTheDocument()
  })

  it('renders trip_title cell with value', () => {
    renderCell(flightSearchesColumns, 'trip_title', 'My Trip')
    expect(screen.getByText('My Trip')).toBeInTheDocument()
  })

  it('renders trip_title cell with fallback', () => {
    renderCell(flightSearchesColumns, 'trip_title', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders origin_iata cell', () => {
    renderCell(flightSearchesColumns, 'origin_iata', 'CDG')
    expect(screen.getByText('CDG')).toBeInTheDocument()
  })

  it('renders destination_iata cell', () => {
    renderCell(flightSearchesColumns, 'destination_iata', 'JFK')
    expect(screen.getByText('JFK')).toBeInTheDocument()
  })

  it('renders departure_date cell', () => {
    const container = renderCell(flightSearchesColumns, 'departure_date', '2024-06-15')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })

  it('renders return_date cell', () => {
    const container = renderCell(flightSearchesColumns, 'return_date', '2024-06-20')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })

  it('renders return_date cell with null', () => {
    const container = renderCell(flightSearchesColumns, 'return_date', null)
    expect(container?.querySelector('span')).toBeInTheDocument()
  })

  it('renders adults cell', () => {
    renderCell(flightSearchesColumns, 'adults', 2)
    expect(screen.getByText('2')).toBeInTheDocument()
  })

  it('renders children cell with value', () => {
    renderCell(flightSearchesColumns, 'children', 1)
    expect(screen.getByText('1')).toBeInTheDocument()
  })

  it('renders children cell with null', () => {
    renderCell(flightSearchesColumns, 'children', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders travel_class cell with value', () => {
    renderCell(flightSearchesColumns, 'travel_class', 'BUSINESS')
    expect(screen.getByText('BUSINESS')).toBeInTheDocument()
  })

  it('renders travel_class cell with null', () => {
    renderCell(flightSearchesColumns, 'travel_class', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders created_at cell', () => {
    const container = renderCell(flightSearchesColumns, 'created_at', '2024-01-15T10:30:00Z')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })
})
