import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { TabSkeleton } from '../TabSkeleton'

describe('TabSkeleton', () => {
  it('renders skeleton elements', () => {
    const { container } = render(<TabSkeleton />)
    const skeletons = container.querySelectorAll('.animate-pulse')
    expect(skeletons.length).toBeGreaterThan(0)
  })
})
