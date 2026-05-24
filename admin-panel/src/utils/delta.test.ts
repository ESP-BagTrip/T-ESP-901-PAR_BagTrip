import { describe, expect, it } from 'vitest'

import { computeDelta, sumSeries, windowDelta } from './delta'

describe('computeDelta', () => {
  it('returns a positive percentage when current > previous', () => {
    expect(computeDelta(120, 100)).toBeCloseTo(20)
  })

  it('returns a negative percentage when current < previous', () => {
    expect(computeDelta(80, 100)).toBeCloseTo(-20)
  })

  it('returns 0 when both values are equal', () => {
    expect(computeDelta(100, 100)).toBe(0)
  })

  it('returns 0 when both values are 0', () => {
    expect(computeDelta(0, 0)).toBe(0)
  })

  it('returns null when previous is 0 and current is not', () => {
    expect(computeDelta(50, 0)).toBeNull()
  })

  it('returns null when either input is not finite', () => {
    expect(computeDelta(Number.NaN, 10)).toBeNull()
    expect(computeDelta(10, Number.POSITIVE_INFINITY)).toBeNull()
  })
})

describe('sumSeries', () => {
  it('sums the value field', () => {
    expect(sumSeries([{ value: 1 }, { value: 2 }, { value: 3 }])).toBe(6)
  })

  it('returns 0 on empty input', () => {
    expect(sumSeries([])).toBe(0)
  })

  it('treats undefined values as 0', () => {
    expect(sumSeries([{ value: 5 }, { value: undefined as unknown as number }])).toBe(5)
  })
})

describe('windowDelta', () => {
  it('splits a series in half and returns current/previous sums + delta', () => {
    const series = [{ value: 10 }, { value: 10 }, { value: 20 }, { value: 20 }]
    const result = windowDelta(series)
    expect(result.previousSum).toBe(20)
    expect(result.currentSum).toBe(40)
    expect(result.delta).toBeCloseTo(100)
  })

  it('returns delta=null when series has fewer than 2 points', () => {
    expect(windowDelta([{ value: 5 }]).delta).toBeNull()
    expect(windowDelta([]).delta).toBeNull()
  })

  it('handles odd-length series by rounding down the midpoint', () => {
    const series = [{ value: 5 }, { value: 10 }, { value: 15 }]
    const result = windowDelta(series)
    expect(result.previousSum).toBe(5)
    expect(result.currentSum).toBe(25)
  })
})
