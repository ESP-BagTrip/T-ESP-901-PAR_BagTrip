import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { baggageItemsColumns } from './columns'

function makeMockRow(data: Record<string, unknown>) {
  return {
    getValue: (key: string) => data[key],
    original: data,
  } as never
}

describe('baggageItemsColumns', () => {
  it('defines the expected columns', () => {
    const ids = baggageItemsColumns.map(c => (c as any).accessorKey)
    expect(ids).toEqual([
      'id',
      'trip_title',
      'user_email',
      'name',
      'category',
      'quantity',
      'is_packed',
      'created_at',
    ])
  })

  it('has correct headers', () => {
    const headers = baggageItemsColumns.map(c => c.header)
    expect(headers).toEqual([
      'ID',
      'Trip',
      'Utilisateur',
      'Nom',
      'Catégorie',
      'Qté',
      'Emballé',
      'Créé le',
    ])
  })

  describe('inferCategory via category cell', () => {
    const categoryCell = baggageItemsColumns[4].cell as any

    it('keeps non-OTHER db category', () => {
      const { container } = render(
        categoryCell({ row: makeMockRow({ name: 'shirt', category: 'CLOTHING' }) })
      )
      expect(container.textContent).toBe('CLOTHING')
    })

    it('infers DOCUMENTS from passport', () => {
      const { container } = render(
        categoryCell({ row: makeMockRow({ name: 'Passport', category: 'OTHER' }) })
      )
      expect(container.textContent).toBe('DOCUMENTS')
    })

    it('infers CLOTHING from shirt', () => {
      const { container } = render(
        categoryCell({ row: makeMockRow({ name: 'T-shirt', category: null }) })
      )
      expect(container.textContent).toBe('CLOTHING')
    })

    it('infers ELECTRONICS from charger', () => {
      const { container } = render(
        categoryCell({ row: makeMockRow({ name: 'Phone charger', category: 'OTHER' }) })
      )
      expect(container.textContent).toBe('ELECTRONICS')
    })

    it('infers TOILETRIES from toothbrush', () => {
      const { container } = render(
        categoryCell({ row: makeMockRow({ name: 'Toothbrush', category: 'OTHER' }) })
      )
      expect(container.textContent).toBe('TOILETRIES')
    })

    it('infers HEALTH from medicine', () => {
      const { container } = render(
        categoryCell({ row: makeMockRow({ name: 'Medicine', category: 'OTHER' }) })
      )
      expect(container.textContent).toBe('HEALTH')
    })

    it('infers ACCESSORIES from sunglasses', () => {
      const { container } = render(
        categoryCell({ row: makeMockRow({ name: 'Sunglasses', category: 'OTHER' }) })
      )
      expect(container.textContent).toBe('ACCESSORIES')
    })

    it('keeps OTHER for unrecognized items', () => {
      const { container } = render(
        categoryCell({ row: makeMockRow({ name: 'random thing', category: 'OTHER' }) })
      )
      expect(container.textContent).toBe('OTHER')
    })
  })

  it('quantity defaults to 1 when null', () => {
    const cell = baggageItemsColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ quantity: null }) }))
    expect(container.textContent).toBe('1')
  })

  it('is_packed shows Oui when true', () => {
    const cell = baggageItemsColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ is_packed: true }) }))
    expect(container.textContent).toBe('Oui')
  })

  it('is_packed shows Non when false', () => {
    const cell = baggageItemsColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ is_packed: false }) }))
    expect(container.textContent).toBe('Non')
  })

  it('id cell truncates to first 8 chars', () => {
    const cell = baggageItemsColumns[0].cell as any
    const { container } = render(cell({ row: makeMockRow({ id: 'abcdefghij1234' }) }))
    expect(container.textContent).toBe('abcdefgh...')
  })

  it('trip_title shows value when present', () => {
    const cell = baggageItemsColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: 'My Trip' }) }))
    expect(container.textContent).toBe('My Trip')
  })

  it('trip_title shows dash when empty', () => {
    const cell = baggageItemsColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ trip_title: '' }) }))
    expect(container.textContent).toBe('—')
  })

  it('user_email renders email', () => {
    const cell = baggageItemsColumns[2].cell as any
    const { container } = render(cell({ row: makeMockRow({ user_email: 'a@b.com' }) }))
    expect(container.textContent).toBe('a@b.com')
  })

  it('name renders text', () => {
    const cell = baggageItemsColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ name: 'Backpack' }) }))
    expect(container.textContent).toBe('Backpack')
  })

  it('quantity shows value when present', () => {
    const cell = baggageItemsColumns[5].cell as any
    const { container } = render(cell({ row: makeMockRow({ quantity: 3 }) }))
    expect(container.textContent).toBe('3')
  })

  it('is_packed true has success color', () => {
    const cell = baggageItemsColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ is_packed: true }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('text-success')
  })

  it('is_packed false has secondary color', () => {
    const cell = baggageItemsColumns[6].cell as any
    const { container } = render(cell({ row: makeMockRow({ is_packed: false }) }))
    const span = container.querySelector('span')
    expect(span?.className).toContain('bg-secondary')
  })

  it('created_at formats a valid date', () => {
    const cell = baggageItemsColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: '2024-01-15T09:00:00Z' }) }))
    expect(container.textContent).toMatch(/15\/01\/2024/)
  })

  it('created_at shows dash for null', () => {
    const cell = baggageItemsColumns[7].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: null }) }))
    expect(container.textContent).toBe('—')
  })
})
