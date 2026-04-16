import { describe, it, expect, vi } from 'vitest'
import { render } from '@testing-library/react'
import { usersColumns } from './columns'

// Mock dependencies needed by the PlanCell component
vi.mock('@tanstack/react-query', () => ({
  useQueryClient: vi.fn(() => ({
    invalidateQueries: vi.fn(),
  })),
}))

vi.mock('@/services', () => ({
  adminService: {
    updateUserPlan: vi.fn(),
  },
}))

vi.mock('sonner', () => ({
  toast: {
    success: vi.fn(),
    error: vi.fn(),
  },
}))

function makeMockRow(data: Record<string, unknown>) {
  return {
    getValue: (key: string) => data[key],
    original: data,
  } as never
}

describe('usersColumns', () => {
  it('defines the expected columns', () => {
    const ids = usersColumns.map(c => (c as any).accessorKey)
    expect(ids).toEqual(['id', 'email', 'plan', 'created_at', 'updated_at'])
  })

  it('has correct headers', () => {
    const headers = usersColumns.map(c => c.header)
    expect(headers).toEqual(['ID', 'Email', 'Plan', 'Créé le', 'Modifié le'])
  })

  it('ID cell truncates to first 8 chars', () => {
    const cell = usersColumns[0].cell as any
    const { container } = render(cell({ row: makeMockRow({ id: 'abcdefghij1234' }) }))
    expect(container.textContent).toBe('abcdefgh...')
  })

  it('email cell renders email text', () => {
    const cell = usersColumns[1].cell as any
    const { container } = render(cell({ row: makeMockRow({ email: 'test@example.com' }) }))
    expect(container.textContent).toBe('test@example.com')
  })

  it('plan cell renders a select with PLAN_OPTIONS', () => {
    const cell = usersColumns[2].cell as any
    const { container } = render(
      cell({ row: makeMockRow({ plan: 'FREE', id: 'user-1' }) })
    )
    const select = container.querySelector('select')
    expect(select).toBeTruthy()
    expect(select?.value).toBe('FREE')
    const options = container.querySelectorAll('option')
    expect(options).toHaveLength(3)
    expect(Array.from(options).map((o: HTMLOptionElement) => o.value)).toEqual([
      'FREE',
      'PREMIUM',
      'ADMIN',
    ])
  })

  it('plan cell defaults to FREE when plan is empty', () => {
    const cell = usersColumns[2].cell as any
    const { container } = render(
      cell({ row: makeMockRow({ plan: '', id: 'user-2' }) })
    )
    const select = container.querySelector('select')
    expect(select?.value).toBe('FREE')
  })

  it('created_at formats a valid date', () => {
    const cell = usersColumns[3].cell as any
    const { container } = render(
      cell({ row: makeMockRow({ created_at: '2024-01-15T09:00:00Z' }) })
    )
    expect(container.textContent).toMatch(/15\/01\/2024/)
  })

  it('updated_at shows dash for null', () => {
    const cell = usersColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ updated_at: null }) }))
    expect(container.textContent).toBe('—')
  })

  it('updated_at formats a valid date', () => {
    const cell = usersColumns[4].cell as any
    const { container } = render(cell({ row: makeMockRow({ updated_at: '2024-06-15T10:30:00Z' }) }))
    expect(container.textContent).toMatch(/15\/06\/2024/)
  })

  it('plan cell renders PREMIUM with warning color', () => {
    const cell = usersColumns[2].cell as any
    const { container } = render(
      cell({ row: makeMockRow({ plan: 'PREMIUM', id: 'user-3' }) })
    )
    const select = container.querySelector('select')
    expect(select?.className).toContain('text-warning')
    expect(select?.value).toBe('PREMIUM')
  })

  it('plan cell renders ADMIN with primary color', () => {
    const cell = usersColumns[2].cell as any
    const { container } = render(
      cell({ row: makeMockRow({ plan: 'ADMIN', id: 'user-4' }) })
    )
    const select = container.querySelector('select')
    expect(select?.className).toContain('text-primary')
    expect(select?.value).toBe('ADMIN')
  })

  it('created_at shows dash for null', () => {
    const cell = usersColumns[3].cell as any
    const { container } = render(cell({ row: makeMockRow({ created_at: null }) }))
    expect(container.textContent).toBe('—')
  })
})
