import { format, isValid, parseISO } from 'date-fns'

/**
 * Safely format a date string, returning '—' if the date is invalid or null
 */
export function safeFormatDate(
  date: string | null | undefined,
  formatStr: string = 'dd/MM/yyyy'
): string {
  if (!date) return '—'

  try {
    const parsedDate = typeof date === 'string' ? parseISO(date) : date
    if (!isValid(parsedDate)) {
      return '—'
    }
    return format(parsedDate, formatStr)
  } catch {
    return '—'
  }
}
