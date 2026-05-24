import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { ColumnDef } from '@tanstack/react-table'
import { DataTable } from './DataTable'

interface TestRow {
  id: string
  name: string
  email: string
}

const columns: ColumnDef<TestRow>[] = [
  { accessorKey: 'name', header: 'Name' },
  { accessorKey: 'email', header: 'Email' },
]

const data: TestRow[] = [
  { id: '1', name: 'Alice', email: 'alice@test.com' },
  { id: '2', name: 'Bob', email: 'bob@test.com' },
]

describe('DataTable', () => {
  it('renders column headers', () => {
    render(<DataTable data={data} columns={columns} />)
    expect(screen.getByText('Name')).toBeInTheDocument()
    expect(screen.getByText('Email')).toBeInTheDocument()
  })

  it('renders data rows', () => {
    render(<DataTable data={data} columns={columns} />)
    expect(screen.getByText('Alice')).toBeInTheDocument()
    expect(screen.getByText('alice@test.com')).toBeInTheDocument()
    expect(screen.getByText('Bob')).toBeInTheDocument()
  })

  it('shows empty message when data is empty', () => {
    render(<DataTable data={[]} columns={columns} />)
    expect(screen.getByText('Aucune donnée disponible')).toBeInTheDocument()
  })

  it('shows custom empty label', () => {
    render(<DataTable data={[]} columns={columns} emptyLabel="No results found" />)
    expect(screen.getByText('No results found')).toBeInTheDocument()
  })

  it('shows loading skeleton when isLoading is true', () => {
    const { container } = render(<DataTable data={[]} columns={columns} isLoading={true} />)
    // Skeleton renders with animate-pulse class
    const skeletons = container.querySelectorAll('.animate-pulse')
    expect(skeletons.length).toBeGreaterThan(0)
  })

  it('does not render data rows when loading', () => {
    render(<DataTable data={data} columns={columns} isLoading={true} />)
    expect(screen.queryByText('Alice')).not.toBeInTheDocument()
  })

  it('renders pagination controls', () => {
    render(
      <DataTable
        data={data}
        columns={columns}
        pagination={{ page: 1, limit: 10, total: 25, total_pages: 3 }}
      />
    )
    expect(screen.getByLabelText('Page précédente')).toBeInTheDocument()
    expect(screen.getByLabelText('Page suivante')).toBeInTheDocument()
  })

  it('disables previous button on first page', () => {
    render(
      <DataTable
        data={data}
        columns={columns}
        pagination={{ page: 1, limit: 10, total: 25, total_pages: 3 }}
      />
    )
    expect(screen.getByLabelText('Page précédente')).toBeDisabled()
  })

  it('disables next button on last page', () => {
    render(
      <DataTable
        data={data}
        columns={columns}
        pagination={{ page: 3, limit: 10, total: 25, total_pages: 3 }}
      />
    )
    expect(screen.getByLabelText('Page suivante')).toBeDisabled()
  })
})
