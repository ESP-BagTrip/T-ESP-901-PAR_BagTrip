import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { budgetItemsColumns } from './columns'

function makeMockRow(data: Record<string, unknown>) {
  return {
    getValue: (key: string) => data[key],
    original: data,
  } as never
}

describe('budgetItemsColumns', () => {
  it('defines the expected columns', () => {
    const ids = budgetItemsColumns.map(c => (c as any).accessorKey)
    expect(ids).toEqual([
      'id',
      'trip_title',
      'user_email',
      'label',
      'amount',
      'category',
      'is_planned',
      'date',
      'created_at',
    ])
  })

  it('has correct headers', () => {
    const headers = budgetItemsColumns.map(c => c.header)
    expect(headers).toEqual([
      'ID',
      'Trip',
      'Utilisateur',
      'Libellé',
      'Montant',
      'Catégorie',
      'Planifié',
      'Date',
      'Créé le',
    ])
  })

  it('amount formats with 2 decimals and euro sign', () => {
    const cell = budgetItemsColumns[4].cell as any
    const result = cell({ row: makeMockRow({ amount: 99.9 }) })
    expect(result).toBe('99.90 €')
  })

  it('category cell renders FLIGHT with primary color', () => {
    const cell = budgetItemsColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ category: 'FLIGHT' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-primary')
    expect(span?.textContent).toBe('FLIGHT')
  })

  it('category cell renders FOOD with orange color', () => {
    const cell = budgetItemsColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ category: 'FOOD' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-orange-800')
  })

  it('category cell falls back for unknown category', () => {
    const cell = budgetItemsColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ category: 'UNKNOWN' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('bg-secondary')
  })

  it('is_planned shows Planifié when true', () => {
    const cell = budgetItemsColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ is_planned: true }) }))
    expect(container.textContent).toBe('Planifié')
  })

  it('is_planned shows Réel when false', () => {
    const cell = budgetItemsColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ is_planned: false }) }))
    expect(container.textContent).toBe('Réel')
  })

  it('id cell truncates to first 8 chars', () => {
    const cell = budgetItemsColumns[0].cell as any
    const { container } = render(cell({ row: makeMockRow({ id: 'abcdefghij1234' }) }))
    expect(container.textContent).toBe('abcdefgh...')
  })

  it('trip_title shows value when present', () => {
    const cell = budgetItemsColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: 'My Trip' }) }))
    expect(container.textContent).toBe('My Trip')
  })

  it('trip_title shows dash when empty', () => {
    const cell = budgetItemsColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('user_email renders email', () => {
    const cell = budgetItemsColumns[2].cell as any
    const { container } = render(cell({ row: makeMockRow({ user_email: 'a@b.com' }) }))
    expect(container.textContent).toBe('a@b.com')
  })

  it('label renders text', () => {
    const cell = budgetItemsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ label: 'Hotel' }) }))
    expect(container.textContent).toBe('Hotel')
  })

  it('category cell renders ACCOMMODATION with chart-4 color', () => {
    const cell = budgetItemsColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ category: 'ACCOMMODATION' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-chart-4')
  })

  it('category cell renders ACTIVITY with success color', () => {
    const cell = budgetItemsColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ category: 'ACTIVITY' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-success')
  })

  it('category cell renders TRANSPORT with warning color', () => {
    const cell = budgetItemsColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ category: 'TRANSPORT' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-warning')
  })

  it('category cell renders OTHER with secondary color', () => {
    const cell = budgetItemsColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ category: 'OTHER' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('bg-secondary')
  })

  it('is_planned true has primary color', () => {
    const cell = budgetItemsColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ is_planned: true }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-primary')
  })

  it('is_planned false has success color', () => {
    const cell = budgetItemsColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ is_planned: false }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-success')
  })

  it('date formats a valid date', () => {
    const cell = budgetItemsColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ date: '2024-06-15' }) }))
    expect(container.textContent).toBe('15/06/2024')
  })

  it('date shows dash for null', () => {
    const cell = budgetItemsColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ date: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('created_at formats a valid date', () => {
    const cell = budgetItemsColumns[8].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: '2024-01-15T09:00:00Z' }) }))
    expect(container.textContent).toMatch(/15\/01\/2024/)
  })

  it('created_at shows dash for null', () => {
    const cell = budgetItemsColumns[8].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: null }) }))
    expect(container.textContent).toBe('—')
  })
})
