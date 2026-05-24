import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { activitiesColumns } from './columns'

function makeMockRow(data: Record<string, unknown>) {
  return {
    getValue: (key: string) => data[key],
    original: data,
  } as never
}

describe('activitiesColumns', () => {
  it('defines the expected columns', () => {
    const ids = activitiesColumns.map(c => (c as any).accessorKey)
    expect(ids).toEqual([
      'id',
      'trip_title',
      'user_email',
      'title',
      'date',
      'category',
      'estimated_cost',
      'is_booked',
      'created_at',
    ])
  })

  it('has correct headers', () => {
    const headers = activitiesColumns.map(c => c.header)
    expect(headers).toEqual([
      'ID',
      'Trip',
      'Utilisateur',
      'Titre',
      'Date',
      'Catégorie',
      'Coût estimé',
      'Réservé',
      'Créé le',
    ])
  })

  it('category cell renders with correct color class for VISIT', () => {
    const cell = activitiesColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ category: 'VISIT' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-primary')
    expect(span?.textContent).toBe('VISIT')
  })

  it('category cell falls back for unknown category', () => {
    const cell = activitiesColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ category: 'UNKNOWN' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('bg-secondary')
  })

  it('estimated_cost formats with 2 decimals', () => {
    const cell = activitiesColumns[6].cell as any
    const result = cell({ row: makeMockRow({ estimated_cost: 42.5 }) })
    expect(result).toBe('42.50 €')
  })

  it('estimated_cost shows dash when null', () => {
    const cell = activitiesColumns[6].cell as any
    const result = cell({ row: makeMockRow({ estimated_cost: null }) })
    expect(result).toBe('—')
  })

  it('is_booked shows Oui when true', () => {
    const cell = activitiesColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ is_booked: true }) }))
    expect(container.textContent).toBe('Oui')
  })

  it('is_booked shows Non when false', () => {
    const cell = activitiesColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ is_booked: false }) }))
    expect(container.textContent).toBe('Non')
  })

  it('id cell truncates to first 8 chars', () => {
    const cell = activitiesColumns[0].cell as any
    const { container } = render(cell({ row: makeMockRow({ id: 'abcdefghij1234' }) }))
    expect(container.textContent).toBe('abcdefgh...')
  })

  it('trip_title shows value when present', () => {
    const cell = activitiesColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: 'My Trip' }) }))
    expect(container.textContent).toBe('My Trip')
  })

  it('trip_title shows dash when empty', () => {
    const cell = activitiesColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('user_email renders email', () => {
    const cell = activitiesColumns[2].cell as any
    const { container } = render(cell({ row: makeMockRow({ user_email: 'a@b.com' }) }))
    expect(container.textContent).toBe('a@b.com')
  })

  it('title renders text', () => {
    const cell = activitiesColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ title: 'Museum' }) }))
    expect(container.textContent).toBe('Museum')
  })

  it('date formats a valid date', () => {
    const cell = activitiesColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ date: '2024-12-25' }) }))
    expect(container.textContent).toBe('25/12/2024')
  })

  it('date shows dash for null', () => {
    const cell = activitiesColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ date: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('category cell renders RESTAURANT with orange color', () => {
    const cell = activitiesColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ category: 'RESTAURANT' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-orange-800')
  })

  it('category cell renders TRANSPORT with warning color', () => {
    const cell = activitiesColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ category: 'TRANSPORT' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-warning')
  })

  it('category cell renders LEISURE with success color', () => {
    const cell = activitiesColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ category: 'LEISURE' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-success')
  })

  it('category cell renders OTHER with secondary color', () => {
    const cell = activitiesColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ category: 'OTHER' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('bg-secondary')
  })

  it('is_booked true has success color', () => {
    const cell = activitiesColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ is_booked: true }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-success')
  })

  it('is_booked false has secondary color', () => {
    const cell = activitiesColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ is_booked: false }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('bg-secondary')
  })

  it('created_at formats a valid date', () => {
    const cell = activitiesColumns[8].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: '2024-01-15T09:00:00Z' }) }))
    expect(container.textContent).toMatch(/15\/01\/2024/)
  })

  it('created_at shows dash for null', () => {
    const cell = activitiesColumns[8].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: null }) }))
    expect(container.textContent).toBe('—')
  })
})
