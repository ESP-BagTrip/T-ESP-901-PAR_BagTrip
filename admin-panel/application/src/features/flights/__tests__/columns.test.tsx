import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { flightBookingsColumns } from '../columns'

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

describe('flightBookingsColumns', () => {
  it('should have 7 columns', () => {
    expect(flightBookingsColumns).toHaveLength(7)
  })

  it('renders id cell with truncated value', () => {
    renderCell(flightBookingsColumns, 'id', 'abcdefgh-1234-5678-9012')
    expect(screen.getByText('abcdefgh...')).toBeInTheDocument()
  })

  it('renders trip_title cell with value', () => {
    renderCell(flightBookingsColumns, 'trip_title', 'My Trip')
    expect(screen.getByText('My Trip')).toBeInTheDocument()
  })

  it('renders trip_title cell with fallback', () => {
    renderCell(flightBookingsColumns, 'trip_title', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders user_email cell', () => {
    renderCell(flightBookingsColumns, 'user_email', 'user@test.com')
    expect(screen.getByText('user@test.com')).toBeInTheDocument()
  })

  it('renders status cell with CONFIRMED', () => {
    renderCell(flightBookingsColumns, 'status', 'CONFIRMED')
    expect(screen.getByText('CONFIRMED')).toBeInTheDocument()
  })

  it('renders status cell with PENDING', () => {
    renderCell(flightBookingsColumns, 'status', 'PENDING')
    expect(screen.getByText('PENDING')).toBeInTheDocument()
  })

  it('renders status cell with CANCELLED', () => {
    renderCell(flightBookingsColumns, 'status', 'CANCELLED')
    expect(screen.getByText('CANCELLED')).toBeInTheDocument()
  })

  it('renders status cell with null', () => {
    renderCell(flightBookingsColumns, 'status', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders amadeus_flight_order_id cell with value', () => {
    renderCell(flightBookingsColumns, 'amadeus_flight_order_id', 'ORDER1234567890AB')
    expect(screen.getByText('ORDER1234567...')).toBeInTheDocument()
  })

  it('renders amadeus_flight_order_id cell with null', () => {
    renderCell(flightBookingsColumns, 'amadeus_flight_order_id', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders booking_reference cell with value', () => {
    renderCell(flightBookingsColumns, 'booking_reference', 'ABC123')
    expect(screen.getByText('ABC123')).toBeInTheDocument()
  })

  it('renders booking_reference cell with null', () => {
    renderCell(flightBookingsColumns, 'booking_reference', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders created_at cell', () => {
    const container = renderCell(flightBookingsColumns, 'created_at', '2024-01-15T10:30:00Z')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })
})
