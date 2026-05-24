import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { tripsColumns } from './columns'

function makeMockRow(data: Record<string, unknown>) {
  return {
    getValue: (key: string) => data[key],
    original: data,
  } as never
}

describe('tripsColumns', () => {
  it('defines the expected columns', () => {
    const ids = tripsColumns.map(c => (c as any).accessorKey)
    expect(ids).toEqual([
      'id',
      'user_email',
      'title',
      'destination_name',
      'origin_iata',
      'start_date',
      'end_date',
      'nb_travelers',
      'status',
      'created_at',
    ])
  })

  it('has correct headers', () => {
    const headers = tripsColumns.map(c => c.header)
    expect(headers).toEqual([
      'ID',
      'Utilisateur',
      'Titre',
      'Destination',
      'Origine',
      'Départ',
      'Retour',
      'Voyageurs',
      'Statut',
      'Créé le',
    ])
  })

  it('ID cell truncates to first 8 chars', () => {
    const cell = tripsColumns[0].cell as any
    const { container } = render(cell({ row: makeMockRow({ id: 'abcdefghij1234' }) }))
    expect(container.textContent).toBe('abcdefgh...')
  })

  it('destination_name shows name when present', () => {
    const cell = tripsColumns[3].cell as any
    const { container } = render(
      cell({
        row: makeMockRow({ destination_name: 'Paris', destination_iata: 'CDG' }),
      })
    )
    expect(container.textContent).toBe('Paris')
  })

  it('destination_name falls back to iata', () => {
    const cell = tripsColumns[3].cell as any
    const { container } = render(
      cell({
        row: makeMockRow({ destination_name: null, destination_iata: 'CDG' }),
      })
    )
    expect(container.textContent).toBe('CDG')
  })

  it('destination_name shows dash when both null', () => {
    const cell = tripsColumns[3].cell as any
    const { container } = render(
      cell({
        row: makeMockRow({ destination_name: null, destination_iata: null }),
      })
    )
    expect(container.textContent).toBe('—')
  })

  it('nb_travelers shows dash when null', () => {
    const cell = tripsColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ nb_travelers: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('nb_travelers shows value when present', () => {
    const cell = tripsColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ nb_travelers: 3 }) }))
    expect(container.textContent).toBe('3')
  })

  it('status renders PLANNED with primary color', () => {
    const cell = tripsColumns[8].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'PLANNED' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-primary')
    expect(span?.textContent).toBe('PLANNED')
  })

  it('status renders ONGOING with success color', () => {
    const cell = tripsColumns[8].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'ONGOING' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-success')
  })

  it('status renders COMPLETED with chart-4 color', () => {
    const cell = tripsColumns[8].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'COMPLETED' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-chart-4')
  })

  it('status shows dash when null', () => {
    const cell = tripsColumns[8].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('title shows dash when empty', () => {
    const cell = tripsColumns[2].cell as any
    const { container } = render(cell({ row: makeMockRow({ title: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('title shows value when present', () => {
    const cell = tripsColumns[2].cell as any
    const { container } = render(cell({ row: makeMockRow({ title: 'Paris Trip' }) }))
    expect(container.textContent).toBe('Paris Trip')
  })

  it('origin_iata shows dash when empty', () => {
    const cell = tripsColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ origin_iata: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('start_date formats a valid date', () => {
    const cell = tripsColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ start_date: '2024-07-01' }) }))
    expect(container.textContent).toBe('01/07/2024')
  })

  it('end_date shows dash for null', () => {
    const cell = tripsColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ end_date: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('status renders DRAFT with secondary bg', () => {
    const cell = tripsColumns[8].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'DRAFT' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('bg-secondary')
  })

  it('user_email renders email', () => {
    const cell = tripsColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ user_email: 'a@b.com' }) }))
    expect(container.textContent).toBe('a@b.com')
  })

  it('status falls back for unknown status', () => {
    const cell = tripsColumns[8].cell as any
    const { container } = render(cell({ row: makeMockRow({ status: 'UNKNOWN' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('bg-secondary')
    expect(span?.textContent).toBe('UNKNOWN')
  })

  it('created_at formats a valid date', () => {
    const cell = tripsColumns[9].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: '2024-01-15T09:00:00Z' }) }))
    expect(container.textContent).toMatch(/15\/01\/2024/)
  })

  it('created_at shows dash for null', () => {
    const cell = tripsColumns[9].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('origin_iata shows value when present', () => {
    const cell = tripsColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ origin_iata: 'CDG' }) }))
    expect(container.textContent).toBe('CDG')
  })
})
