import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { DataTableToolbar, type FilterConfig } from './DataTableToolbar'

describe('DataTableToolbar', () => {
  it('renders search input with placeholder', () => {
    render(
      <DataTableToolbar searchValue="" onSearch={vi.fn()} searchPlaceholder="Search users..." />
    )

    expect(screen.getByPlaceholderText('Search users...')).toBeInTheDocument()
  })

  it('renders default search placeholder', () => {
    render(<DataTableToolbar searchValue="" onSearch={vi.fn()} />)

    expect(screen.getByPlaceholderText('Rechercher…')).toBeInTheDocument()
  })

  it('calls onSearch when typing', () => {
    const onSearch = vi.fn()
    render(<DataTableToolbar searchValue="" onSearch={onSearch} />)

    fireEvent.change(screen.getByPlaceholderText('Rechercher…'), {
      target: { value: 'test' },
    })

    expect(onSearch).toHaveBeenCalledWith('test')
  })

  it('does not render search input when onSearch is not provided', () => {
    render(<DataTableToolbar />)

    expect(screen.queryByPlaceholderText('Rechercher…')).not.toBeInTheDocument()
  })

  it('renders filter selects', () => {
    const filters: FilterConfig[] = [
      {
        key: 'status',
        label: 'Status',
        options: [
          { value: 'active', label: 'Active' },
          { value: 'inactive', label: 'Inactive' },
        ],
      },
    ]

    render(<DataTableToolbar filters={filters} activeFilters={{}} onFilterChange={vi.fn()} />)

    // Select trigger should show the placeholder
    expect(screen.getByText('Tous')).toBeInTheDocument()
  })

  it('shows bulk actions when selectedCount > 0', () => {
    render(<DataTableToolbar selectedCount={3} bulkActions={<button>Delete selected</button>} />)

    expect(screen.getByText('3 éléments sélectionnés')).toBeInTheDocument()
    expect(screen.getByText('Delete selected')).toBeInTheDocument()
  })

  it('shows singular text for selectedCount === 1', () => {
    render(<DataTableToolbar selectedCount={1} bulkActions={<button>Delete</button>} />)

    expect(screen.getByText('1 élément sélectionné')).toBeInTheDocument()
  })

  it('shows reset button when search has value', () => {
    const onReset = vi.fn()
    render(<DataTableToolbar searchValue="something" onSearch={vi.fn()} onReset={onReset} />)

    const resetButton = screen.getByText('Réinitialiser')
    expect(resetButton).toBeInTheDocument()

    fireEvent.click(resetButton)
    expect(onReset).toHaveBeenCalledOnce()
  })

  it('does not show reset button when no active filters', () => {
    render(<DataTableToolbar searchValue="" onSearch={vi.fn()} onReset={vi.fn()} />)

    expect(screen.queryByText('Réinitialiser')).not.toBeInTheDocument()
  })

  it('renders actions slot', () => {
    render(<DataTableToolbar actions={<button>Create</button>} />)

    expect(screen.getByText('Create')).toBeInTheDocument()
  })
})
