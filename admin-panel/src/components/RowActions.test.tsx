import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { RowActions, type RowAction } from './RowActions'

describe('RowActions', () => {
  const actions: RowAction[] = [
    { label: 'Edit', onClick: vi.fn() },
    { label: 'Delete', onClick: vi.fn(), variant: 'destructive' },
  ]

  it('renders nothing when actions array is empty', () => {
    const { container } = render(<RowActions actions={[]} />)
    expect(container.innerHTML).toBe('')
  })

  it('renders the dropdown trigger button', () => {
    render(<RowActions actions={actions} />)
    expect(screen.getByRole('button', { name: /actions/i })).toBeInTheDocument()
  })

  it('shows actions when opened', async () => {
    const user = userEvent.setup()
    render(<RowActions actions={actions} />)

    await user.click(screen.getByRole('button', { name: /actions/i }))

    expect(await screen.findByText('Edit')).toBeInTheDocument()
    expect(screen.getByText('Delete')).toBeInTheDocument()
  })
})
