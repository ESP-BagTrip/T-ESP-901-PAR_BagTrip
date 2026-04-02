import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { notificationsColumns } from '../columns'

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

describe('notificationsColumns', () => {
  it('should have 9 columns', () => {
    expect(notificationsColumns).toHaveLength(9)
  })

  it('renders id cell with truncated value', () => {
    renderCell(notificationsColumns, 'id', 'abcdefgh-1234-5678-9012')
    expect(screen.getByText('abcdefgh...')).toBeInTheDocument()
  })

  it('renders user_email cell', () => {
    renderCell(notificationsColumns, 'user_email', 'user@test.com')
    expect(screen.getByText('user@test.com')).toBeInTheDocument()
  })

  it('renders trip_title cell with value', () => {
    renderCell(notificationsColumns, 'trip_title', 'My Trip')
    expect(screen.getByText('My Trip')).toBeInTheDocument()
  })

  it('renders trip_title cell with fallback', () => {
    renderCell(notificationsColumns, 'trip_title', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders type cell with DEPARTURE_REMINDER', () => {
    renderCell(notificationsColumns, 'type', 'DEPARTURE_REMINDER')
    expect(screen.getByText('DEPARTURE_REMINDER')).toBeInTheDocument()
  })

  it('renders type cell with BUDGET_ALERT', () => {
    renderCell(notificationsColumns, 'type', 'BUDGET_ALERT')
    expect(screen.getByText('BUDGET_ALERT')).toBeInTheDocument()
  })

  it('renders type cell with unknown type', () => {
    renderCell(notificationsColumns, 'type', 'CUSTOM')
    expect(screen.getByText('CUSTOM')).toBeInTheDocument()
  })

  it('renders title cell', () => {
    renderCell(notificationsColumns, 'title', 'Departure reminder')
    expect(screen.getByText('Departure reminder')).toBeInTheDocument()
  })

  it('renders body cell with short text', () => {
    renderCell(notificationsColumns, 'body', 'Short message')
    expect(screen.getByText('Short message')).toBeInTheDocument()
  })

  it('renders body cell with long text truncated', () => {
    const longText = 'A'.repeat(60)
    renderCell(notificationsColumns, 'body', longText)
    expect(screen.getByText('A'.repeat(50) + '...')).toBeInTheDocument()
  })

  it('renders is_read cell true', () => {
    renderCell(notificationsColumns, 'is_read', true)
    expect(screen.getByText('Lu')).toBeInTheDocument()
  })

  it('renders is_read cell false', () => {
    renderCell(notificationsColumns, 'is_read', false)
    expect(screen.getByText('Non lu')).toBeInTheDocument()
  })

  it('renders sent_at cell with date', () => {
    const container = renderCell(notificationsColumns, 'sent_at', '2024-01-15T10:30:00Z')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })

  it('renders sent_at cell with null', () => {
    renderCell(notificationsColumns, 'sent_at', null)
    expect(screen.getByText('—')).toBeInTheDocument()
  })

  it('renders created_at cell', () => {
    const container = renderCell(notificationsColumns, 'created_at', '2024-01-15T10:30:00Z')
    expect(container?.querySelector('span')).toBeInTheDocument()
  })
})
