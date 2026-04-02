import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { bookingIntentsColumns } from '../columns'

function renderCell(columns: any[], accessorKey: string, value: any, original: any = {}) {
  const col = columns.find((c: any) => c.accessorKey === accessorKey)
  if (!col?.cell) return null
  const mockRow = {
    getValue: (key: string) => (key === accessorKey ? value : undefined),
    original,
  }
  const { container } = render(<>{(col.cell as Function)({ row: mockRow })}</>)
  return container
}

describe('bookingIntentsColumns', () => {
  it('should have 8 columns', () => {
    expect(bookingIntentsColumns).toHaveLength(8)
  })

  it('renders id cell with truncated value', () => {
    renderCell(bookingIntentsColumns, 'id', 'abcdefgh-1234-5678-9012')
    expect(screen.getByText('abcdefgh...')).toBeInTheDocument()
  })

  it('renders user_email cell', () => {
    renderCell(bookingIntentsColumns, 'user_email', 'user@test.com')
    expect(screen.getByText('user@test.com')).toBeInTheDocument()
  })

  it('renders trip_title cell with value', () => {
    renderCell(bookingIntentsColumns, 'trip_title', 'Trip Paris')
    expect(screen.getByText('Trip Paris')).toBeInTheDocument()
  })

  it('renders trip_title cell with fallback', () => {
    renderCell(bookingIntentsColumns, 'trip_title', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders type cell with flight', () => {
    renderCell(bookingIntentsColumns, 'type', 'flight')
    expect(screen.getByText('flight')).toBeInTheDocument()
  })

  it('renders type cell with hotel', () => {
    renderCell(bookingIntentsColumns, 'type', 'hotel')
    expect(screen.getByText('hotel')).toBeInTheDocument()
  })

  it('renders type cell with unknown type', () => {
    renderCell(bookingIntentsColumns, 'type', 'other')
    expect(screen.getByText('other')).toBeInTheDocument()
  })

  it('renders status cell with BOOKED', () => {
    renderCell(bookingIntentsColumns, 'status', 'BOOKED')
    expect(screen.getByText('BOOKED')).toBeInTheDocument()
  })

  it('renders status cell with FAILED', () => {
    renderCell(bookingIntentsColumns, 'status', 'FAILED')
    expect(screen.getByText('FAILED')).toBeInTheDocument()
  })

  it('renders status cell with INIT', () => {
    renderCell(bookingIntentsColumns, 'status', 'INIT')
    expect(screen.getByText('INIT')).toBeInTheDocument()
  })

  it('renders status cell with unknown status', () => {
    renderCell(bookingIntentsColumns, 'status', 'UNKNOWN')
    expect(screen.getByText('UNKNOWN')).toBeInTheDocument()
  })

  it('renders amount cell with currency from original', () => {
    renderCell(bookingIntentsColumns, 'amount', 99.5, { currency: 'EUR' })
    expect(screen.getByText('99.5 EUR')).toBeInTheDocument()
  })

  it('renders stripe_payment_intent_id cell with value', () => {
    renderCell(bookingIntentsColumns, 'stripe_payment_intent_id', 'pi_1234567890abcdef')
    expect(screen.getByText('pi_123456789...')).toBeInTheDocument()
  })

  it('renders stripe_payment_intent_id cell with null', () => {
    renderCell(bookingIntentsColumns, 'stripe_payment_intent_id', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders created_at cell', () => {
    const container = renderCell(bookingIntentsColumns, 'created_at', '2024-01-15T10:30:00Z')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })
})
