import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'

let capturedOnPaginationChange: ((page: number, limit: number) => void) | undefined

vi.mock('../../hooks', () => ({
  useNotificationsTab: vi.fn(() => ({
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

let capturedModalProps: any = {}
vi.mock('../SendNotificationModal', () => ({
  SendNotificationModal: (props: any) => {
    capturedModalProps = props
    return props.open ? <div data-testid="modal">Modal</div> : null
  },
}))

import NotificationsTab from '../NotificationsTab'

describe('NotificationsTab', () => {
  it('renders DataTable', () => {
    render(<NotificationsTab isActive={true} />)
    expect(screen.getByTestId('data-table')).toBeInTheDocument()
  })

  it('has "Envoyer une notification" button', () => {
    render(<NotificationsTab isActive={true} />)
    expect(screen.getByText('Envoyer une notification')).toBeInTheDocument()
  })

  it('passes isLoading to DataTable', async () => {
    const { useNotificationsTab } = await import('../../hooks')
    vi.mocked(useNotificationsTab).mockReturnValue({ data: null, isLoading: true, setPage: vi.fn() } as any)
    render(<NotificationsTab isActive={true} />)
    expect(screen.getByTestId('data-table')).toHaveAttribute('data-loading', 'true')
  })

  it('opens modal when button clicked and closes it via onClose', () => {
    render(<NotificationsTab isActive={true} />)
    expect(screen.queryByTestId('modal')).not.toBeInTheDocument()
    const { fireEvent } = require('@testing-library/react')
    fireEvent.click(screen.getByText('Envoyer une notification'))
    expect(screen.getByTestId('modal')).toBeInTheDocument()
    // Close modal via captured onClose prop
    const { act } = require('@testing-library/react')
    act(() => { capturedModalProps.onClose() })
  })

  it('calls setPage on pagination change', async () => {
    const mockSetPage = vi.fn()
    const { useNotificationsTab } = await import('../../hooks')
    vi.mocked(useNotificationsTab).mockReturnValue({
      data: { items: [], page: 1, limit: 10, total: 0, total_pages: 0 },
      isLoading: false,
      setPage: mockSetPage,
    } as any)
    render(<NotificationsTab isActive={true} />)
    capturedOnPaginationChange?.(2, 10)
    expect(mockSetPage).toHaveBeenCalledWith(2)
  })
})
