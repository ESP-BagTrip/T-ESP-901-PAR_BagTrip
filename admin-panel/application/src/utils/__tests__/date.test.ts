import { describe, it, expect } from 'vitest'
import { safeFormatDate } from '@/utils/date'

describe('safeFormatDate', () => {
  it('should format a valid ISO date string', () => {
    expect(safeFormatDate('2024-03-15')).toBe('15/03/2024')
  })

  it('should return dash for null', () => {
    expect(safeFormatDate(null)).toBe('\u2014')
  })

  it('should return dash for undefined', () => {
    expect(safeFormatDate(undefined)).toBe('\u2014')
  })

  it('should return dash for invalid string', () => {
    expect(safeFormatDate('not-a-date')).toBe('\u2014')
  })

  it('should return dash for empty string', () => {
    expect(safeFormatDate('')).toBe('\u2014')
  })

  it('should use a custom format string', () => {
    expect(safeFormatDate('2024-03-15', 'yyyy-MM-dd')).toBe('2024-03-15')
  })

  it('should format with time when format includes time', () => {
    const result = safeFormatDate('2024-03-15T14:30:00Z', 'dd/MM/yyyy HH:mm')
    expect(result).toMatch(/^15\/03\/2024 \d{2}:\d{2}$/)
  })
})
