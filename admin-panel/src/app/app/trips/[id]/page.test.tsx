import { render, screen, act } from '@testing-library/react'
import { Suspense } from 'react'

vi.mock('next/link', () => ({
  default: ({ children, href }: { children: React.ReactNode; href: string }) => (
    <a href={href}>{children}</a>
  ),
}))
vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: vi.fn(), replace: vi.fn(), back: vi.fn() }),
}))
vi.mock('@tanstack/react-query', () => ({
  useQuery: vi.fn(() => ({
    data: {
      id: 'trip-123',
      title: 'Paris to Rome',
      destination_name: 'Rome',
      destination_iata: 'ROM',
      start_date: '2024-01-10',
      end_date: '2024-01-13',
      status: 'PLANNED',
      user_id: 'user-1',
      user_email: 'test@example.com',
      budget_total: 1500,
      nb_travelers: 2,
      origin: 'Paris',
      activities_count: 3,
      accommodations_count: 1,
      shares_count: 1,
      archived_at: null,
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
  Button: ({ children, ...props }: React.ComponentProps<'button'> & { asChild?: boolean }) => (
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
vi.mock('@/components/ui/tabs', () => ({
  Tabs: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  TabsContent: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  TabsList: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  TabsTrigger: ({ children }: { children: React.ReactNode }) => <button>{children}</button>,
}))
vi.mock('@/services', () => ({
  adminService: { getTripDetail: vi.fn() },
}))
vi.mock('@/utils/date', () => ({
  safeFormatDate: vi.fn(() => '10/01/2024'),
}))
vi.mock('@/utils/format', () => ({
  formatCurrency: vi.fn(() => '1 500,00 EUR'),
  formatNumber: vi.fn((v: unknown) => String(v ?? '0')),
}))
vi.mock('@/features/trips/mutations', () => ({
  useArchiveTrip: vi.fn(() => ({ mutate: vi.fn(), isPending: false })),
  useDeleteTrip: vi.fn(() => ({ mutate: vi.fn(), isPending: false })),
}))

import TripDetailPage from './page'

async function renderPage() {
  const params = Promise.resolve({ id: '123' })
  await act(async () => {
    render(
      <Suspense fallback={<div>Loading...</div>}>
        <TripDetailPage params={params} />
      </Suspense>
    )
    await params
  })
}

describe('TripDetailPage', () => {
  it('renders without crashing', async () => {
    await renderPage()
    expect(screen.getByText('Paris to Rome')).toBeInTheDocument()
  })

  it('renders info card', async () => {
    await renderPage()
    expect(screen.getByText('Informations')).toBeInTheDocument()
  })

  it('renders tabs', async () => {
    await renderPage()
    expect(screen.getByText("Vue d'ensemble")).toBeInTheDocument()
  })
})
