import { format, formatDistanceToNow } from 'date-fns'
import { fr } from 'date-fns/locale'
import { DATE_FORMATS } from './constants'

export const formatDate = (date: string | Date, formatString = DATE_FORMATS.DISPLAY): string => {
  const dateObject = typeof date === 'string' ? new Date(date) : date
  return format(dateObject, formatString, { locale: fr })
}

export const formatDateTime = (date: string | Date): string => {
  const dateObject = typeof date === 'string' ? new Date(date) : date
  return format(dateObject, DATE_FORMATS.DISPLAY_WITH_TIME, { locale: fr })
}

export const formatRelativeTime = (date: string | Date): string => {
  const dateObject = typeof date === 'string' ? new Date(date) : date
  return formatDistanceToNow(dateObject, { addSuffix: true, locale: fr })
}

export const formatCurrency = (
  amount: number | null | undefined,
  opts: { currency?: string; precise?: boolean } = {}
): string => {
  if (amount == null || !Number.isFinite(amount)) return '—'
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: opts.currency ?? 'EUR',
    maximumFractionDigits: opts.precise ? 2 : 0,
  }).format(amount)
}

export const formatNumber = (num: number | null | undefined): string => {
  if (num == null || !Number.isFinite(num)) return '—'
  return new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 0 }).format(num)
}

export const formatPercentage = (value: number | null | undefined, decimals = 1): string => {
  if (value == null || !Number.isFinite(value)) return '—'
  return `${value.toFixed(decimals)}%`
}

export const formatRating = (value: number | null | undefined): string => {
  if (value == null || !Number.isFinite(value)) return '—'
  return `${value.toFixed(1)} / 5`
}

export const truncateText = (text: string, maxLength: number): string => {
  if (text.length <= maxLength) return text
  return `${text.slice(0, maxLength)}...`
}
