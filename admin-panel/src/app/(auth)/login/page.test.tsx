import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

const mockLogin = vi.fn()
const mockUseAuth = vi.fn(() => ({
  login: mockLogin,
  isLoggingIn: false,
  loginError: null,
}))

vi.mock('@/hooks', () => {
  class NotAdminError extends Error {
    constructor(msg = 'Not admin') { super(msg); this.name = 'NotAdminError' }
  }
  return {
    NotAdminError,
    useAuth: (...args: unknown[]) => mockUseAuth(...args),
  }
})
vi.mock('@/lib/validations/auth', () => ({
  loginSchema: {
    parse: vi.fn(),
    safeParse: vi.fn(() => ({ success: true, data: {} })),
  },
}))
vi.mock('@hookform/resolvers/zod', () => ({
  zodResolver: vi.fn(() => vi.fn()),
}))

import { NotAdminError } from '@/hooks'
import LoginPage from './page'

describe('LoginPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockUseAuth.mockReturnValue({
      login: mockLogin,
      isLoggingIn: false,
      loginError: null,
    })
  })

  it('renders without crashing', () => {
    render(<LoginPage />)
    expect(screen.getByText('BagTrip')).toBeInTheDocument()
  })

  it('renders email and password inputs', () => {
    render(<LoginPage />)
    expect(screen.getByLabelText('Email')).toBeInTheDocument()
    expect(screen.getByLabelText('Mot de passe')).toBeInTheDocument()
  })

  it('renders submit button', () => {
    render(<LoginPage />)
    expect(screen.getByRole('button', { name: 'Se connecter' })).toBeInTheDocument()
  })

  it('renders admin subtitle', () => {
    render(<LoginPage />)
    expect(screen.getByText('Admin')).toBeInTheDocument()
  })

  it('renders description text', () => {
    render(<LoginPage />)
    expect(screen.getByText('Connectez-vous avec votre compte administrateur.')).toBeInTheDocument()
  })

  it('toggles password visibility', async () => {
    const user = userEvent.setup()
    render(<LoginPage />)
    const passwordInput = screen.getByLabelText('Mot de passe')
    expect(passwordInput).toHaveAttribute('type', 'password')

    const toggleBtn = screen.getByLabelText('Afficher le mot de passe')
    await user.click(toggleBtn)
    expect(passwordInput).toHaveAttribute('type', 'text')

    const hideBtn = screen.getByLabelText('Masquer le mot de passe')
    await user.click(hideBtn)
    expect(passwordInput).toHaveAttribute('type', 'password')
  })

  it('shows loading state when isLoggingIn is true', () => {
    mockUseAuth.mockReturnValue({
      login: mockLogin,
      isLoggingIn: true,
      loginError: null,
    })
    render(<LoginPage />)
    expect(screen.getByText('Connexion…')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /Connexion/ })).toBeDisabled()
  })

  it('displays NotAdminError message', () => {
    mockUseAuth.mockReturnValue({
      login: mockLogin,
      isLoggingIn: false,
      loginError: new NotAdminError('Accès réservé aux administrateurs'),
    })
    render(<LoginPage />)
    expect(screen.getByText('Accès réservé aux administrateurs')).toBeInTheDocument()
  })

  it('displays generic Error message', () => {
    mockUseAuth.mockReturnValue({
      login: mockLogin,
      isLoggingIn: false,
      loginError: new Error('Invalid credentials'),
    })
    render(<LoginPage />)
    expect(screen.getByText('Invalid credentials')).toBeInTheDocument()
  })

  it('displays fallback error message for unknown error', () => {
    mockUseAuth.mockReturnValue({
      login: mockLogin,
      isLoggingIn: false,
      loginError: 'some string error',
    })
    render(<LoginPage />)
    expect(screen.getByText('Une erreur est survenue')).toBeInTheDocument()
  })

  it('has correct input placeholders', () => {
    render(<LoginPage />)
    expect(screen.getByPlaceholderText('you@bagtrip.app')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('••••••••')).toBeInTheDocument()
  })
})
