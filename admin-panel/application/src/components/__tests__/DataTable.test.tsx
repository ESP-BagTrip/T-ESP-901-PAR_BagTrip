import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { ColumnDef } from '@tanstack/react-table'
import { DataTable } from '../DataTable'

type TestRow = { name: string; email: string }

const columns: ColumnDef<TestRow>[] = [
  { accessorKey: 'name', header: 'Name' },
  { accessorKey: 'email', header: 'Email' },
]

const data: TestRow[] = [{ name: 'Alice', email: 'a@test.com' }]

describe('DataTable', () => {
  it('renders loading skeleton when isLoading is true', () => {
    const { container } = render(
      <DataTable data={[]} columns={columns} isLoading={true} />
    )
    const skeletons = container.querySelectorAll('.animate-pulse')
    expect(skeletons.length).toBeGreaterThan(0)
  })

  it('renders "Aucune donnée disponible" when data is empty', () => {
    render(<DataTable data={[]} columns={columns} />)
    expect(screen.getByText('Aucune donnée disponible')).toBeInTheDocument()
  })

  it('renders data rows correctly', () => {
    render(<DataTable data={data} columns={columns} />)
    expect(screen.getByText('Alice')).toBeInTheDocument()
    expect(screen.getByText('a@test.com')).toBeInTheDocument()
  })

  it('calls onPaginationChange when pagination buttons are clicked', () => {
    const onPaginationChange = vi.fn()
    render(
      <DataTable
        data={data}
        columns={columns}
        pagination={{ page: 1, limit: 10, total: 30, total_pages: 3 }}
        onPaginationChange={onPaginationChange}
      />
    )
    const nextButtons = screen.getAllByRole('button').filter(
      (btn) => !btn.hasAttribute('disabled')
    )
    // Click the last next/chevron button
    const forwardBtn = nextButtons[nextButtons.length - 1]
    fireEvent.click(forwardBtn)
    expect(onPaginationChange).toHaveBeenCalledWith(2, 10)
  })

  it('shows pagination info text', () => {
    render(
      <DataTable
        data={data}
        columns={columns}
        pagination={{ page: 1, limit: 10, total: 30, total_pages: 3 }}
      />
    )
    expect(screen.getByText(/résultats/)).toBeInTheDocument()
    expect(screen.getByText('Page 1 sur 3')).toBeInTheDocument()
  })
})
