import { describe, it, expect } from 'vitest'
import { safeFormatDate } from './date'

describe('safeFormatDate', () => {
  it('returns dash for null', () => {
    expect(safeFormatDate(null)).toBe('—')
  })

  it('returns dash for undefined', () => {
    expect(safeFormatDate(undefined)).toBe('—')
  })

  it('returns dash for empty string', () => {
    expect(safeFormatDate('')).toBe('—')
  })

  it('formats a valid ISO date with default format', () => {
    expect(safeFormatDate('2024-03-15')).toBe('15/03/2024')
  })

  it('formats a valid ISO datetime with default format', () => {
    expect(safeFormatDate('2024-03-15T10:30:00Z')).toMatch(/15\/03\/2024/)
  })

  it('formats with a custom format string', () => {
    expect(safeFormatDate('2024-03-15', 'yyyy-MM-dd')).toBe('2024-03-15')
  })

  it('formats with time format', () => {
    const result = safeFormatDate('2024-03-15T10:30:00', 'dd/MM/yyyy HH:mm')
    expect(result).toBe('15/03/2024 10:30')
  })

  it('returns dash for an invalid date string', () => {
    expect(safeFormatDate('not-a-date')).toBe('—')
  })

  it('returns dash for a malformed ISO string', () => {
    expect(safeFormatDate('2024-99-99')).toBe('—')
  })

  it('handles date-only ISO string correctly', () => {
    expect(safeFormatDate('2023-01-01')).toBe('01/01/2023')
  })

  it('handles ISO string with timezone offset', () => {
    const result = safeFormatDate('2024-06-15T14:30:00+02:00', 'yyyy-MM-dd')
    expect(result).toMatch(/2024-06-15/)
  })
})
