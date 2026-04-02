import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'

let capturedOnPaginationChange: ((page: number, limit: number) => void) | undefined

vi.mock('../../hooks', () => ({
  useAccommodationsTab: vi.fn(() => ({
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

import AccommodationsTab from '../AccommodationsTab'

describe('AccommodationsTab', () => {
  it('renders DataTable', () => {
    render(<AccommodationsTab isActive={true} />)
    expect(screen.getByTestId('data-table')).toBeInTheDocument()
  })

  it('passes isLoading to DataTable', async () => {
    const { useAccommodationsTab } = await import('../../hooks')
    vi.mocked(useAccommodationsTab).mockReturnValue({ data: null, isLoading: true, setPage: vi.fn() } as any)
    render(<AccommodationsTab isActive={true} />)
    expect(screen.getByTestId('data-table')).toHaveAttribute('data-loading', 'true')
  })

  it('calls setPage on pagination change', async () => {
    const mockSetPage = vi.fn()
    const { useAccommodationsTab } = await import('../../hooks')
    vi.mocked(useAccommodationsTab).mockReturnValue({
      data: { items: [], page: 1, limit: 10, total: 0, total_pages: 0 },
      isLoading: false,
      setPage: mockSetPage,
    } as any)
    render(<AccommodationsTab isActive={true} />)
    capturedOnPaginationChange?.(2, 10)
    expect(mockSetPage).toHaveBeenCalledWith(2)
  })
})
