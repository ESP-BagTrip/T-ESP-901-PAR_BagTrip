import { describe, expect, it } from 'vitest'

import {
  formatDate,
  formatDateTime,
  formatRelativeTime,
  formatCurrency,
  formatNumber,
  formatPercentage,
  formatRating,
  truncateText,
} from './format'

describe('formatDate', () => {
  it('formats a Date object with default dd/MM/yyyy format', () => {
    expect(formatDate(new Date(2024, 2, 15))).toBe('15/03/2024')
  })

  it('formats a date string with default format', () => {
    expect(formatDate('2024-03-15T00:00:00')).toBe('15/03/2024')
  })

  it('formats with a custom format string', () => {
    expect(formatDate(new Date(2024, 2, 15), 'yyyy-MM-dd')).toBe('2024-03-15')
  })

  it('uses French locale (month names)', () => {
    const result = formatDate(new Date(2024, 0, 1), 'MMMM')
    expect(result.toLowerCase()).toBe('janvier')
  })
})

describe('formatDateTime', () => {
  it('formats a Date object with date and time', () => {
    expect(formatDateTime(new Date(2024, 2, 15, 14, 30))).toBe('15/03/2024 14:30')
  })

  it('formats a date string with date and time', () => {
    expect(formatDateTime('2024-03-15T14:30:00')).toBe('15/03/2024 14:30')
  })

  it('shows midnight correctly', () => {
    expect(formatDateTime(new Date(2024, 0, 1, 0, 0))).toBe('01/01/2024 00:00')
  })
})

describe('formatRelativeTime', () => {
  it('returns a French relative string with "il y a" for a past Date', () => {
    const pastDate = new Date(Date.now() - 3600 * 1000)
    const result = formatRelativeTime(pastDate)
    expect(result).toContain('il y a')
  })

  it('returns a relative string for a date string', () => {
    const pastDate = new Date(Date.now() - 86400 * 1000).toISOString()
    const result = formatRelativeTime(pastDate)
    expect(typeof result).toBe('string')
    expect(result.length).toBeGreaterThan(0)
  })

  it('handles a very recent date', () => {
    const recent = new Date(Date.now() - 5000) // 5 seconds ago
    const result = formatRelativeTime(recent)
    expect(result).toContain('il y a')
  })
})

describe('formatNumber', () => {
  it('formats integers with French thousand separators', () => {
    expect(formatNumber(1234)).toMatch(/1.234/)
    expect(formatNumber(1_000_000)).toMatch(/1.000.000/)
  })

  it('returns "---" for null, undefined, or NaN', () => {
    expect(formatNumber(null)).toBe('\u2014')
    expect(formatNumber(undefined)).toBe('\u2014')
    expect(formatNumber(Number.NaN)).toBe('\u2014')
  })

  it('returns "---" for Infinity', () => {
    expect(formatNumber(Infinity)).toBe('\u2014')
    expect(formatNumber(-Infinity)).toBe('\u2014')
  })

  it('drops fraction digits by default', () => {
    expect(formatNumber(42.7)).toMatch(/^43$/)
  })

  it('formats zero', () => {
    expect(formatNumber(0)).toBe('0')
  })

  it('formats negative numbers', () => {
    const result = formatNumber(-1234)
    expect(result).toMatch(/1.234/)
  })
})

describe('formatCurrency', () => {
  it('defaults to EUR', () => {
    expect(formatCurrency(1234)).toContain('\u20ac')
  })

  it('respects the currency option', () => {
    expect(formatCurrency(1234, { currency: 'USD' })).toMatch(/\$|US\$/)
  })

  it('returns "---" on nullish input', () => {
    expect(formatCurrency(null)).toBe('\u2014')
    expect(formatCurrency(undefined)).toBe('\u2014')
  })

  it('returns "---" for NaN and Infinity', () => {
    expect(formatCurrency(NaN)).toBe('\u2014')
    expect(formatCurrency(Infinity)).toBe('\u2014')
  })

  it('hides cents by default but shows them in precise mode', () => {
    expect(formatCurrency(10.5)).not.toMatch(/,5/)
    expect(formatCurrency(10.5, { precise: true })).toMatch(/10,50/)
  })

  it('formats zero', () => {
    const result = formatCurrency(0)
    expect(result).toMatch(/0/)
    expect(result).toContain('\u20ac')
  })

  it('formats negative amounts', () => {
    const result = formatCurrency(-50)
    expect(result).toMatch(/50/)
  })
})

describe('formatPercentage', () => {
  it('appends % with one decimal by default', () => {
    expect(formatPercentage(12.34)).toBe('12.3%')
  })

  it('honors decimals arg', () => {
    expect(formatPercentage(12.34, 2)).toBe('12.34%')
  })

  it('formats with 0 decimals', () => {
    expect(formatPercentage(85.456, 0)).toBe('85%')
  })

  it('returns "---" on nullish input', () => {
    expect(formatPercentage(null)).toBe('\u2014')
    expect(formatPercentage(undefined)).toBe('\u2014')
  })

  it('returns "---" for NaN', () => {
    expect(formatPercentage(NaN)).toBe('\u2014')
  })

  it('formats zero', () => {
    expect(formatPercentage(0)).toBe('0.0%')
  })
})

describe('formatRating', () => {
  it('formats as X.X / 5', () => {
    expect(formatRating(4.2)).toBe('4.2 / 5')
  })

  it('formats integer with one decimal', () => {
    expect(formatRating(3)).toBe('3.0 / 5')
  })

  it('returns "---" when missing', () => {
    expect(formatRating(null)).toBe('\u2014')
    expect(formatRating(undefined)).toBe('\u2014')
    expect(formatRating(Number.NaN)).toBe('\u2014')
  })

  it('formats zero', () => {
    expect(formatRating(0)).toBe('0.0 / 5')
  })
})

describe('truncateText', () => {
  it('leaves short text intact', () => {
    expect(truncateText('hello', 10)).toBe('hello')
  })

  it('returns full text when exactly maxLength', () => {
    expect(truncateText('hello', 5)).toBe('hello')
  })

  it('truncates and appends ellipsis on longer text', () => {
    expect(truncateText('abcdefghij', 5)).toBe('abcde...')
  })

  it('truncates to 0 characters', () => {
    expect(truncateText('hello', 0)).toBe('...')
  })

  it('handles empty string', () => {
    expect(truncateText('', 5)).toBe('')
  })

  it('handles single character truncation', () => {
    expect(truncateText('ab', 1)).toBe('a...')
  })

  it('handles whitespace-only text', () => {
    expect(truncateText('   ', 2)).toBe('  ...')
  })
})
