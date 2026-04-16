import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { feedbacksColumns } from './columns'

function makeMockRow(data: Record<string, unknown>) {
  return {
    getValue: (key: string) => data[key],
    original: data,
  } as never
}

describe('feedbacksColumns', () => {
  it('defines the expected columns', () => {
    const ids = feedbacksColumns.map(c => (c as any).accessorKey)
    expect(ids).toEqual([
      'id',
      'trip_title',
      'user_email',
      'overall_rating',
      'highlights',
      'lowlights',
      'would_recommend',
      'created_at',
    ])
  })

  it('has correct headers', () => {
    const headers = feedbacksColumns.map(c => c.header)
    expect(headers).toEqual([
      'ID',
      'Trip',
      'Utilisateur',
      'Note',
      'Points forts',
      'Points faibles',
      'Recommande',
      'Créé le',
    ])
  })

  it('overall_rating renders correct number of filled stars', () => {
    const cell = feedbacksColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ overall_rating: 3 }) }))
    expect(container.textContent).toBe('★★★☆☆')
  })

  it('overall_rating renders 5 filled stars', () => {
    const cell = feedbacksColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ overall_rating: 5 }) }))
    expect(container.textContent).toBe('★★★★★')
  })

  it('overall_rating renders 0 filled stars', () => {
    const cell = feedbacksColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ overall_rating: 0 }) }))
    expect(container.textContent).toBe('☆☆☆☆☆')
  })

  it('highlights shows dash when null', () => {
    const cell = feedbacksColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ highlights: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('highlights shows text when present', () => {
    const cell = feedbacksColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ highlights: 'Great view' }) }))
    expect(container.textContent).toBe('Great view')
  })

  it('lowlights shows dash when null', () => {
    const cell = feedbacksColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ lowlights: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('would_recommend shows Oui when true', () => {
    const cell = feedbacksColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ would_recommend: true }) }))
    expect(container.textContent).toBe('Oui')
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-success')
  })

  it('would_recommend shows Non when false', () => {
    const cell = feedbacksColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ would_recommend: false }) }))
    expect(container.textContent).toBe('Non')
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-destructive')
  })

  it('id cell truncates to first 8 chars', () => {
    const cell = feedbacksColumns[0].cell as any
    const { container } = render(cell({ row: makeMockRow({ id: 'abcdefghij1234' }) }))
    expect(container.textContent).toBe('abcdefgh...')
  })

  it('trip_title shows value when present', () => {
    const cell = feedbacksColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: 'My Trip' }) }))
    expect(container.textContent).toBe('My Trip')
  })

  it('trip_title shows dash when empty', () => {
    const cell = feedbacksColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('user_email renders email', () => {
    const cell = feedbacksColumns[2].cell as any
    const { container } = render(cell({ row: makeMockRow({ user_email: 'a@b.com' }) }))
    expect(container.textContent).toBe('a@b.com')
  })

  it('lowlights shows text when present', () => {
    const cell = feedbacksColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ lowlights: 'Bad food' }) }))
    expect(container.textContent).toBe('Bad food')
  })

  it('created_at formats a valid date', () => {
    const cell = feedbacksColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: '2024-01-15T09:00:00Z' }) }))
    expect(container.textContent).toMatch(/15\/01\/2024/)
  })

  it('created_at shows dash for null', () => {
    const cell = feedbacksColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: null }) }))
    expect(container.textContent).toBe('—')
  })
})
