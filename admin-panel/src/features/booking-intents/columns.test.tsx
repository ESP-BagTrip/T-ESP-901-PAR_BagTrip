import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { bookingIntentsColumns } from './columns'

function makeMockRow(data: Record<string, unknown>) {
  return {
    getValue: (key: string) => data[key],
    original: data,
  } as never
}

describe('bookingIntentsColumns', () => {
  it('defines the expected columns', () => {
    const ids = bookingIntentsColumns.map(c => (c as any).accessorKey)
    expect(ids).toEqual([
      'id',
      'user_email',
      'trip_title',
      'type',
      'status',
      'amount',
      'stripe_payment_intent_id',
      'created_at',
    ])
  })

  it('has correct headers', () => {
    const headers = bookingIntentsColumns.map(c => c.header)
    expect(headers).toEqual([
      'ID',
      'Utilisateur',
      'Trip',
      'Type',
      'Statut',
      'Montant',
      'Stripe PI',
      'Créé le',
    ])
  })

  it('type cell renders flight with primary color', () => {
    const cell = bookingIntentsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ type: 'flight' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-primary')
    expect(span?.textContent).toBe('flight')
  })

  it('type cell renders hotel with chart-4 color', () => {
    const cell = bookingIntentsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ type: 'hotel' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-chart-4')
  })

  it('status cell renders BOOKED with success color', () => {
    const cell = bookingIntentsColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'BOOKED' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-success')
  })

  it('status cell renders FAILED with destructive color', () => {
    const cell = bookingIntentsColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'FAILED' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-destructive')
  })

  it('amount cell shows amount with currency', () => {
    const cell = bookingIntentsColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ amount: 250, currency: 'EUR' }) }))
    expect(container.textContent).toContain('250')
    expect(container.textContent).toContain('EUR')
  })

  it('stripe PI truncates when present', () => {
    const cell = bookingIntentsColumns[6].cell as any
    const { container } = render(
      cell({ row: makeMockRow({ stripe_payment_intent_id: 'pi_1234567890abcdef' }) })
    )
    expect(container.textContent).toBe('pi_123456789...')
  })

  it('stripe PI shows dash when null', () => {
    const cell = bookingIntentsColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ stripe_payment_intent_id: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('id cell truncates to first 8 chars', () => {
    const cell = bookingIntentsColumns[0].cell as any
    const { container } = render(cell({ row: makeMockRow({ id: 'abcdefghij1234' }) }))
    expect(container.textContent).toBe('abcdefgh...')
  })

  it('user_email renders email', () => {
    const cell = bookingIntentsColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ user_email: 'a@b.com' }) }))
    expect(container.textContent).toBe('a@b.com')
  })

  it('trip_title shows value when present', () => {
    const cell = bookingIntentsColumns[2].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: 'My Trip' }) }))
    expect(container.textContent).toBe('My Trip')
  })

  it('trip_title shows dash when empty', () => {
    const cell = bookingIntentsColumns[2].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('type cell falls back for unknown type', () => {
    const cell = bookingIntentsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ type: 'unknown' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('bg-secondary')
  })

  it('status cell renders INIT with secondary color', () => {
    const cell = bookingIntentsColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'INIT' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('bg-secondary')
    expect(span?.textContent).toBe('INIT')
  })

  it('status cell renders AUTHORIZED with primary color', () => {
    const cell = bookingIntentsColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'AUTHORIZED' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-primary')
  })

  it('status cell renders BOOKING_PENDING with warning color', () => {
    const cell = bookingIntentsColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'BOOKING_PENDING' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-warning')
  })

  it('status cell renders CAPTURED with success color', () => {
    const cell = bookingIntentsColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'CAPTURED' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-success')
  })

  it('status cell renders CANCELLED with destructive color', () => {
    const cell = bookingIntentsColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'CANCELLED' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-destructive')
  })

  it('status cell renders PAYMENT_CAPTURE_FAILED with destructive color', () => {
    const cell = bookingIntentsColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'PAYMENT_CAPTURE_FAILED' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-destructive')
  })

  it('status cell falls back for unknown status', () => {
    const cell = bookingIntentsColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'UNKNOWN' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('bg-secondary')
  })

  it('created_at formats a valid date', () => {
    const cell = bookingIntentsColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: '2024-01-15T09:00:00Z' }) }))
    expect(container.textContent).toMatch(/15\/01\/2024/)
  })

  it('created_at shows dash for null', () => {
    const cell = bookingIntentsColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: null }) }))
    expect(container.textContent).toBe('—')
  })
})
