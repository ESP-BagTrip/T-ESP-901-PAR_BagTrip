import { describe, expect, it } from 'vitest'

import { countBy } from './group-by'

describe('countBy', () => {
  it('counts occurrences by key', () => {
    const trips = [
      { status: 'PLANNED' },
      { status: 'PLANNED' },
      { status: 'COMPLETED' },
      { status: 'DRAFT' },
    ]
    const result = countBy(trips, t => t.status)
    expect(result).toEqual([
      { name: 'PLANNED', value: 2 },
      { name: 'COMPLETED', value: 1 },
      { name: 'DRAFT', value: 1 },
    ])
  })

  it('sorts entries by count descending', () => {
    const items = [
      { cat: 'a' },
      { cat: 'b' },
      { cat: 'b' },
      { cat: 'c' },
      { cat: 'c' },
      { cat: 'c' },
    ]
    const result = countBy(items, i => i.cat)
    expect(result.map(r => r.name)).toEqual(['c', 'b', 'a'])
  })

  it('uses "UNKNOWN" for null/undefined keys', () => {
    const items = [{ status: null }, { status: undefined }, { status: 'FOO' }]
    const result = countBy(items, i => i.status as string | null | undefined)
    expect(result.find(r => r.name === 'UNKNOWN')?.value).toBe(2)
    expect(result.find(r => r.name === 'FOO')?.value).toBe(1)
  })

  it('returns an empty array for empty input', () => {
    expect(countBy([], () => 'x')).toEqual([])
  })
})
