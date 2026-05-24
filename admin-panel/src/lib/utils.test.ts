import { describe, it, expect } from 'vitest'
import { cn } from './utils'

describe('cn', () => {
  it('merges simple class names', () => {
    expect(cn('foo', 'bar')).toBe('foo bar')
  })

  it('handles conditional classes via clsx syntax', () => {
    expect(cn('base', false && 'hidden', 'visible')).toBe('base visible')
  })

  it('merges conflicting tailwind classes (last wins)', () => {
    expect(cn('p-4', 'p-2')).toBe('p-2')
  })

  it('merges conflicting tailwind text colors', () => {
    expect(cn('text-red-500', 'text-blue-500')).toBe('text-blue-500')
  })

  it('handles undefined and null inputs', () => {
    expect(cn('foo', undefined, null, 'bar')).toBe('foo bar')
  })

  it('handles empty string inputs', () => {
    expect(cn('', 'foo', '')).toBe('foo')
  })

  it('handles array inputs', () => {
    expect(cn(['foo', 'bar'])).toBe('foo bar')
  })

  it('handles object inputs', () => {
    expect(cn({ foo: true, bar: false, baz: true })).toBe('foo baz')
  })

  it('returns empty string for no arguments', () => {
    expect(cn()).toBe('')
  })

  it('handles complex tailwind merges', () => {
    const result = cn('px-2 py-1 bg-red-500 hover:bg-red-600', 'bg-blue-500')
    expect(result).toContain('bg-blue-500')
    expect(result).not.toContain('bg-red-500')
    expect(result).toContain('px-2')
  })
})
