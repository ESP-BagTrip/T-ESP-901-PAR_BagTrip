import { render, screen } from '@testing-library/react'
import { DistributionChartCard } from './DistributionChartCard'

const mockData = [
  { name: '5 stars', value: 50 },
  { name: '4 stars', value: 30 },
  { name: '3 stars', value: 10 },
]

describe('DistributionChartCard', () => {
  it('renders title', () => {
    render(<DistributionChartCard title="Ratings" data={mockData} />)
    expect(screen.getByText('Ratings')).toBeInTheDocument()
  })

  it('renders distribution bars from data', () => {
    render(<DistributionChartCard title="Ratings" data={mockData} />)
    expect(screen.getByText('5 stars')).toBeInTheDocument()
    expect(screen.getByText('4 stars')).toBeInTheDocument()
    expect(screen.getByText('3 stars')).toBeInTheDocument()
    expect(screen.getByText('50')).toBeInTheDocument()
    expect(screen.getByText('30')).toBeInTheDocument()
    expect(screen.getByText('10')).toBeInTheDocument()
  })

  it('shows loading state', () => {
    const { container } = render(<DistributionChartCard title="Ratings" data={[]} isLoading />)
    const skeletons = container.querySelectorAll('[class*="animate-pulse"], [data-slot="skeleton"]')
    expect(skeletons.length).toBeGreaterThan(0)
  })
})
