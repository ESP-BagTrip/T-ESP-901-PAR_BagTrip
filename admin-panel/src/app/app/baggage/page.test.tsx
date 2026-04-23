import { render, screen } from '@testing-library/react'

vi.mock('@/components/DataTable', () => ({
  DataTable: ({
    data,
    isLoading,
    pagination,
  }: {
    data: unknown[]
    isLoading: boolean
    pagination: { page: number; total: number }
  }) => (
    <div
      data-testid="data-table"
      data-loading={isLoading}
      data-page={pagination.page}
      data-total={pagination.total}
    >
      {data.length} rows
    </div>
  ),
}))
vi.mock('@/components/DataTableToolbar', () => ({
  DataTableToolbar: ({
    searchValue,
    onSearch,
    searchPlaceholder,
    onReset,
  }: {
    searchValue?: string
    onSearch?: (v: string) => void
    searchPlaceholder?: string
    onReset?: () => void
  }) => (
    <div data-testid="data-table-toolbar">
      <input
        data-testid="search-input"
        value={searchValue ?? ''}
        onChange={e => onSearch?.(e.target.value)}
        placeholder={searchPlaceholder}
      />
      {onReset && (
        <button data-testid="reset-btn" onClick={onReset}>
          Reset
        </button>
      )}
    </div>
  ),
}))
vi.mock('@/components/layout/PageHeader', () => ({
  PageHeader: ({ title, description }: { title: string; description: string }) => (
    <div>
      <h1>{title}</h1>
      <p>{description}</p>
    </div>
  ),
}))

const mockSetPage = vi.fn()
vi.mock('@/features/baggage-items/hooks', () => ({
  useBaggageItemsTab: vi.fn(() => ({
    rows: [],
    isLoading: false,
    page: 1,
    limit: 10,
    total: 0,
    total_pages: 0,
    setPage: mockSetPage,
    search: '',
    setSearch: vi.fn(),
    filters: {},
    setFilter: vi.fn(),
    resetFilters: vi.fn(),
  })),
}))
vi.mock('@/features/baggage-items/columns', () => ({ baggageItemsColumns: [] }))

import { useBaggageItemsTab } from '@/features/baggage-items/hooks'
import BaggagePage from './page'

describe('BaggagePage', () => {
  it('renders the page heading', () => {
    render(<BaggagePage />)
    expect(screen.getByText('Bagages')).toBeInTheDocument()
  })

  it('renders data table', () => {
    render(<BaggagePage />)
    expect(screen.getByTestId('data-table')).toBeInTheDocument()
  })

  it('renders toolbar with search', () => {
    render(<BaggagePage />)
    expect(screen.getByTestId('search-input')).toBeInTheDocument()
  })

  it('renders description', () => {
    render(<BaggagePage />)
    expect(screen.getByText('Items de bagage par voyage.')).toBeInTheDocument()
  })

  it('passes loading state', () => {
    vi.mocked(useBaggageItemsTab).mockReturnValueOnce({
      rows: [],
      isLoading: true,
      page: 1,
      limit: 10,
      total: 0,
      total_pages: 0,
      setPage: mockSetPage,
      search: '',
      setSearch: vi.fn(),
      filters: {},
      setFilter: vi.fn(),
      resetFilters: vi.fn(),
    })
    render(<BaggagePage />)
    expect(screen.getByTestId('data-table')).toHaveAttribute('data-loading', 'true')
  })
})
