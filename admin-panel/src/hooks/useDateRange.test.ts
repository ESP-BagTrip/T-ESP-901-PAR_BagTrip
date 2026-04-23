import { describe, expect, it, vi, beforeEach } from 'vitest'
import { renderHook, act } from '@testing-library/react'

import { RANGE_PRESETS, useDateRange } from './useDateRange'

const mockReplace = vi.fn()
let mockSearchParams = new URLSearchParams('')

vi.mock('next/navigation', () => ({
  useRouter: () => ({ replace: mockReplace }),
  usePathname: () => '/app/dashboard',
  useSearchParams: () => mockSearchParams,
}))

describe('RANGE_PRESETS', () => {
  it('exposes the expected 4 presets in order', () => {
    expect(RANGE_PRESETS.map(p => p.value)).toEqual(['7d', '30d', '90d', '1y'])
  })

  it('has a unique value per preset', () => {
    const values = new Set(RANGE_PRESETS.map(p => p.value))
    expect(values.size).toBe(RANGE_PRESETS.length)
  })

  it('each preset has a non-empty label', () => {
    RANGE_PRESETS.forEach(p => {
      expect(p.label.length).toBeGreaterThan(0)
    })
  })
})

describe('useDateRange (resolve behavior)', () => {
  beforeEach(() => {
    mockReplace.mockClear()
    mockSearchParams = new URLSearchParams('')
  })

  it('defaults to 30d preset when no search param is set', () => {
    const { result } = renderHook(() => useDateRange())
    expect(result.current.preset).toBe('30d')
  })

  it('returns correct apiPeriod for default 30d', () => {
    const { result } = renderHook(() => useDateRange())
    expect(result.current.apiPeriod).toBe('month')
  })

  it('returns correct label for default 30d', () => {
    const { result } = renderHook(() => useDateRange())
    expect(result.current.label).toBe('30 derniers jours')
  })

  it('returns from and to as Date objects', () => {
    const { result } = renderHook(() => useDateRange())
    expect(result.current.from).toBeInstanceOf(Date)
    expect(result.current.to).toBeInstanceOf(Date)
  })

  it('from is 30 days before to for default preset', () => {
    const { result } = renderHook(() => useDateRange())
    const diffMs = result.current.to.getTime() - result.current.from.getTime()
    const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24))
    expect(diffDays).toBe(30)
  })

  it('exposes a setRange function', () => {
    const { result } = renderHook(() => useDateRange())
    expect(typeof result.current.setRange).toBe('function')
  })

  it('setRange with 30d removes range param from URL', () => {
    const { result } = renderHook(() => useDateRange())
    act(() => {
      result.current.setRange('30d')
    })
    expect(mockReplace).toHaveBeenCalledWith('/app/dashboard', { scroll: false })
  })

  it('setRange with 7d sets range param in URL', () => {
    const { result } = renderHook(() => useDateRange())
    act(() => {
      result.current.setRange('7d')
    })
    expect(mockReplace).toHaveBeenCalledWith('/app/dashboard?range=7d', { scroll: false })
  })
})

describe('useDateRange with URL presets', () => {
  beforeEach(() => {
    mockReplace.mockClear()
  })

  it('reads 7d preset from URL search params', () => {
    mockSearchParams = new URLSearchParams('range=7d')
    const { result } = renderHook(() => useDateRange())
    expect(result.current.preset).toBe('7d')
    expect(result.current.apiPeriod).toBe('week')
    expect(result.current.label).toBe('7 derniers jours')
  })

  it('reads 90d preset from URL search params', () => {
    mockSearchParams = new URLSearchParams('range=90d')
    const { result } = renderHook(() => useDateRange())
    expect(result.current.preset).toBe('90d')
    expect(result.current.apiPeriod).toBe('month')
    expect(result.current.label).toBe('90 derniers jours')
  })

  it('reads 1y preset from URL search params', () => {
    mockSearchParams = new URLSearchParams('range=1y')
    const { result } = renderHook(() => useDateRange())
    expect(result.current.preset).toBe('1y')
    expect(result.current.apiPeriod).toBe('year')
    expect(result.current.label).toBe('12 derniers mois')
  })

  it('falls back to 30d for an invalid range search param', () => {
    mockSearchParams = new URLSearchParams('range=invalid')
    const { result } = renderHook(() => useDateRange())
    expect(result.current.preset).toBe('30d')
  })

  it('from is 7 days before to for 7d preset', () => {
    mockSearchParams = new URLSearchParams('range=7d')
    const { result } = renderHook(() => useDateRange())
    const diffMs = result.current.to.getTime() - result.current.from.getTime()
    const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24))
    expect(diffDays).toBe(7)
  })

  it('from is 90 days before to for 90d preset', () => {
    mockSearchParams = new URLSearchParams('range=90d')
    const { result } = renderHook(() => useDateRange())
    const diffMs = result.current.to.getTime() - result.current.from.getTime()
    const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24))
    expect(diffDays).toBe(90)
  })

  it('from is 365 days before to for 1y preset', () => {
    mockSearchParams = new URLSearchParams('range=1y')
    const { result } = renderHook(() => useDateRange())
    const diffMs = result.current.to.getTime() - result.current.from.getTime()
    const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24))
    expect(diffDays).toBe(365)
  })

  it('setRange with 1y sets range param in URL', () => {
    mockSearchParams = new URLSearchParams('')
    const { result } = renderHook(() => useDateRange())
    act(() => {
      result.current.setRange('1y')
    })
    expect(mockReplace).toHaveBeenCalledWith('/app/dashboard?range=1y', { scroll: false })
  })

  it('setRange with 90d sets range param in URL', () => {
    mockSearchParams = new URLSearchParams('')
    const { result } = renderHook(() => useDateRange())
    act(() => {
      result.current.setRange('90d')
    })
    expect(mockReplace).toHaveBeenCalledWith('/app/dashboard?range=90d', { scroll: false })
  })

  it('preserves other URL search params when setting range', () => {
    mockSearchParams = new URLSearchParams('tab=overview')
    const { result } = renderHook(() => useDateRange())
    act(() => {
      result.current.setRange('7d')
    })
    expect(mockReplace).toHaveBeenCalledWith(expect.stringContaining('tab=overview'), {
      scroll: false,
    })
    expect(mockReplace).toHaveBeenCalledWith(expect.stringContaining('range=7d'), { scroll: false })
  })

  it('to date is close to current time', () => {
    mockSearchParams = new URLSearchParams('')
    const before = Date.now()
    const { result } = renderHook(() => useDateRange())
    const after = Date.now()
    expect(result.current.to.getTime()).toBeGreaterThanOrEqual(before - 1000)
    expect(result.current.to.getTime()).toBeLessThanOrEqual(after + 1000)
  })
})
