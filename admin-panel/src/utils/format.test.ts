import { describe, expect, it } from 'vitest'

import {
  formatCurrency,
  formatNumber,
  formatPercentage,
  formatRating,
  truncateText,
} from './format'

describe('formatNumber', () => {
  it('formats integers with French thousand separators', () => {
    // fr-FR uses narrow no-break space (U+202F) as thousand separator
    expect(formatNumber(1234)).toMatch(/1.234/)
    expect(formatNumber(1_000_000)).toMatch(/1.000.000/)
  })

  it('returns "—" for null, undefined, or NaN', () => {
    expect(formatNumber(null)).toBe('—')
    expect(formatNumber(undefined)).toBe('—')
    expect(formatNumber(Number.NaN)).toBe('—')
  })

  it('drops fraction digits by default', () => {
    expect(formatNumber(42.7)).toMatch(/^43$/)
  })
})

describe('formatCurrency', () => {
  it('defaults to EUR', () => {
    expect(formatCurrency(1234)).toContain('€')
  })

  it('respects the currency option', () => {
    expect(formatCurrency(1234, { currency: 'USD' })).toMatch(/\$|US\$/)
  })

  it('returns "—" on nullish input', () => {
    expect(formatCurrency(null)).toBe('—')
    expect(formatCurrency(undefined)).toBe('—')
  })

  it('hides cents by default but shows them in precise mode', () => {
    expect(formatCurrency(10.5)).not.toMatch(/,5/)
    expect(formatCurrency(10.5, { precise: true })).toMatch(/10,50/)
  })
})

describe('formatPercentage', () => {
  it('appends % with one decimal by default', () => {
    expect(formatPercentage(12.34)).toBe('12.3%')
  })

  it('honors decimals arg', () => {
    expect(formatPercentage(12.34, 2)).toBe('12.34%')
  })

  it('returns "—" on nullish input', () => {
    expect(formatPercentage(null)).toBe('—')
  })
})

describe('formatRating', () => {
  it('formats as X.X / 5', () => {
    expect(formatRating(4.2)).toBe('4.2 / 5')
  })

  it('returns "—" when missing', () => {
    expect(formatRating(null)).toBe('—')
    expect(formatRating(Number.NaN)).toBe('—')
  })
})

describe('truncateText', () => {
  it('leaves short text intact', () => {
    expect(truncateText('hello', 10)).toBe('hello')
  })

  it('truncates and appends ellipsis on longer text', () => {
    expect(truncateText('abcdefghij', 5)).toBe('abcde...')
  })
})
