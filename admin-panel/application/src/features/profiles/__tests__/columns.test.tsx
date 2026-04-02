import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { profilesColumns } from '../columns'

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

describe('profilesColumns', () => {
  it('should have 8 columns', () => {
    expect(profilesColumns).toHaveLength(8)
  })

  it('renders id cell with truncated value', () => {
    renderCell(profilesColumns, 'id', 'abcdefgh-1234-5678-9012')
    expect(screen.getByText('abcdefgh...')).toBeInTheDocument()
  })

  it('renders user_email cell', () => {
    renderCell(profilesColumns, 'user_email', 'user@test.com')
    expect(screen.getByText('user@test.com')).toBeInTheDocument()
  })

  it('renders travel_types cell with array', () => {
    renderCell(profilesColumns, 'travel_types', ['beach', 'city'])
    expect(screen.getByText('beach, city')).toBeInTheDocument()
  })

  it('renders travel_types cell with null', () => {
    renderCell(profilesColumns, 'travel_types', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders travel_style cell with value', () => {
    renderCell(profilesColumns, 'travel_style', 'Backpacker')
    expect(screen.getByText('Backpacker')).toBeInTheDocument()
  })

  it('renders travel_style cell with null', () => {
    renderCell(profilesColumns, 'travel_style', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders budget cell with value', () => {
    renderCell(profilesColumns, 'budget', 'Medium')
    expect(screen.getByText('Medium')).toBeInTheDocument()
  })

  it('renders budget cell with null', () => {
    renderCell(profilesColumns, 'budget', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders companions cell with value', () => {
    renderCell(profilesColumns, 'companions', 'Family')
    expect(screen.getByText('Family')).toBeInTheDocument()
  })

  it('renders companions cell with null', () => {
    renderCell(profilesColumns, 'companions', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders is_completed cell true', () => {
    renderCell(profilesColumns, 'is_completed', true)
    expect(screen.getByText('Oui')).toBeInTheDocument()
  })

  it('renders is_completed cell false', () => {
    renderCell(profilesColumns, 'is_completed', false)
    expect(screen.getByText('Non')).toBeInTheDocument()
  })

  it('renders created_at cell', () => {
    const container = renderCell(profilesColumns, 'created_at', '2024-01-15T10:30:00Z')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })
})
