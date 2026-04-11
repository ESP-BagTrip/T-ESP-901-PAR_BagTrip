/**
 * Group an array by a string key accessor, counting occurrences.
 * Returns entries sorted by count desc.
 */
export function countBy<T>(
  items: readonly T[],
  key: (item: T) => string | null | undefined
): Array<{ name: string; value: number }> {
  const counts = new Map<string, number>()
  for (const item of items) {
    const k = key(item) ?? 'UNKNOWN'
    counts.set(k, (counts.get(k) ?? 0) + 1)
  }
  return Array.from(counts.entries())
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => b.value - a.value)
}
