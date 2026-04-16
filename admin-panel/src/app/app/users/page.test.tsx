import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: vi.fn(), replace: vi.fn(), back: vi.fn() }),
}))
vi.mock('@/components/DataTable', () => ({
  DataTable: ({ data, isLoading, pagination, rowSelection, onRowSelectionChange, columns }: {
    data: unknown[]; isLoading: boolean; pagination: { page: number; total: number };
    rowSelection?: Record<string, boolean>; onRowSelectionChange?: (s: Record<string, boolean>) => void;
    columns: unknown[];
  }) => (
    <div data-testid="data-table" data-loading={isLoading} data-page={pagination.page} data-total={pagination.total} data-cols={columns.length}>
      {data.length} rows
    </div>
  ),
}))
vi.mock('@/components/DataTableToolbar', () => ({
  DataTableToolbar: ({ searchValue, onSearch, searchPlaceholder, filters, onReset, selectedCount, bulkActions, actions }: {
    searchValue?: string; onSearch?: (v: string) => void; searchPlaceholder?: string;
    filters?: { key: string; label: string; options: { value: string; label: string }[] }[];
    onReset?: () => void; selectedCount?: number; bulkActions?: React.ReactNode; actions?: React.ReactNode;
  }) => (
    <div data-testid="data-table-toolbar">
      <input data-testid="search-input" value={searchValue ?? ''} onChange={e => onSearch?.(e.target.value)} placeholder={searchPlaceholder} />
      {filters?.map(f => <select key={f.key} data-testid={`filter-${f.key}`}><option>{f.label}</option>{f.options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}</select>)}
      {onReset && <button data-testid="reset-btn" onClick={onReset}>Reset</button>}
      {selectedCount != null && selectedCount > 0 && <span data-testid="selected-count">{selectedCount} selected</span>}
      {bulkActions && <div data-testid="bulk-actions">{bulkActions}</div>}
      {actions && <div data-testid="actions">{actions}</div>}
    </div>
  ),
}))
vi.mock('@/components/ConfirmDialog', () => ({
  ConfirmDialog: ({ open, title }: { open: boolean; title: string }) => open ? <div data-testid="confirm-dialog">{title}</div> : null,
}))
vi.mock('@/components/RowActions', () => ({
  RowActions: () => null,
}))
vi.mock('@/components/layout/PageHeader', () => ({
  PageHeader: ({ title, description }: { title: string; description: string }) => (
    <div><h1>{title}</h1><p>{description}</p></div>
  ),
}))
vi.mock('@/components/ui/button', () => ({
  Button: ({ children, ...props }: React.ComponentProps<'button'> & { asChild?: boolean }) => (
    <button {...props}>{children}</button>
  ),
}))
vi.mock('@/components/ui/checkbox', () => ({
  Checkbox: () => <input type="checkbox" />,
}))
vi.mock('@/components/ui/select', () => ({
  Select: ({ children, onValueChange }: { children: React.ReactNode; onValueChange?: (v: string) => void }) => (
    <div data-testid="bulk-plan-select" onClick={() => onValueChange?.('PREMIUM')}>{children}</div>
  ),
  SelectContent: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  SelectItem: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  SelectTrigger: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  SelectValue: () => <span />,
}))

const mockSetPage = vi.fn()
const mockSetSearch = vi.fn()
const mockSetFilter = vi.fn()
const mockResetFilters = vi.fn()
const mockDeleteMutate = vi.fn()
const mockBulkPlanMutate = vi.fn()
const mockBulkBanMutate = vi.fn()

vi.mock('@/features/users/hooks', () => ({
  useUsersTab: vi.fn(() => ({
    rows: [], isLoading: false, page: 1, limit: 10, total: 0, total_pages: 0,
    setPage: mockSetPage, search: '', setSearch: mockSetSearch, filters: {},
    setFilter: mockSetFilter, resetFilters: mockResetFilters,
  })),
}))
vi.mock('@/features/users/mutations', () => ({
  useDeleteUser: vi.fn(() => ({ mutate: mockDeleteMutate, isPending: false })),
  useBulkChangePlan: vi.fn(() => ({ mutate: mockBulkPlanMutate, isPending: false })),
  useBulkBan: vi.fn(() => ({ mutate: mockBulkBanMutate, isPending: false })),
}))
vi.mock('@/features/users/columns', () => ({
  usersColumns: [],
}))

import { useUsersTab } from '@/features/users/hooks'
import UsersPage from './page'

describe('UsersPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders the page heading', () => {
    render(<UsersPage />)
    expect(screen.getByText('Utilisateurs')).toBeInTheDocument()
  })

  it('renders data table', () => {
    render(<UsersPage />)
    expect(screen.getByTestId('data-table')).toBeInTheDocument()
  })

  it('renders toolbar with search', () => {
    render(<UsersPage />)
    expect(screen.getByTestId('search-input')).toBeInTheDocument()
  })

  it('renders plan filter', () => {
    render(<UsersPage />)
    expect(screen.getByTestId('filter-plan')).toBeInTheDocument()
  })

  it('renders plan filter options', () => {
    render(<UsersPage />)
    expect(screen.getByText('Free')).toBeInTheDocument()
    expect(screen.getByText('Premium')).toBeInTheDocument()
    expect(screen.getByText('Admin')).toBeInTheDocument()
  })

  it('renders description', () => {
    render(<UsersPage />)
    expect(screen.getByText('Liste et gestion des comptes utilisateurs.')).toBeInTheDocument()
  })

  it('renders bulk actions area', () => {
    render(<UsersPage />)
    expect(screen.getByTestId('bulk-actions')).toBeInTheDocument()
  })

  it('renders ban button in bulk actions', () => {
    render(<UsersPage />)
    expect(screen.getByText('Bannir')).toBeInTheDocument()
  })

  it('renders export CSV action', () => {
    render(<UsersPage />)
    expect(screen.getByText('Export CSV')).toBeInTheDocument()
  })

  it('renders search placeholder', () => {
    render(<UsersPage />)
    expect(screen.getByPlaceholderText('Rechercher par email…')).toBeInTheDocument()
  })

  it('passes loading state to data table', () => {
    vi.mocked(useUsersTab).mockReturnValueOnce({
      rows: [], isLoading: true, page: 1, limit: 10, total: 0, total_pages: 0,
      setPage: mockSetPage, search: '', setSearch: mockSetSearch, filters: {},
      setFilter: mockSetFilter, resetFilters: mockResetFilters,
    })
    render(<UsersPage />)
    expect(screen.getByTestId('data-table')).toHaveAttribute('data-loading', 'true')
  })

  it('passes pagination info to data table', () => {
    vi.mocked(useUsersTab).mockReturnValueOnce({
      rows: [], isLoading: false, page: 3, limit: 10, total: 100, total_pages: 10,
      setPage: mockSetPage, search: '', setSearch: mockSetSearch, filters: {},
      setFilter: mockSetFilter, resetFilters: mockResetFilters,
    })
    render(<UsersPage />)
    expect(screen.getByTestId('data-table')).toHaveAttribute('data-page', '3')
    expect(screen.getByTestId('data-table')).toHaveAttribute('data-total', '100')
  })

  it('renders bulk plan select with options', () => {
    render(<UsersPage />)
    expect(screen.getByTestId('bulk-plan-select')).toBeInTheDocument()
  })
})
