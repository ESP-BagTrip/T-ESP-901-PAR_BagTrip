import { describe, expect, it } from 'vitest'

import { RANGE_PRESETS } from './useDateRange'

describe('RANGE_PRESETS', () => {
  it('exposes the expected 4 presets in order', () => {
    expect(RANGE_PRESETS.map(p => p.value)).toEqual(['7d', '30d', '90d', '1y'])
  })

  it('has a unique value per preset', () => {
    const values = new Set(RANGE_PRESETS.map(p => p.value))
    expect(values.size).toBe(RANGE_PRESETS.length)
  })
})
