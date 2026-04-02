import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'

vi.mock('../../hooks', () => ({
  useDashboardMetrics: vi.fn(() => ({
    data: {
      totalUsers: 100,
      activeUsers: 80,
      inactiveUsers: 20,
      totalTrips: 50,
      totalRevenue: 10000,
      totalFeedbacks: 30,
      averageRating: 4.5,
      pendingFeedbacks: 5,
    },
    isLoading: false,
  })),
  useUserRegistrationsChart: vi.fn(() => ({ data: [] })),
  useRevenueChart: vi.fn(() => ({ data: [] })),
  useFeedbacksChart: vi.fn(() => ({ data: [] })),
}))

vi.mock('recharts', () => ({
  ResponsiveContainer: ({ children }: any) => <div>{children}</div>,
  LineChart: ({ children }: any) => <div>{children}</div>,
  BarChart: ({ children }: any) => <div>{children}</div>,
  Line: () => null,
  Bar: () => null,
  XAxis: () => null,
  YAxis: () => null,
  CartesianGrid: () => null,
  Tooltip: () => null,
}))

import DashboardTab from '../DashboardTab'

describe('DashboardTab', () => {
  it('renders metric cards', () => {
    render(<DashboardTab isActive={true} />)
    expect(screen.getByText('Utilisateurs')).toBeInTheDocument()
    expect(screen.getByText('Trips')).toBeInTheDocument()
    expect(screen.getAllByText('Revenus').length).toBeGreaterThan(0)
    expect(screen.getAllByText('Feedbacks').length).toBeGreaterThan(0)
  })

  it('renders metric values', () => {
    render(<DashboardTab isActive={true} />)
    expect(screen.getByText('100')).toBeInTheDocument()
    expect(screen.getByText('50')).toBeInTheDocument()
  })

  it('renders chart titles', () => {
    render(<DashboardTab isActive={true} />)
    expect(screen.getByText('Inscriptions utilisateurs')).toBeInTheDocument()
    expect(screen.getByText('Distribution des feedbacks')).toBeInTheDocument()
  })

  it('shows loading skeleton when metricsLoading is true', async () => {
    const { useDashboardMetrics } = await import('../../hooks')
    vi.mocked(useDashboardMetrics).mockReturnValue({ data: null, isLoading: true } as any)
    const { container } = render(<DashboardTab isActive={true} />)
    expect(container.querySelector('.animate-pulse')).toBeInTheDocument()
  })

  it('shows "Aucune donnée" when chart data is empty', async () => {
    const { useDashboardMetrics } = await import('../../hooks')
    vi.mocked(useDashboardMetrics).mockReturnValue({
      data: {
        totalUsers: 0,
        activeUsers: 0,
        inactiveUsers: 0,
        totalTrips: 0,
        totalRevenue: 0,
        totalFeedbacks: 0,
        averageRating: null,
        pendingFeedbacks: 0,
      },
      isLoading: false,
    } as any)
    render(<DashboardTab isActive={true} />)
    const emptyMessages = screen.getAllByText('Aucune donnée')
    expect(emptyMessages.length).toBeGreaterThanOrEqual(1)
  })
})
