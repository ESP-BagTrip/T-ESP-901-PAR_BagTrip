import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { profilesColumns } from './columns'

function makeMockRow(data: Record<string, unknown>) {
  return {
    getValue: (key: string) => data[key],
    original: data,
  } as never
}

describe('profilesColumns', () => {
  it('defines the expected columns', () => {
    const ids = profilesColumns.map(c => (c as any).accessorKey)
    expect(ids).toEqual([
      'id',
      'user_email',
      'travel_types',
      'travel_style',
      'budget',
      'companions',
      'is_completed',
      'created_at',
    ])
  })

  it('has correct headers', () => {
    const headers = profilesColumns.map(c => c.header)
    expect(headers).toEqual([
      'ID',
      'Utilisateur',
      'Types de voyage',
      'Style',
      'Budget',
      'Compagnons',
      'Complété',
      'Créé le',
    ])
  })

  it('ID cell truncates to first 8 chars', () => {
    const cell = profilesColumns[0].cell as any
    const { container } = render(cell({ row: makeMockRow({ id: 'abcdefghij1234' }) }))
    expect(container.textContent).toBe('abcdefgh...')
  })

  it('travel_types joins array with comma', () => {
    const cell = profilesColumns[2].cell as any
    const { container } = render(
      cell({ row: makeMockRow({ travel_types: ['Beach', 'City'] }) })
    )
    expect(container.textContent).toBe('Beach, City')
  })

  it('travel_types shows dash when null', () => {
    const cell = profilesColumns[2].cell as any
    const { container } = render(cell({ row: makeMockRow({ travel_types: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('travel_style shows dash when empty', () => {
    const cell = profilesColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ travel_style: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('is_completed shows Oui when true with success color', () => {
    const cell = profilesColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ is_completed: true }) }))
    expect(container.textContent).toBe('Oui')
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-success')
  })

  it('is_completed shows Non when false with warning color', () => {
    const cell = profilesColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ is_completed: false }) }))
    expect(container.textContent).toBe('Non')
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-warning')
  })

  it('budget shows value when present', () => {
    const cell = profilesColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ budget: 'MODERATE' }) }))
    expect(container.textContent).toBe('MODERATE')
  })

  it('budget shows dash when empty', () => {
    const cell = profilesColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ budget: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('companions shows dash when empty', () => {
    const cell = profilesColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ companions: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('user_email renders email', () => {
    const cell = profilesColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ user_email: 'a@b.com' }) }))
    expect(container.textContent).toBe('a@b.com')
  })

  it('travel_style shows value when present', () => {
    const cell = profilesColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ travel_style: 'ADVENTURE' }) }))
    expect(container.textContent).toBe('ADVENTURE')
  })

  it('companions shows value when present', () => {
    const cell = profilesColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ companions: 'FAMILY' }) }))
    expect(container.textContent).toBe('FAMILY')
  })

  it('created_at formats a valid date', () => {
    const cell = profilesColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: '2024-01-15T09:00:00Z' }) }))
    expect(container.textContent).toMatch(/15\/01\/2024/)
  })

  it('created_at shows dash for null', () => {
    const cell = profilesColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: null }) }))
    expect(container.textContent).toBe('—')
  })
})
