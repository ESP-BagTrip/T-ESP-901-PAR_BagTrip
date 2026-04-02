import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'

let capturedOnPaginationChange: ((page: number, limit: number) => void) | undefined

vi.mock('../../hooks', () => ({
  useTravelersTab: vi.fn(() => ({
    data: null,
    isLoading: false,
    setPage: vi.fn(),
  })),
}))

vi.mock('@/components/DataTable', () => ({
  DataTable: ({ data, isLoading, onPaginationChange }: any) => {
    capturedOnPaginationChange = onPaginationChange
    return (
      <div data-testid="data-table" data-loading={isLoading}>
        {data.length} rows
      </div>
    )
  },
}))

import TravelersTab from '../TravelersTab'

describe('TravelersTab', () => {
  it('renders DataTable', () => {
    render(<TravelersTab isActive={true} />)
    expect(screen.getByTestId('data-table')).toBeInTheDocument()
  })

  it('passes isLoading to DataTable', async () => {
    const { useTravelersTab } = await import('../../hooks')
    vi.mocked(useTravelersTab).mockReturnValue({ data: null, isLoading: true, setPage: vi.fn() } as any)
    render(<TravelersTab isActive={true} />)
    expect(screen.getByTestId('data-table')).toHaveAttribute('data-loading', 'true')
  })

  it('calls setPage on pagination change', async () => {
    const mockSetPage = vi.fn()
    const { useTravelersTab } = await import('../../hooks')
    vi.mocked(useTravelersTab).mockReturnValue({
      data: { items: [], page: 1, limit: 10, total: 0, total_pages: 0 },
      isLoading: false,
      setPage: mockSetPage,
    } as any)
    render(<TravelersTab isActive={true} />)
    capturedOnPaginationChange?.(2, 10)
    expect(mockSetPage).toHaveBeenCalledWith(2)
  })
})
