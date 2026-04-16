import { render, screen, act } from '@testing-library/react'
import { Suspense } from 'react'

vi.mock('next/link', () => ({
  default: ({ children, href }: { children: React.ReactNode; href: string }) => (
    <a href={href}>{children}</a>
  ),
}))
vi.mock('@tanstack/react-query', () => ({
  useQuery: vi.fn(() => ({
    data: {
      id: '12345678-abcd-efgh-ijkl-123456789012',
      user_id: 'user-1',
      user_email: 'test@example.com',
      trip_id: 'trip-1',
      trip_title: 'Test Trip',
      type: 'flight',
      status: 'INIT',
      amount: 150,
      currency: 'EUR',
      stripe_payment_intent_id: null,
      stripe_charge_id: null,
      amadeus_order_id: null,
      last_error: null,
      created_at: '2024-01-01T00:00:00Z',
      updated_at: '2024-01-01T00:00:00Z',
    },
    isLoading: false,
  })),
}))
vi.mock('@/components/layout/PageHeader', () => ({
  PageHeader: ({ title, description }: { title: string; description: string }) => (
    <div><h1>{title}</h1><p>{description}</p></div>
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
vi.mock('@/components/ui/alert', () => ({
  Alert: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  AlertDescription: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
}))
vi.mock('@/components/ui/skeleton', () => ({
  Skeleton: () => <div data-testid="skeleton" />,
}))
vi.mock('@/components/ui/select', () => ({
  Select: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  SelectContent: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  SelectItem: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  SelectTrigger: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  SelectValue: () => <span />,
}))
vi.mock('@/services', () => ({
  adminService: { getBookingIntentDetail: vi.fn() },
}))
vi.mock('@/utils/date', () => ({
  safeFormatDate: vi.fn(() => '01/01/2024 00:00'),
}))
vi.mock('@/utils/format', () => ({
  formatCurrency: vi.fn(() => '150,00 EUR'),
}))
vi.mock('@/features/booking-intents/mutations', () => ({
  useCancelBooking: vi.fn(() => ({ mutate: vi.fn(), isPending: false })),
  useForceBookingStatus: vi.fn(() => ({ mutate: vi.fn(), isPending: false })),
  useMarkRefunded: vi.fn(() => ({ mutate: vi.fn(), isPending: false })),
}))
vi.mock('@/lib/utils', () => ({
  cn: vi.fn((...args: string[]) => args.filter(Boolean).join(' ')),
}))

import BookingDetailPage from './page'

async function renderPage() {
  const params = Promise.resolve({ id: '123' })
  await act(async () => {
    render(
      <Suspense fallback={<div>Loading...</div>}>
        <BookingDetailPage params={params} />
      </Suspense>
    )
    await params
  })
}

describe('BookingDetailPage', () => {
  it('renders without crashing', async () => {
    await renderPage()
    expect(screen.getByText('Booking #12345678')).toBeInTheDocument()
  })

  it('renders detail cards', async () => {
    await renderPage()
    expect(screen.getByText('Détails')).toBeInTheDocument()
  })

  it('renders timeline', async () => {
    await renderPage()
    expect(screen.getByText('Timeline')).toBeInTheDocument()
  })
})
