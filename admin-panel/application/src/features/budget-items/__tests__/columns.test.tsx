import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { budgetItemsColumns } from '../columns'

function renderCell(columns: any[], accessorKey: string, value: any) {
  const col = columns.find((c: any) => c.accessorKey === accessorKey)
  if (!col?.cell) return null
  const mockRow = {
    getValue: (key: string) => (key === accessorKey ? value : undefined),
    original: {},
  }
  const { container } = render(<>{(col.cell as Function)({ row: mockRow })}</>)
  return container
}

describe('budgetItemsColumns', () => {
  it('should have 9 columns', () => {
    expect(budgetItemsColumns).toHaveLength(9)
  })

  it('renders id cell with truncated value', () => {
    renderCell(budgetItemsColumns, 'id', 'abcdefgh-1234-5678-9012')
    expect(screen.getByText('abcdefgh...')).toBeInTheDocument()
  })

  it('renders trip_title cell with value', () => {
    renderCell(budgetItemsColumns, 'trip_title', 'My Trip')
    expect(screen.getByText('My Trip')).toBeInTheDocument()
  })

  it('renders trip_title cell with fallback', () => {
    renderCell(budgetItemsColumns, 'trip_title', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders user_email cell', () => {
    renderCell(budgetItemsColumns, 'user_email', 'user@test.com')
    expect(screen.getByText('user@test.com')).toBeInTheDocument()
  })

  it('renders label cell', () => {
    renderCell(budgetItemsColumns, 'label', 'Restaurant dinner')
    expect(screen.getByText('Restaurant dinner')).toBeInTheDocument()
  })

  it('renders amount cell', () => {
    const container = renderCell(budgetItemsColumns, 'amount', 99.5)
    expect(container?.textContent).toBe('99.50 €')
  })

  it('renders category cell with FLIGHT', () => {
    renderCell(budgetItemsColumns, 'category', 'FLIGHT')
    expect(screen.getByText('FLIGHT')).toBeInTheDocument()
  })

  it('renders category cell with FOOD', () => {
    renderCell(budgetItemsColumns, 'category', 'FOOD')
    expect(screen.getByText('FOOD')).toBeInTheDocument()
  })

  it('renders category cell with unknown category', () => {
    renderCell(budgetItemsColumns, 'category', 'SHOPPING')
    expect(screen.getByText('SHOPPING')).toBeInTheDocument()
  })

  it('renders is_planned cell true', () => {
    renderCell(budgetItemsColumns, 'is_planned', true)
    expect(screen.getByText('Planifié')).toBeInTheDocument()
  })

  it('renders is_planned cell false', () => {
    renderCell(budgetItemsColumns, 'is_planned', false)
    expect(screen.getByText('Réel')).toBeInTheDocument()
  })

  it('renders date cell', () => {
    const container = renderCell(budgetItemsColumns, 'date', '2024-06-15')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })

  it('renders created_at cell', () => {
    const container = renderCell(budgetItemsColumns, 'created_at', '2024-01-15T10:30:00Z')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })
})
