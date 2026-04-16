import { render, screen } from '@testing-library/react'

vi.mock('@/components/DataTable', () => ({
  DataTable: ({ data, isLoading, pagination }: { data: unknown[]; isLoading: boolean; pagination: { page: number; total: number } }) => (
    <div data-testid="data-table" data-loading={isLoading} data-page={pagination.page} data-total={pagination.total}>{data.length} rows</div>
  ),
}))
vi.mock('@/components/DataTableToolbar', () => ({
  DataTableToolbar: ({ searchValue, onSearch, searchPlaceholder, filters, onReset }: {
    searchValue?: string; onSearch?: (v: string) => void; searchPlaceholder?: string;
    filters?: { key: string; label: string; options: { value: string; label: string }[] }[];
    onReset?: () => void;
  }) => (
    <div data-testid="data-table-toolbar">
      <input data-testid="search-input" value={searchValue ?? ''} onChange={e => onSearch?.(e.target.value)} placeholder={searchPlaceholder} />
      {filters?.map(f => <select key={f.key} data-testid={`filter-${f.key}`}><option>{f.label}</option>{f.options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}</select>)}
      {onReset && <button data-testid="reset-btn" onClick={onReset}>Reset</button>}
    </div>
  ),
}))
vi.mock('@/components/layout/PageHeader', () => ({
  PageHeader: ({ title, description }: { title: string; description: string }) => (
    <div><h1>{title}</h1><p>{description}</p></div>
  ),
}))

const mockSetPage = vi.fn()
vi.mock('@/features/booking-intents/hooks', () => ({
  useBookingIntentsTab: vi.fn(() => ({
    rows: [], isLoading: false, page: 1, limit: 10, total: 0, total_pages: 0,
    setPage: mockSetPage, search: '', setSearch: vi.fn(), filters: {},
    setFilter: vi.fn(), resetFilters: vi.fn(),
  })),
}))
vi.mock('@/features/booking-intents/columns', () => ({ bookingIntentsColumns: [] }))

import { useBookingIntentsTab } from '@/features/booking-intents/hooks'
import BookingIntentsPage from './page'

describe('BookingIntentsPage', () => {
  it('renders the page heading', () => {
    render(<BookingIntentsPage />)
    expect(screen.getByText('Intentions de paiement')).toBeInTheDocument()
  })

  it('renders data table', () => {
    render(<BookingIntentsPage />)
    expect(screen.getByTestId('data-table')).toBeInTheDocument()
  })

  it('renders toolbar with search', () => {
    render(<BookingIntentsPage />)
    expect(screen.getByTestId('search-input')).toBeInTheDocument()
  })

  it('renders status filter', () => {
    render(<BookingIntentsPage />)
    expect(screen.getByTestId('filter-status')).toBeInTheDocument()
  })

  it('renders filter options', () => {
    render(<BookingIntentsPage />)
    expect(screen.getByText('Init')).toBeInTheDocument()
    expect(screen.getByText('Captured')).toBeInTheDocument()
    expect(screen.getByText('Failed')).toBeInTheDocument()
    expect(screen.getByText('Cancelled')).toBeInTheDocument()
  })

  it('renders description', () => {
    render(<BookingIntentsPage />)
    expect(screen.getByText('Funnel Stripe booking intents.')).toBeInTheDocument()
  })

  it('passes loading state', () => {
    vi.mocked(useBookingIntentsTab).mockReturnValueOnce({
      rows: [], isLoading: true, page: 1, limit: 10, total: 0, total_pages: 0,
      setPage: mockSetPage, search: '', setSearch: vi.fn(), filters: {},
      setFilter: vi.fn(), resetFilters: vi.fn(),
    })
    render(<BookingIntentsPage />)
    expect(screen.getByTestId('data-table')).toHaveAttribute('data-loading', 'true')
  })
})
