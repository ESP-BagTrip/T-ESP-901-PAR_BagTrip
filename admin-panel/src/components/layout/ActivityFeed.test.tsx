import { render, screen } from '@testing-library/react'
import { ActivityFeed } from './ActivityFeed'
import type { ActivityLog } from '@/types'

vi.mock('@/utils/format', () => ({
  formatRelativeTime: (ts: string) => `formatted:${ts}`,
}))

const mockItems: ActivityLog[] = [
  {
    id: '1',
    userId: 'u1',
    user: { firstName: 'John', lastName: 'Doe', email: 'john@test.com' },
    action: 'created',
    resource: 'trip',
    timestamp: '2024-01-01T00:00:00Z',
    ipAddress: '127.0.0.1',
  },
  {
    id: '2',
    userId: 'u2',
    user: { firstName: 'Jane', lastName: 'Doe', email: 'jane@test.com' },
    action: 'updated',
    resource: 'user',
    timestamp: '2024-01-02T00:00:00Z',
    ipAddress: '127.0.0.1',
  },
]

describe('ActivityFeed', () => {
  it('renders activity items', () => {
    render(<ActivityFeed items={mockItems} />)
    expect(screen.getByText('john@test.com')).toBeInTheDocument()
    expect(screen.getByText('jane@test.com')).toBeInTheDocument()
    expect(screen.getByText(/created trip/)).toBeInTheDocument()
    expect(screen.getByText(/updated user/)).toBeInTheDocument()
  })

  it('shows loading skeleton when isLoading', () => {
    const { container } = render(<ActivityFeed items={[]} isLoading />)
    // Skeleton elements are rendered (5 skeleton groups)
    const skeletons = container.querySelectorAll('[class*="animate-pulse"], [data-slot="skeleton"]')
    expect(skeletons.length).toBeGreaterThan(0)
  })

  it('shows empty state when items is empty', () => {
    render(<ActivityFeed items={[]} />)
    expect(screen.getByText('Aucune activité récente')).toBeInTheDocument()
  })
})
