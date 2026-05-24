/**
 * Compute a percentage delta between the current window and the previous window.
 * Returns null if we can't compute a meaningful delta.
 */
export function computeDelta(current: number, previous: number): number | null {
  if (!Number.isFinite(current) || !Number.isFinite(previous)) return null
  if (previous === 0) {
    return current === 0 ? 0 : null
  }
  return ((current - previous) / previous) * 100
}

/**
 * Sum the values of a time-series slice.
 */
export function sumSeries<T extends { value: number }>(series: T[]): number {
  return series.reduce((acc, point) => acc + (point.value ?? 0), 0)
}

/**
 * Given a chronological time-series, return `{ currentSum, previousSum, delta }`.
 * The window is split in two equal halves — the second half is "current".
 */
export function windowDelta<T extends { value: number }>(
  series: T[]
): { currentSum: number; previousSum: number; delta: number | null } {
  if (series.length < 2) {
    return { currentSum: sumSeries(series), previousSum: 0, delta: null }
  }
  const mid = Math.floor(series.length / 2)
  const previousSum = sumSeries(series.slice(0, mid))
  const currentSum = sumSeries(series.slice(mid))
  return { currentSum, previousSum, delta: computeDelta(currentSum, previousSum) }
}
