import { render, screen } from '@testing-library/react'

vi.mock('@/components/DataTable', () => ({
  DataTable: ({ data, isLoading, pagination }: { data: unknown[]; isLoading: boolean; pagination: { page: number; total: number } }) => (
    <div data-testid="data-table" data-loading={isLoading} data-page={pagination.page} data-total={pagination.total}>
      {data.length} rows
    </div>
  ),
}))
vi.mock('@/components/DataTableToolbar', () => ({
  DataTableToolbar: ({ searchValue, onSearch, searchPlaceholder, filters, onReset, activeFilters }: {
    searchValue?: string; onSearch?: (v: string) => void; searchPlaceholder?: string;
    filters?: { key: string; label: string; options: { value: string; label: string }[] }[];
    onReset?: () => void; activeFilters?: Record<string, string | undefined>;
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
const mockSetSearch = vi.fn()
const mockSetFilter = vi.fn()
const mockResetFilters = vi.fn()

vi.mock('@/features/accommodations/hooks', () => ({
  useAccommodationsTab: vi.fn(() => ({
    rows: [], isLoading: false, page: 1, limit: 10, total: 0, total_pages: 0,
    setPage: mockSetPage, search: '', setSearch: mockSetSearch, filters: {},
    setFilter: mockSetFilter, resetFilters: mockResetFilters,
  })),
}))
vi.mock('@/features/accommodations/columns', () => ({
  accommodationsColumns: [],
}))

import { useAccommodationsTab } from '@/features/accommodations/hooks'
import AccommodationsPage from './page'

describe('AccommodationsPage', () => {
  it('renders the page heading', () => {
    render(<AccommodationsPage />)
    expect(screen.getByText('Hébergements')).toBeInTheDocument()
  })

  it('renders data table', () => {
    render(<AccommodationsPage />)
    expect(screen.getByTestId('data-table')).toBeInTheDocument()
  })

  it('renders toolbar with search', () => {
    render(<AccommodationsPage />)
    expect(screen.getByTestId('search-input')).toBeInTheDocument()
  })

  it('renders toolbar with reset button', () => {
    render(<AccommodationsPage />)
    expect(screen.getByTestId('reset-btn')).toBeInTheDocument()
  })

  it('renders description', () => {
    render(<AccommodationsPage />)
    expect(screen.getByText('Hébergements liés aux voyages.')).toBeInTheDocument()
  })

  it('passes loading state to data table', () => {
    vi.mocked(useAccommodationsTab).mockReturnValueOnce({
      rows: [], isLoading: true, page: 1, limit: 10, total: 0, total_pages: 0,
      setPage: mockSetPage, search: '', setSearch: mockSetSearch, filters: {},
      setFilter: mockSetFilter, resetFilters: mockResetFilters,
    })
    render(<AccommodationsPage />)
    expect(screen.getByTestId('data-table')).toHaveAttribute('data-loading', 'true')
  })

  it('passes pagination to data table', () => {
    vi.mocked(useAccommodationsTab).mockReturnValueOnce({
      rows: [], isLoading: false, page: 3, limit: 10, total: 50, total_pages: 5,
      setPage: mockSetPage, search: '', setSearch: mockSetSearch, filters: {},
      setFilter: mockSetFilter, resetFilters: mockResetFilters,
    })
    render(<AccommodationsPage />)
    expect(screen.getByTestId('data-table')).toHaveAttribute('data-page', '3')
    expect(screen.getByTestId('data-table')).toHaveAttribute('data-total', '50')
  })
})
