import { render, screen } from '@testing-library/react'

vi.mock('recharts', () => ({
  ResponsiveContainer: ({ children }: any) => <div data-testid="responsive-container">{children}</div>,
  BarChart: ({ children }: any) => <div data-testid="bar-chart">{children}</div>,
  Bar: () => null,
  XAxis: () => null,
  YAxis: () => null,
  CartesianGrid: () => null,
  Tooltip: () => null,
}))

vi.mock('@/components/ui/chart', () => ({
  ChartContainer: ({ children }: any) => <div data-testid="chart-container">{children}</div>,
  ChartTooltip: () => null,
  ChartTooltipContent: () => null,
}))

import { BarChartCard } from './BarChartCard'

const mockData = [
  { name: 'Jan', value: 10 },
  { name: 'Feb', value: 20 },
]

describe('BarChartCard', () => {
  it('renders title', () => {
    render(<BarChartCard title="Sales" data={mockData} />)
    expect(screen.getByText('Sales')).toBeInTheDocument()
  })

  it('shows loading skeleton when isLoading', () => {
    const { container } = render(<BarChartCard title="Sales" data={[]} isLoading />)
    const skeletons = container.querySelectorAll('[class*="animate-pulse"], [data-slot="skeleton"]')
    expect(skeletons.length).toBeGreaterThan(0)
  })

  it('renders chart when data provided', () => {
    render(<BarChartCard title="Sales" data={mockData} />)
    expect(screen.getByTestId('chart-container')).toBeInTheDocument()
    expect(screen.getByTestId('bar-chart')).toBeInTheDocument()
  })
})
