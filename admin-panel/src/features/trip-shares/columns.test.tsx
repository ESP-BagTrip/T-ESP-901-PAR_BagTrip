import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { tripSharesColumns } from './columns'

function makeMockRow(data: Record<string, unknown>) {
  return {
    getValue: (key: string) => data[key],
    original: data,
  } as never
}

describe('tripSharesColumns', () => {
  it('defines the expected columns', () => {
    const ids = tripSharesColumns.map(c => (c as any).accessorKey)
    expect(ids).toEqual(['id', 'trip_title', 'user_email', 'role', 'invited_at'])
  })

  it('has correct headers', () => {
    const headers = tripSharesColumns.map(c => c.header)
    expect(headers).toEqual(['ID', 'Trip', 'Utilisateur partagé', 'Rôle', 'Invité le'])
  })

  it('ID cell truncates to first 8 chars', () => {
    const cell = tripSharesColumns[0].cell as any
    const { container } = render(cell({ row: makeMockRow({ id: 'abcdefghij1234' }) }))
    expect(container.textContent).toBe('abcdefgh...')
  })

  it('trip_title shows value when present', () => {
    const cell = tripSharesColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: 'Paris Trip' }) }))
    expect(container.textContent).toBe('Paris Trip')
  })

  it('role cell renders with primary color badge', () => {
    const cell = tripSharesColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ role: 'EDITOR' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-primary')
    expect(span?.textContent).toBe('EDITOR')
  })

  it('invited_at formats a valid date', () => {
    const cell = tripSharesColumns[4].cell as any
    const { container } = render(
      cell({ row: makeMockRow({ invited_at: '2024-03-10T14:00:00Z' }) })
    )
    expect(container.textContent).toMatch(/10\/03\/2024/)
  })

  it('trip_title shows dash when empty', () => {
    const cell = tripSharesColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('invited_at shows dash for null', () => {
    const cell = tripSharesColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ invited_at: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('user_email renders email', () => {
    const cell = tripSharesColumns[2].cell as any
    const { container } = render(cell({ row: makeMockRow({ user_email: 'a@b.com' }) }))
    expect(container.textContent).toBe('a@b.com')
  })

  it('role cell renders VIEWER with primary color badge', () => {
    const cell = tripSharesColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ role: 'VIEWER' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-primary')
    expect(span?.textContent).toBe('VIEWER')
  })
})
