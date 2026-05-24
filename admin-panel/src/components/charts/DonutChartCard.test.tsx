import { render, screen } from '@testing-library/react'

vi.mock('recharts', () => ({
  ResponsiveContainer: ({ children }: any) => (
    <div data-testid="responsive-container">{children}</div>
  ),
  PieChart: ({ children }: any) => <div data-testid="pie-chart">{children}</div>,
  Pie: ({ children }: any) => <div data-testid="pie">{children}</div>,
  Cell: () => null,
  Tooltip: () => null,
}))

vi.mock('@/components/ui/chart', () => ({
  ChartContainer: ({ children }: any) => <div data-testid="chart-container">{children}</div>,
  ChartTooltip: () => null,
  ChartTooltipContent: () => null,
}))

import { DonutChartCard } from './DonutChartCard'

const mockData = [
  { name: 'Active', value: 60 },
  { name: 'Inactive', value: 30 },
  { name: 'Pending', value: 10 },
]

describe('DonutChartCard', () => {
  it('renders title', () => {
    render(<DonutChartCard title="User Status" data={mockData} />)
    expect(screen.getByText('User Status')).toBeInTheDocument()
  })

  it('shows loading skeleton', () => {
    const { container } = render(<DonutChartCard title="User Status" data={[]} isLoading />)
    const skeletons = container.querySelectorAll('[class*="animate-pulse"], [data-slot="skeleton"]')
    expect(skeletons.length).toBeGreaterThan(0)
  })

  it('renders legend items from data', () => {
    render(<DonutChartCard title="User Status" data={mockData} />)
    expect(screen.getByText('Active')).toBeInTheDocument()
    expect(screen.getByText('Inactive')).toBeInTheDocument()
    expect(screen.getByText('Pending')).toBeInTheDocument()
  })
})
