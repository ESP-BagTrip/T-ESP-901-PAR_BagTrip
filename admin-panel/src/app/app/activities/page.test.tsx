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
    filters,
    onReset,
  }: {
    searchValue?: string
    onSearch?: (v: string) => void
    searchPlaceholder?: string
    filters?: { key: string; label: string; options: { value: string; label: string }[] }[]
    onReset?: () => void
  }) => (
    <div data-testid="data-table-toolbar">
      <input
        data-testid="search-input"
        value={searchValue ?? ''}
        onChange={e => onSearch?.(e.target.value)}
        placeholder={searchPlaceholder}
      />
      {filters?.map(f => (
        <select key={f.key} data-testid={`filter-${f.key}`}>
          <option>{f.label}</option>
          {f.options.map(o => (
            <option key={o.value} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
      ))}
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
const mockSetSearch = vi.fn()
const mockSetFilter = vi.fn()
const mockResetFilters = vi.fn()

vi.mock('@/features/activities/hooks', () => ({
  useActivitiesTab: vi.fn(() => ({
    rows: [],
    isLoading: false,
    page: 1,
    limit: 10,
    total: 0,
    total_pages: 0,
    setPage: mockSetPage,
    search: '',
    setSearch: mockSetSearch,
    filters: {},
    setFilter: mockSetFilter,
    resetFilters: mockResetFilters,
  })),
}))
vi.mock('@/features/activities/columns', () => ({
  activitiesColumns: [],
}))

import { useActivitiesTab } from '@/features/activities/hooks'
import ActivitiesPage from './page'

describe('ActivitiesPage', () => {
  it('renders the page heading', () => {
    render(<ActivitiesPage />)
    expect(screen.getByText('Activités')).toBeInTheDocument()
  })

  it('renders data table', () => {
    render(<ActivitiesPage />)
    expect(screen.getByTestId('data-table')).toBeInTheDocument()
  })

  it('renders toolbar with search', () => {
    render(<ActivitiesPage />)
    expect(screen.getByTestId('search-input')).toBeInTheDocument()
  })

  it('renders description', () => {
    render(<ActivitiesPage />)
    expect(screen.getByText('Activités planifiées par les voyageurs.')).toBeInTheDocument()
  })

  it('passes loading state to data table', () => {
    vi.mocked(useActivitiesTab).mockReturnValueOnce({
      rows: [],
      isLoading: true,
      page: 1,
      limit: 10,
      total: 0,
      total_pages: 0,
      setPage: mockSetPage,
      search: '',
      setSearch: mockSetSearch,
      filters: {},
      setFilter: mockSetFilter,
      resetFilters: mockResetFilters,
    })
    render(<ActivitiesPage />)
    expect(screen.getByTestId('data-table')).toHaveAttribute('data-loading', 'true')
  })

  it('passes pagination to data table', () => {
    vi.mocked(useActivitiesTab).mockReturnValueOnce({
      rows: [],
      isLoading: false,
      page: 2,
      limit: 10,
      total: 30,
      total_pages: 3,
      setPage: mockSetPage,
      search: '',
      setSearch: mockSetSearch,
      filters: {},
      setFilter: mockSetFilter,
      resetFilters: mockResetFilters,
    })
    render(<ActivitiesPage />)
    expect(screen.getByTestId('data-table')).toHaveAttribute('data-page', '2')
  })
})
