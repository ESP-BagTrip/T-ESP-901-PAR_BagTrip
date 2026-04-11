'use client'

import { useCallback, useMemo } from 'react'
import { usePathname, useRouter, useSearchParams } from 'next/navigation'

export type RangePreset = '7d' | '30d' | '90d' | '1y'

export interface ResolvedRange {
  /** Preset key or 'custom' when absent. */
  preset: RangePreset
  from: Date
  to: Date
  /** Period key compatible with dashboard chart endpoints. */
  apiPeriod: 'week' | 'month' | 'year'
  /** Human-readable label. */
  label: string
}

const DEFAULTS: Record<
  RangePreset,
  { days: number; apiPeriod: 'week' | 'month' | 'year'; label: string }
> = {
  '7d': { days: 7, apiPeriod: 'week', label: '7 derniers jours' },
  '30d': { days: 30, apiPeriod: 'month', label: '30 derniers jours' },
  '90d': { days: 90, apiPeriod: 'month', label: '90 derniers jours' },
  '1y': { days: 365, apiPeriod: 'year', label: '12 derniers mois' },
}

function resolve(preset: RangePreset): ResolvedRange {
  const def = DEFAULTS[preset]
  const to = new Date()
  const from = new Date(to)
  from.setDate(to.getDate() - def.days)
  return { preset, from, to, apiPeriod: def.apiPeriod, label: def.label }
}

/**
 * URL-synced date range state. Source of truth = `?range=` search param.
 * Default when absent: 30d.
 */
export function useDateRange(): ResolvedRange & { setRange: (preset: RangePreset) => void } {
  const router = useRouter()
  const pathname = usePathname()
  const searchParams = useSearchParams()

  const preset = useMemo<RangePreset>(() => {
    const raw = searchParams?.get('range')
    if (raw && raw in DEFAULTS) return raw as RangePreset
    return '30d'
  }, [searchParams])

  const range = useMemo(() => resolve(preset), [preset])

  const setRange = useCallback(
    (next: RangePreset) => {
      const params = new URLSearchParams(searchParams?.toString() ?? '')
      if (next === '30d') {
        params.delete('range')
      } else {
        params.set('range', next)
      }
      const q = params.toString()
      router.replace(q ? `${pathname}?${q}` : (pathname ?? ''), { scroll: false })
    },
    [pathname, router, searchParams]
  )

  return { ...range, setRange }
}

export const RANGE_PRESETS: Array<{ value: RangePreset; label: string }> = [
  { value: '7d', label: '7j' },
  { value: '30d', label: '30j' },
  { value: '90d', label: '90j' },
  { value: '1y', label: '1an' },
]
