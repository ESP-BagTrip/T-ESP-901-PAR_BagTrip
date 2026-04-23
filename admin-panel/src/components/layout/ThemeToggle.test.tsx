import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

vi.mock('next-themes', () => ({
  useTheme: () => ({ theme: 'light', setTheme: vi.fn() }),
}))

import { ThemeToggle } from './ThemeToggle'

describe('ThemeToggle', () => {
  it('renders the toggle button', () => {
    render(<ThemeToggle />)
    expect(screen.getByRole('button', { name: /changer le thème/i })).toBeInTheDocument()
  })

  it('shows options when clicked (light, dark, system)', async () => {
    const user = userEvent.setup()
    render(<ThemeToggle />)

    await user.click(screen.getByRole('button', { name: /changer le thème/i }))

    expect(await screen.findByText('Clair')).toBeInTheDocument()
    expect(screen.getByText('Sombre')).toBeInTheDocument()
    expect(screen.getByText('Système')).toBeInTheDocument()
  })
})
