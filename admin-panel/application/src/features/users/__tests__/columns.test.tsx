import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { usersColumns } from '../columns'

vi.mock('@/services', () => ({
  adminService: {
    updateUserPlan: vi.fn().mockResolvedValue({}),
  },
}))

function renderCell(columns: any[], accessorKey: string, value: any, original: any = {}) {
  const col = columns.find((c: any) => c.accessorKey === accessorKey)
  if (!col?.cell) return null
  const mockRow = {
    getValue: (key: string) => {
      if (key === accessorKey) return value
      if (key === 'id') return original.id ?? 'mock-user-id'
      return undefined
    },
    original,
  }
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })
  const { container } = render(
    <QueryClientProvider client={queryClient}>
      <>{(col.cell as Function)({ row: mockRow })}</>
    </QueryClientProvider>
  )
  return container
}

describe('usersColumns', () => {
  it('should have 5 columns', () => {
    expect(usersColumns).toHaveLength(5)
  })

  it('renders id cell with truncated value', () => {
    renderCell(usersColumns, 'id', 'abcdefgh-1234-5678-9012')
    expect(screen.getByText('abcdefgh...')).toBeInTheDocument()
  })

  it('renders email cell', () => {
    renderCell(usersColumns, 'email', 'admin@test.com')
    expect(screen.getByText('admin@test.com')).toBeInTheDocument()
  })

  it('renders plan cell with FREE plan and shows select', () => {
    renderCell(usersColumns, 'plan', 'FREE', { id: 'user-123' })
    const select = screen.getByRole('combobox')
    expect(select).toBeInTheDocument()
    expect(select).toHaveValue('FREE')
  })

  it('renders plan cell with PREMIUM plan', () => {
    renderCell(usersColumns, 'plan', 'PREMIUM', { id: 'user-123' })
    const select = screen.getByRole('combobox')
    expect(select).toHaveValue('PREMIUM')
  })

  it('renders plan cell with ADMIN plan', () => {
    renderCell(usersColumns, 'plan', 'ADMIN', { id: 'user-123' })
    const select = screen.getByRole('combobox')
    expect(select).toHaveValue('ADMIN')
  })

  it('renders plan cell with null defaults to FREE', () => {
    renderCell(usersColumns, 'plan', null, { id: 'user-123' })
    const select = screen.getByRole('combobox')
    expect(select).toHaveValue('FREE')
  })

  it('renders plan cell with all options available', () => {
    renderCell(usersColumns, 'plan', 'FREE', { id: 'user-123' })
    const options = screen.getAllByRole('option')
    expect(options).toHaveLength(3)
    expect(options[0]).toHaveValue('FREE')
    expect(options[1]).toHaveValue('PREMIUM')
    expect(options[2]).toHaveValue('ADMIN')
  })

  it('renders created_at cell', () => {
    renderCell(usersColumns, 'created_at', '2024-01-15T10:30:00Z')
    expect(document.querySelector('span')).toBeInTheDocument()
  })

  it('renders updated_at cell', () => {
    renderCell(usersColumns, 'updated_at', '2024-02-20T14:00:00Z')
    expect(document.querySelector('span')).toBeInTheDocument()
  })

  it('handleChange calls updateUserPlan on plan change', async () => {
    const { adminService } = await import('@/services')
    vi.mocked(adminService.updateUserPlan).mockResolvedValue(undefined)
    renderCell(usersColumns, 'plan', 'FREE', { id: 'user-123' })
    const select = screen.getByRole('combobox')
    const { fireEvent, waitFor } = await import('@testing-library/react')
    fireEvent.change(select, { target: { value: 'PREMIUM' } })
    await waitFor(() => {
      expect(adminService.updateUserPlan).toHaveBeenCalledWith('user-123', 'PREMIUM')
    })
  })

  it('handleChange does nothing when same plan selected', async () => {
    const { adminService } = await import('@/services')
    vi.mocked(adminService.updateUserPlan).mockClear()
    renderCell(usersColumns, 'plan', 'FREE', { id: 'user-123' })
    const select = screen.getByRole('combobox')
    const { fireEvent } = await import('@testing-library/react')
    fireEvent.change(select, { target: { value: 'FREE' } })
    expect(adminService.updateUserPlan).not.toHaveBeenCalled()
  })

  it('handleChange shows error toast on failure', async () => {
    const { adminService } = await import('@/services')
    vi.mocked(adminService.updateUserPlan).mockRejectedValue(new Error('fail'))
    renderCell(usersColumns, 'plan', 'FREE', { id: 'user-123' })
    const select = screen.getByRole('combobox')
    const { fireEvent, waitFor } = await import('@testing-library/react')
    fireEvent.change(select, { target: { value: 'ADMIN' } })
    await waitFor(() => {
      expect(adminService.updateUserPlan).toHaveBeenCalled()
    })
  })
})
