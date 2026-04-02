import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { SendNotificationModal } from '../SendNotificationModal'

const mockSendNotification = vi.fn().mockResolvedValue({ message: 'Sent', count: 1 })
const mockGetUsers = vi.fn().mockResolvedValue({
  data: [{ id: '1', email: 'test@test.com' }],
  pagination: {},
})

vi.mock('@/services', () => ({
  adminService: {
    sendNotification: (...args: unknown[]) => mockSendNotification(...args),
  },
  usersService: {
    getUsers: (...args: unknown[]) => mockGetUsers(...args),
  },
}))

vi.mock('sonner', () => ({
  toast: { error: vi.fn(), success: vi.fn() },
}))

import { toast } from 'sonner'

function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })
  return function Wrapper({ children }: { children: React.ReactNode }) {
    return (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    )
  }
}

describe('SendNotificationModal', () => {
  const mockOnClose = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('returns null when open is false', () => {
    const { container } = render(
      <SendNotificationModal open={false} onClose={mockOnClose} />,
      { wrapper: createWrapper() }
    )
    expect(container.innerHTML).toBe('')
  })

  it('renders modal when open is true', () => {
    render(
      <SendNotificationModal open={true} onClose={mockOnClose} />,
      { wrapper: createWrapper() }
    )
    expect(screen.getByText('Envoyer une notification')).toBeInTheDocument()
  })

  it('shows title input, body textarea, and sendToAll checkbox', () => {
    render(
      <SendNotificationModal open={true} onClose={mockOnClose} />,
      { wrapper: createWrapper() }
    )
    expect(screen.getByPlaceholderText('Titre de la notification')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Corps du message')).toBeInTheDocument()
    expect(screen.getByLabelText('Envoyer à tous les utilisateurs')).toBeInTheDocument()
  })

  it('cancel button calls onClose', () => {
    render(
      <SendNotificationModal open={true} onClose={mockOnClose} />,
      { wrapper: createWrapper() }
    )
    fireEvent.click(screen.getByText('Annuler'))
    expect(mockOnClose).toHaveBeenCalled()
  })

  it('submit with empty fields shows error toast', async () => {
    render(
      <SendNotificationModal open={true} onClose={mockOnClose} />,
      { wrapper: createWrapper() }
    )
    fireEvent.click(screen.getByText('Envoyer'))
    await waitFor(() => {
      expect(toast.error).toHaveBeenCalledWith('Titre et message sont requis')
    })
  })

  it('submit with valid data calls sendNotification and onClose', async () => {
    render(
      <SendNotificationModal open={true} onClose={mockOnClose} />,
      { wrapper: createWrapper() }
    )

    fireEvent.change(screen.getByPlaceholderText('Titre de la notification'), {
      target: { value: 'Test Title' },
    })
    fireEvent.change(screen.getByPlaceholderText('Corps du message'), {
      target: { value: 'Test Body' },
    })

    fireEvent.click(screen.getByText('Envoyer'))

    await waitFor(() => {
      expect(mockSendNotification).toHaveBeenCalledWith({
        user_ids: ['1'],
        title: 'Test Title',
        body: 'Test Body',
        type: 'ADMIN',
      })
    })

    await waitFor(() => {
      expect(mockOnClose).toHaveBeenCalled()
    })
  })

  it('unchecking sendToAll shows user list', async () => {
    render(
      <SendNotificationModal open={true} onClose={mockOnClose} />,
      { wrapper: createWrapper() }
    )

    const checkbox = screen.getByLabelText('Envoyer à tous les utilisateurs')
    fireEvent.click(checkbox)

    await waitFor(() => {
      expect(screen.getByText(/sélectionné/)).toBeInTheDocument()
    })
  })
})
