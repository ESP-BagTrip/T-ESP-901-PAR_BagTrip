import { render, screen } from '@testing-library/react'

vi.mock('@/components/DataTable', () => ({
  DataTable: () => <div data-testid="data-table" />,
}))
vi.mock('@/components/DataTableToolbar', () => ({
  DataTableToolbar: () => <div data-testid="data-table-toolbar" />,
}))
vi.mock('@/components/layout/PageHeader', () => ({
  PageHeader: ({ title, description }: { title: string; description: string }) => (
    <div>
      <h1>{title}</h1>
      <p>{description}</p>
    </div>
  ),
}))
vi.mock('@/components/ui/badge', () => ({
  Badge: ({ children }: { children: React.ReactNode }) => <span>{children}</span>,
}))
vi.mock('@/components/ui/button', () => ({
  Button: ({ children, ...props }: React.ComponentProps<'button'>) => (
    <button {...props}>{children}</button>
  ),
}))
vi.mock('@/components/ui/dialog', () => ({
  Dialog: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  DialogContent: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  DialogHeader: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  DialogTitle: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
}))
vi.mock('@/services', () => ({
  adminService: { getAuditLogs: vi.fn() },
}))
vi.mock('@/shared/hooks/usePaginatedQuery', () => ({
  usePaginatedQuery: vi.fn(() => ({
    rows: [],
    isLoading: false,
    page: 1,
    limit: 20,
    total: 0,
    total_pages: 0,
    setPage: vi.fn(),
    search: '',
    setSearch: vi.fn(),
    filters: {},
    setFilter: vi.fn(),
    resetFilters: vi.fn(),
  })),
}))
vi.mock('@/utils/date', () => ({
  safeFormatDate: vi.fn(() => ''),
}))

import AuditLogPage from './page'

describe('AuditLogPage', () => {
  it('renders the audit log heading', () => {
    render(<AuditLogPage />)
    expect(screen.getByText("Journal d'audit")).toBeInTheDocument()
  })

  it('renders description', () => {
    render(<AuditLogPage />)
    expect(screen.getByText('Historique de toutes les actions admin.')).toBeInTheDocument()
  })

  it('renders data table', () => {
    render(<AuditLogPage />)
    expect(screen.getByTestId('data-table')).toBeInTheDocument()
  })
})
