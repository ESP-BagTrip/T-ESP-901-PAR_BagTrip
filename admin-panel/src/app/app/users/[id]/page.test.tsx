import { render, screen, act } from '@testing-library/react'
import { Suspense } from 'react'

vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: vi.fn(), replace: vi.fn(), back: vi.fn() }),
}))
vi.mock('@tanstack/react-query', () => ({
  useQuery: vi.fn(() => ({
    data: {
      id: 'user-123',
      email: 'admin@bagtrip.com',
      full_name: 'Admin User',
      phone: '+33600000000',
      plan: 'ADMIN',
      plan_expires_at: null,
      banned_at: null,
      ban_reason: null,
      trips_count: 5,
      bookings_count: 3,
      ai_generations_count: 10,
      ai_generations_reset_at: null,
      created_at: '2024-01-01T00:00:00Z',
    },
    isLoading: false,
  })),
}))
vi.mock('@/components/layout/PageHeader', () => ({
  PageHeader: ({ title, description }: { title: string; description: string }) => (
    <div>
      <h1>{title}</h1>
      <p>{description}</p>
    </div>
  ),
}))
vi.mock('@/components/ConfirmDialog', () => ({
  ConfirmDialog: () => null,
}))
vi.mock('@/components/ui/badge', () => ({
  Badge: ({ children }: { children: React.ReactNode }) => <span>{children}</span>,
}))
vi.mock('@/components/ui/button', () => ({
  Button: ({ children, ...props }: React.ComponentProps<'button'>) => (
    <button {...props}>{children}</button>
  ),
}))
vi.mock('@/components/ui/card', () => ({
  Card: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  CardContent: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  CardHeader: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  CardTitle: ({ children }: { children: React.ReactNode }) => <h3>{children}</h3>,
}))
vi.mock('@/components/ui/skeleton', () => ({
  Skeleton: () => <div data-testid="skeleton" />,
}))
vi.mock('@/services', () => ({
  adminService: { getUserDetail: vi.fn() },
}))
vi.mock('@/utils/date', () => ({
  safeFormatDate: vi.fn(() => '01/01/2024'),
}))
vi.mock('@/utils/format', () => ({
  formatNumber: vi.fn((v: unknown) => String(v ?? '0')),
}))
vi.mock('@/features/users/components/UserEditSheet', () => ({
  UserEditSheet: () => null,
}))
vi.mock('@/features/users/mutations', () => ({
  useBanUser: vi.fn(() => ({ mutate: vi.fn(), isPending: false })),
  useUnbanUser: vi.fn(() => ({ mutate: vi.fn(), isPending: false })),
  useDeleteUser: vi.fn(() => ({ mutate: vi.fn(), isPending: false })),
  useResetAiQuota: vi.fn(() => ({ mutate: vi.fn(), isPending: false })),
}))

import UserDetailPage from './page'

async function renderPage() {
  const params = Promise.resolve({ id: '123' })
  await act(async () => {
    render(
      <Suspense fallback={<div>Loading...</div>}>
        <UserDetailPage params={params} />
      </Suspense>
    )
    await params
  })
}

describe('UserDetailPage', () => {
  it('renders without crashing', async () => {
    await renderPage()
    expect(screen.getAllByText('admin@bagtrip.com').length).toBeGreaterThan(0)
  })

  it('renders profile card', async () => {
    await renderPage()
    expect(screen.getByText('Profil')).toBeInTheDocument()
  })

  it('renders AI quota card', async () => {
    await renderPage()
    expect(screen.getByText('Quotas IA')).toBeInTheDocument()
  })
})
