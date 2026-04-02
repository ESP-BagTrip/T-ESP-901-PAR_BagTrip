import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { Skeleton } from '../skeleton'

describe('Skeleton', () => {
  it('renders div with animate-pulse class', () => {
    const { container } = render(<Skeleton />)
    const div = container.firstChild as HTMLElement
    expect(div.className).toContain('animate-pulse')
  })

  it('supports custom className', () => {
    const { container } = render(<Skeleton className="h-8 w-full" />)
    const div = container.firstChild as HTMLElement
    expect(div.className).toContain('h-8')
    expect(div.className).toContain('w-full')
  })
})
