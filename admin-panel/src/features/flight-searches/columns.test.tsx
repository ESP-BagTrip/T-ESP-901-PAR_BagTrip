import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { flightSearchesColumns } from './columns'

function makeMockRow(data: Record<string, unknown>) {
  return {
    getValue: (key: string) => data[key],
    original: data,
  } as never
}

describe('flightSearchesColumns', () => {
  it('defines the expected columns', () => {
    const ids = flightSearchesColumns.map(c => (c as any).accessorKey)
    expect(ids).toEqual([
      'id',
      'trip_title',
      'origin_iata',
      'destination_iata',
      'departure_date',
      'return_date',
      'adults',
      'children',
      'travel_class',
      'created_at',
    ])
  })

  it('has correct headers', () => {
    const headers = flightSearchesColumns.map(c => c.header)
    expect(headers).toEqual([
      'ID',
      'Trip',
      'Origine',
      'Destination',
      'Départ',
      'Retour',
      'Adultes',
      'Enfants',
      'Classe',
      'Créé le',
    ])
  })

  it('origin_iata renders with font-semibold', () => {
    const cell = flightSearchesColumns[2].cell as any
    const { container } = render(cell({ row: makeMockRow({ origin_iata: 'CDG' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('font-semibold')
    expect(span?.textContent).toBe('CDG')
  })

  it('children shows dash when null', () => {
    const cell = flightSearchesColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ children: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('children shows value when present', () => {
    const cell = flightSearchesColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ children: 2 }) }))
    expect(container.textContent).toBe('2')
  })

  it('travel_class shows dash when empty', () => {
    const cell = flightSearchesColumns[8].cell as any
    const { container } = render(cell({ row: makeMockRow({ travel_class: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('departure_date formats a valid date', () => {
    const cell = flightSearchesColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ departure_date: '2024-12-25' }) }))
    expect(container.textContent).toBe('25/12/2024')
  })

  it('id cell truncates to first 8 chars', () => {
    const cell = flightSearchesColumns[0].cell as any
    const { container } = render(cell({ row: makeMockRow({ id: 'abcdefghij1234' }) }))
    expect(container.textContent).toBe('abcdefgh...')
  })

  it('trip_title shows value when present', () => {
    const cell = flightSearchesColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: 'My Trip' }) }))
    expect(container.textContent).toBe('My Trip')
  })

  it('trip_title shows dash when empty', () => {
    const cell = flightSearchesColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('destination_iata renders with font-semibold', () => {
    const cell = flightSearchesColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ destination_iata: 'JFK' }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('font-semibold')
    expect(span?.textContent).toBe('JFK')
  })

  it('return_date formats a valid date', () => {
    const cell = flightSearchesColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ return_date: '2025-01-05' }) }))
    expect(container.textContent).toBe('05/01/2025')
  })

  it('return_date shows dash for null', () => {
    const cell = flightSearchesColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ return_date: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('adults renders value', () => {
    const cell = flightSearchesColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ adults: 2 }) }))
    expect(container.textContent).toBe('2')
  })

  it('travel_class shows value when present', () => {
    const cell = flightSearchesColumns[8].cell as any
    const { container } = render(cell({ row: makeMockRow({ travel_class: 'BUSINESS' }) }))
    expect(container.textContent).toBe('BUSINESS')
  })

  it('departure_date shows dash for null', () => {
    const cell = flightSearchesColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ departure_date: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('created_at formats a valid date', () => {
    const cell = flightSearchesColumns[9].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: '2024-01-15T09:00:00Z' }) }))
    expect(container.textContent).toMatch(/15\/01\/2024/)
  })

  it('created_at shows dash for null', () => {
    const cell = flightSearchesColumns[9].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: null }) }))
    expect(container.textContent).toBe('—')
  })
})
