import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { flightBookingsColumns } from './columns'

function makeMockRow(data: Record<string, unknown>) {
  return {
    getValue: (key: string) => data[key],
    original: data,
  } as never
}

describe('flightBookingsColumns', () => {
  it('defines the expected columns', () => {
    const ids = flightBookingsColumns.map(c => (c as any).accessorKey)
    expect(ids).toEqual([
      'id',
      'trip_title',
      'user_email',
      'status',
      'amadeus_flight_order_id',
      'booking_reference',
      'created_at',
    ])
  })

  it('has correct headers', () => {
    const headers = flightBookingsColumns.map(c => c.header)
    expect(headers).toEqual([
      'ID',
      'Trip',
      'Utilisateur',
      'Statut',
      'Amadeus Order ID',
      'Référence',
      'Créé le',
    ])
  })

  it('status cell renders CONFIRMED with success color', () => {
    const cell = flightBookingsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'CONFIRMED' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-success')
    expect(span?.textContent).toBe('CONFIRMED')
  })

  it('status cell renders PENDING with warning color', () => {
    const cell = flightBookingsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'PENDING' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-warning')
  })

  it('status cell renders CANCELLED with destructive color', () => {
    const cell = flightBookingsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'CANCELLED' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-destructive')
  })

  it('status cell shows dash when null', () => {
    const cell = flightBookingsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('amadeus order id truncates when present', () => {
    const cell = flightBookingsColumns[4].cell as any
    const { container } = render(
      cell({ row: makeMockRow({ amadeus_flight_order_id: 'ORDER123456789ABC' }) })
    )
    expect(container.textContent).toBe('ORDER1234567...')
  })

  it('amadeus order id shows dash when null', () => {
    const cell = flightBookingsColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ amadeus_flight_order_id: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('booking reference shows dash when null', () => {
    const cell = flightBookingsColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ booking_reference: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('booking reference shows value when present', () => {
    const cell = flightBookingsColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ booking_reference: 'ABC123' }) }))
    expect(container.textContent).toBe('ABC123')
  })

  it('id cell truncates to first 8 chars', () => {
    const cell = flightBookingsColumns[0].cell as any
    const { container } = render(cell({ row: makeMockRow({ id: 'abcdefghij1234' }) }))
    expect(container.textContent).toBe('abcdefgh...')
  })

  it('trip_title shows value when present', () => {
    const cell = flightBookingsColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: 'My Trip' }) }))
    expect(container.textContent).toBe('My Trip')
  })

  it('trip_title shows dash when empty', () => {
    const cell = flightBookingsColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('user_email renders email', () => {
    const cell = flightBookingsColumns[2].cell as any
    const { container } = render(cell({ row: makeMockRow({ user_email: 'a@b.com' }) }))
    expect(container.textContent).toBe('a@b.com')
  })

  it('status cell falls back for unknown status', () => {
    const cell = flightBookingsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'UNKNOWN' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('bg-secondary')
    expect(span?.textContent).toBe('UNKNOWN')
  })

  it('created_at formats a valid date', () => {
    const cell = flightBookingsColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: '2024-01-15T09:00:00Z' }) }))
    expect(container.textContent).toMatch(/15\/01\/2024/)
  })

  it('created_at shows dash for null', () => {
    const cell = flightBookingsColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: null }) }))
    expect(container.textContent).toBe('—')
  })
})
