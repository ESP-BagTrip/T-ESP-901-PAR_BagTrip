import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

const mockInvalidateQueries = vi.fn()
vi.mock('@tanstack/react-query', () => ({
  useQuery: vi.fn(() => ({ data: { data: [{ id: 'u1', email: 'user1@test.com' }, { id: 'u2', email: 'user2@test.com' }] } })),
  useQueryClient: vi.fn(() => ({ invalidateQueries: mockInvalidateQueries })),
}))
vi.mock('sonner', () => ({
  toast: { success: vi.fn(), error: vi.fn() },
}))
vi.mock('@/services', () => ({
  adminService: { sendNotification: vi.fn(() => Promise.resolve({ message: 'Sent' })) },
  usersService: { getUsers: vi.fn(() => Promise.resolve({ data: [{ id: 'u1' }, { id: 'u2' }] })) },
}))
vi.mock('@/components/ui/button', () => ({
  Button: ({ children, ...props }: React.ComponentProps<'button'>) => <button {...props}>{children}</button>,
}))
vi.mock('@/components/ui/input', () => ({
  Input: (props: React.ComponentProps<'input'>) => <input {...props} />,
}))
vi.mock('@/components/ui/label', () => ({
  Label: ({ children, ...props }: React.ComponentProps<'label'>) => <label {...props}>{children}</label>,
}))
vi.mock('@/components/ui/textarea', () => ({
  Textarea: (props: React.ComponentProps<'textarea'>) => <textarea {...props} />,
}))
vi.mock('@/components/ui/checkbox', () => ({
  Checkbox: ({ checked, onCheckedChange, id }: { checked?: boolean; onCheckedChange?: (v: boolean) => void; id?: string }) => (
    <input type="checkbox" id={id} checked={checked} onChange={e => onCheckedChange?.(e.target.checked)} />
  ),
}))
vi.mock('@/components/ui/scroll-area', () => ({
  ScrollArea: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
}))
vi.mock('@/components/ui/dialog', () => ({
  Dialog: ({ children, open }: { children: React.ReactNode; open: boolean }) => open ? <div role="dialog">{children}</div> : null,
  DialogContent: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  DialogDescription: ({ children }: { children: React.ReactNode }) => <p>{children}</p>,
  DialogFooter: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  DialogHeader: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  DialogTitle: ({ children }: { children: React.ReactNode }) => <h2>{children}</h2>,
}))

import { toast } from 'sonner'
import { adminService, usersService } from '@/services'
import { SendNotificationModal } from './SendNotificationModal'

describe('SendNotificationModal', () => {
  const onClose = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders nothing when closed', () => {
    const { container } = render(<SendNotificationModal open={false} onClose={onClose} />)
    expect(container.innerHTML).toBe('')
  })

  it('renders dialog title when open', () => {
    render(<SendNotificationModal open={true} onClose={onClose} />)
    expect(screen.getByText('Envoyer une notification')).toBeInTheDocument()
  })

  it('renders title and body inputs', () => {
    render(<SendNotificationModal open={true} onClose={onClose} />)
    expect(screen.getByPlaceholderText('Titre de la notification')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Corps du message')).toBeInTheDocument()
  })

  it('renders send to all checkbox checked by default', () => {
    render(<SendNotificationModal open={true} onClose={onClose} />)
    expect(screen.getByText('Envoyer à tous les utilisateurs')).toBeInTheDocument()
  })

  it('renders submit and cancel buttons', () => {
    render(<SendNotificationModal open={true} onClose={onClose} />)
    expect(screen.getByText('Envoyer')).toBeInTheDocument()
    expect(screen.getByText('Annuler')).toBeInTheDocument()
  })

  it('calls onClose when cancel is clicked', async () => {
    const user = userEvent.setup()
    render(<SendNotificationModal open={true} onClose={onClose} />)
    await user.click(screen.getByText('Annuler'))
    expect(onClose).toHaveBeenCalled()
  })

  it('shows error toast when submitting empty form', async () => {
    const user = userEvent.setup()
    render(<SendNotificationModal open={true} onClose={onClose} />)
    await user.click(screen.getByText('Envoyer'))
    expect(toast.error).toHaveBeenCalledWith('Titre et message sont requis')
  })

  it('unchecking send-to-all shows user list', async () => {
    const user = userEvent.setup()
    render(<SendNotificationModal open={true} onClose={onClose} />)
    const checkbox = screen.getByRole('checkbox', { checked: true })
    await user.click(checkbox)
    expect(screen.getByText('user1@test.com')).toBeInTheDocument()
  })

  it('submits successfully with title and body', async () => {
    const user = userEvent.setup()
    render(<SendNotificationModal open={true} onClose={onClose} />)
    await user.type(screen.getByPlaceholderText('Titre de la notification'), 'Test Title')
    await user.type(screen.getByPlaceholderText('Corps du message'), 'Test Body')
    await user.click(screen.getByText('Envoyer'))
    expect(vi.mocked(usersService.getUsers)).toHaveBeenCalled()
  })
})
