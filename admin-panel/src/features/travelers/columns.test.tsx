import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { travelersColumns } from './columns'

function makeMockRow(data: Record<string, unknown>) {
  return {
    getValue: (key: string) => data[key],
    original: data,
  } as never
}

describe('travelersColumns', () => {
  it('defines the expected columns', () => {
    const ids = travelersColumns.map(c => (c as any).accessorKey)
    expect(ids).toEqual([
      'id',
      'trip_title',
      'user_email',
      'first_name',
      'last_name',
      'traveler_type',
      'date_of_birth',
      'gender',
      'created_at',
    ])
  })

  it('has correct headers', () => {
    const headers = travelersColumns.map(c => c.header)
    expect(headers).toEqual([
      'ID',
      'Trip',
      'Utilisateur',
      'Prénom',
      'Nom',
      'Type',
      'Date de naissance',
      'Genre',
      'Créé le',
    ])
  })

  it('ID cell truncates to first 8 chars', () => {
    const cell = travelersColumns[0].cell as any
    const { container } = render(cell({ row: makeMockRow({ id: 'abcdefghij1234' }) }))
    expect(container.textContent).toBe('abcdefgh...')
  })

  it('trip_title falls back to dash', () => {
    const cell = travelersColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('traveler_type renders ADULT with primary color', () => {
    const cell = travelersColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ traveler_type: 'ADULT' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-primary')
    expect(span?.textContent).toBe('ADULT')
  })

  it('traveler_type renders CHILD with warning color', () => {
    const cell = travelersColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ traveler_type: 'CHILD' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-warning')
  })

  it('traveler_type renders INFANT with chart-4 color', () => {
    const cell = travelersColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ traveler_type: 'INFANT' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-chart-4')
  })

  it('traveler_type falls back for unknown type', () => {
    const cell = travelersColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ traveler_type: 'UNKNOWN' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('bg-secondary')
  })

  it('gender shows dash when empty', () => {
    const cell = travelersColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ gender: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('date_of_birth formats a valid date', () => {
    const cell = travelersColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ date_of_birth: '1990-05-20' }) }))
    expect(container.textContent).toBe('20/05/1990')
  })

  it('date_of_birth shows dash for null', () => {
    const cell = travelersColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ date_of_birth: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('gender shows value when present', () => {
    const cell = travelersColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ gender: 'MALE' }) }))
    expect(container.textContent).toBe('MALE')
  })

  it('user_email renders email', () => {
    const cell = travelersColumns[2].cell as any
    const { container } = render(cell({ row: makeMockRow({ user_email: 'a@b.com' }) }))
    expect(container.textContent).toBe('a@b.com')
  })

  it('first_name renders text', () => {
    const cell = travelersColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ first_name: 'John' }) }))
    expect(container.textContent).toBe('John')
  })

  it('last_name renders text', () => {
    const cell = travelersColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ last_name: 'Doe' }) }))
    expect(container.textContent).toBe('Doe')
  })

  it('created_at formats a valid date', () => {
    const cell = travelersColumns[8].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: '2024-01-15T09:00:00Z' }) }))
    expect(container.textContent).toMatch(/15\/01\/2024/)
  })

  it('created_at shows dash for null', () => {
    const cell = travelersColumns[8].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: null }) }))
    expect(container.textContent).toBe('—')
  })
})
