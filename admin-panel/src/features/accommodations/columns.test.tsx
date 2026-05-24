import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { accommodationsColumns } from './columns'

function makeMockRow(data: Record<string, unknown>) {
  return {
    getValue: (key: string) => data[key],
    original: data,
  } as never
}

describe('accommodationsColumns', () => {
  it('defines the expected columns', () => {
    const ids = accommodationsColumns.map(c => (c as any).accessorKey)
    expect(ids).toEqual([
      'id',
      'trip_title',
      'user_email',
      'name',
      'check_in',
      'check_out',
      'price_per_night',
      'created_at',
    ])
  })

  it('has correct headers', () => {
    const headers = accommodationsColumns.map(c => c.header)
    expect(headers).toEqual([
      'ID',
      'Trip',
      'Utilisateur',
      'Nom',
      'Arrivée',
      'Départ',
      'Prix/nuit',
      'Créé le',
    ])
  })

  it('ID cell truncates to first 8 chars', () => {
    const cell = accommodationsColumns[0].cell as any
    const { container } = render(cell({ row: makeMockRow({ id: 'abcdefghij1234' }) }))
    expect(container.textContent).toBe('abcdefgh...')
  })

  it('trip_title falls back to dash', () => {
    const cell = accommodationsColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('price_per_night formats with 2 decimals and euro sign', () => {
    const cell = accommodationsColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ price_per_night: 120 }) }))
    expect(container.textContent).toBe('120.00 €')
  })

  it('price_per_night shows dash when null', () => {
    const cell = accommodationsColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ price_per_night: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('check_in formats a valid date', () => {
    const cell = accommodationsColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ check_in: '2024-06-15' }) }))
    expect(container.textContent).toBe('15/06/2024')
  })

  it('check_in shows dash for null', () => {
    const cell = accommodationsColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ check_in: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('user_email renders email', () => {
    const cell = accommodationsColumns[2].cell as any
    const { container } = render(cell({ row: makeMockRow({ user_email: 'a@b.com' }) }))
    expect(container.textContent).toBe('a@b.com')
  })

  it('name renders text', () => {
    const cell = accommodationsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ name: 'Hotel Paris' }) }))
    expect(container.textContent).toBe('Hotel Paris')
  })

  it('check_out formats a valid date', () => {
    const cell = accommodationsColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ check_out: '2024-06-20' }) }))
    expect(container.textContent).toBe('20/06/2024')
  })

  it('check_out shows dash for null', () => {
    const cell = accommodationsColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ check_out: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('trip_title shows value when present', () => {
    const cell = accommodationsColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: 'My Trip' }) }))
    expect(container.textContent).toBe('My Trip')
  })

  it('created_at formats a valid date', () => {
    const cell = accommodationsColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: '2024-01-15T09:00:00Z' }) }))
    expect(container.textContent).toMatch(/15\/01\/2024/)
  })

  it('created_at shows dash for null', () => {
    const cell = accommodationsColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: null }) }))
    expect(container.textContent).toBe('—')
  })
})
