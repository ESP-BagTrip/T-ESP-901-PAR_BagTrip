import { describe, it, expect } from 'vitest'
import {
  formatDate,
  formatDateTime,
  formatRelativeTime,
  formatCurrency,
  formatNumber,
  formatPercentage,
  truncateText,
} from '../format'

describe('format utilities', () => {
  describe('formatDate', () => {
    it('formats a date string with default format', () => {
      const result = formatDate('2024-01-15T10:30:00Z')
      expect(result).toBe('15/01/2024')
    })

    it('formats a Date object', () => {
      const result = formatDate(new Date(2024, 0, 15))
      expect(result).toBe('15/01/2024')
    })

    it('accepts a custom format string', () => {
      const result = formatDate('2024-01-15T10:30:00Z', 'yyyy-MM-dd')
      expect(result).toBe('2024-01-15')
    })
  })

  describe('formatDateTime', () => {
    it('formats a date string with time', () => {
      const result = formatDateTime('2024-01-15T10:30:00Z')
      // Exact output depends on timezone, but should contain date and time
      expect(result).toMatch(/15\/01\/2024/)
      expect(result).toMatch(/\d{2}:\d{2}/)
    })

    it('formats a Date object with time', () => {
      const date = new Date(2024, 0, 15, 10, 30)
      const result = formatDateTime(date)
      expect(result).toMatch(/15\/01\/2024/)
    })
  })

  describe('formatRelativeTime', () => {
    it('returns a relative time string', () => {
      const recentDate = new Date(Date.now() - 1000 * 60 * 5) // 5 minutes ago
      const result = formatRelativeTime(recentDate)
      expect(result).toBeTruthy()
      expect(typeof result).toBe('string')
    })

    it('works with a date string', () => {
      const result = formatRelativeTime('2020-01-01T00:00:00Z')
      expect(result).toBeTruthy()
      // Should contain "il y a" (French for "ago")
      expect(result).toContain('il y a')
    })
  })

  describe('formatCurrency', () => {
    it('formats a number as EUR currency', () => {
      const result = formatCurrency(1234.56)
      // French locale uses non-breaking space and comma
      expect(result).toContain('1')
      expect(result).toContain('234')
      expect(result).toContain('€')
    })

    it('formats a number with custom currency', () => {
      const result = formatCurrency(1000, 'USD')
      expect(result).toContain('$')
    })

    it('formats zero', () => {
      const result = formatCurrency(0)
      expect(result).toContain('0')
      expect(result).toContain('€')
    })
  })

  describe('formatNumber', () => {
    it('formats a number with French locale separators', () => {
      const result = formatNumber(1234567)
      // French locale uses non-breaking space as thousands separator
      expect(result).toContain('1')
      expect(result).toContain('234')
      expect(result).toContain('567')
    })

    it('formats small numbers', () => {
      expect(formatNumber(42)).toBe('42')
    })

    it('formats zero', () => {
      expect(formatNumber(0)).toBe('0')
    })
  })

  describe('formatPercentage', () => {
    it('formats a percentage with default decimals', () => {
      expect(formatPercentage(75.5)).toBe('75.5%')
    })

    it('formats with custom decimal places', () => {
      expect(formatPercentage(33.3333, 2)).toBe('33.33%')
    })

    it('formats zero', () => {
      expect(formatPercentage(0)).toBe('0.0%')
    })

    it('formats 100', () => {
      expect(formatPercentage(100, 0)).toBe('100%')
    })
  })

  describe('truncateText', () => {
    it('returns text unchanged when shorter than maxLength', () => {
      expect(truncateText('hello', 10)).toBe('hello')
    })

    it('returns text unchanged when exactly maxLength', () => {
      expect(truncateText('hello', 5)).toBe('hello')
    })

    it('truncates text and adds ellipsis when longer than maxLength', () => {
      expect(truncateText('hello world', 5)).toBe('hello...')
    })

    it('handles empty string', () => {
      expect(truncateText('', 5)).toBe('')
    })
  })
})
