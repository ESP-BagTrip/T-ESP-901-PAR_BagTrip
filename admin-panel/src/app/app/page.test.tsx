import { render, screen } from '@testing-library/react'

vi.mock('@/components/layout/PageHeader', () => ({
  PageHeader: ({ title, description }: { title: string; description: string }) => (
    <div>
      <h1>{title}</h1>
      <p>{description}</p>
    </div>
  ),
}))
vi.mock('@/components/layout/ActivityFeed', () => ({
  ActivityFeed: () => <div data-testid="activity-feed" />,
}))
vi.mock('@/components/ui/kpi-card', () => ({
  KPICard: ({ label }: { label: string }) => <div data-testid="kpi-card">{label}</div>,
}))
vi.mock('@/components/ui/date-range-picker', () => ({
  DateRangePicker: () => <div data-testid="date-range-picker" />,
}))
vi.mock('@/components/charts/AreaChartCard', () => ({
  AreaChartCard: () => <div data-testid="area-chart" />,
}))
vi.mock('@/components/charts/BarChartCard', () => ({
  BarChartCard: () => <div data-testid="bar-chart" />,
}))
vi.mock('@/components/charts/DonutChartCard', () => ({
  DonutChartCard: () => <div data-testid="donut-chart" />,
}))
vi.mock('@/components/charts/DistributionChartCard', () => ({
  DistributionChartCard: () => <div data-testid="distribution-chart" />,
}))
vi.mock('@/features/dashboard/hooks', () => ({
  useDashboardMetrics: vi.fn(() => ({ data: undefined, isLoading: false })),
  useFeedbacksChart: vi.fn(() => ({ data: [], isLoading: false })),
  useRecentActivity: vi.fn(() => ({ data: { data: [] }, isLoading: false })),
  useRevenueChart: vi.fn(() => ({ data: [], isLoading: false })),
  useTripStatusDistribution: vi.fn(() => ({ data: { items: [] }, isLoading: false })),
  useUserRegistrationsChart: vi.fn(() => ({ data: [], isLoading: false })),
}))
vi.mock('@/hooks/useDateRange', () => ({
  useDateRange: vi.fn(() => ({ apiPeriod: '7d' })),
}))
vi.mock('@/utils/format', () => ({
  formatCurrency: vi.fn((v: unknown) => String(v ?? '—')),
  formatNumber: vi.fn((v: unknown) => String(v ?? '—')),
  formatRating: vi.fn((v: unknown) => String(v ?? '—')),
}))
vi.mock('@/utils/delta', () => ({
  windowDelta: vi.fn(() => ({ delta: null })),
}))
vi.mock('@/utils/group-by', () => ({
  countBy: vi.fn(() => []),
}))

import OverviewPage from './page'

describe('OverviewPage', () => {
  it('renders the overview heading', () => {
    render(<OverviewPage />)
    expect(screen.getByText('Overview')).toBeInTheDocument()
  })

  it('renders KPI cards', () => {
    render(<OverviewPage />)
    expect(screen.getAllByTestId('kpi-card')).toHaveLength(4)
  })

  it('renders chart sections', () => {
    render(<OverviewPage />)
    expect(screen.getByTestId('area-chart')).toBeInTheDocument()
    expect(screen.getByTestId('bar-chart')).toBeInTheDocument()
    expect(screen.getByTestId('donut-chart')).toBeInTheDocument()
    expect(screen.getByTestId('distribution-chart')).toBeInTheDocument()
  })

  it('renders activity feed', () => {
    render(<OverviewPage />)
    expect(screen.getByTestId('activity-feed')).toBeInTheDocument()
  })
})
