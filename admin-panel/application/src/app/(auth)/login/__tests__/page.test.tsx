import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { useAuth } from '@/hooks'

const mockLogin = vi.fn()
const mockRegister = vi.fn()

class NotAdminError extends Error {
  constructor() {
    super("Vous n'avez pas les droits d'accès à l'interface d'administration.")
    this.name = 'NotAdminError'
  }
}

vi.mock('@/hooks', () => ({
  NotAdminError: class extends Error {
    constructor() {
      super("Vous n'avez pas les droits d'accès à l'interface d'administration.")
      this.name = 'NotAdminError'
    }
  },
  useAuth: vi.fn(() => ({
    login: mockLogin,
    register: mockRegister,
    isLoggingIn: false,
    isRegistering: false,
    loginError: null,
    registerError: null,
  })),
}))

import LoginPage from '../page'

describe('LoginPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(useAuth).mockReturnValue({
      login: mockLogin,
      register: mockRegister,
      isLoggingIn: false,
      isRegistering: false,
      loginError: null,
      registerError: null,
    } as ReturnType<typeof useAuth>)
  })

  it('renders login form with email and password fields', () => {
    render(<LoginPage />)
    expect(screen.getByPlaceholderText('Adresse email')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Mot de passe')).toBeInTheDocument()
  })

  it('renders BagTrip Admin heading', () => {
    render(<LoginPage />)
    expect(screen.getByText('BagTrip Admin')).toBeInTheDocument()
  })

  it('shows Se connecter button', () => {
    render(<LoginPage />)
    expect(screen.getByText('Se connecter')).toBeInTheDocument()
  })

  it('toggle to register mode shows fullName and phone fields and S\'inscrire button', () => {
    render(<LoginPage />)
    fireEvent.click(screen.getByText("Pas encore de compte ? S'inscrire"))
    expect(screen.getByPlaceholderText('Nom complet (optionnel)')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Téléphone (optionnel)')).toBeInTheDocument()
    expect(screen.getByText("S'inscrire")).toBeInTheDocument()
  })

  it('toggle back to login mode hides register fields', () => {
    render(<LoginPage />)
    fireEvent.click(screen.getByText("Pas encore de compte ? S'inscrire"))
    expect(screen.getByPlaceholderText('Nom complet (optionnel)')).toBeInTheDocument()

    fireEvent.click(screen.getByText('Déjà un compte ? Se connecter'))
    expect(screen.queryByPlaceholderText('Nom complet (optionnel)')).not.toBeInTheDocument()
    expect(screen.queryByPlaceholderText('Téléphone (optionnel)')).not.toBeInTheDocument()
  })

  it('password toggle button switches between text and password type', () => {
    render(<LoginPage />)
    const passwordInput = screen.getByPlaceholderText('Mot de passe')
    expect(passwordInput).toHaveAttribute('type', 'password')

    // Find the toggle button (it's the button inside the password field container)
    const toggleButton = passwordInput.parentElement!.querySelector('button')!
    fireEvent.click(toggleButton)
    expect(passwordInput).toHaveAttribute('type', 'text')

    fireEvent.click(toggleButton)
    expect(passwordInput).toHaveAttribute('type', 'password')
  })

  it('shows error message when loginError is set', () => {
    vi.mocked(useAuth).mockReturnValue({
      login: mockLogin,
      register: mockRegister,
      isLoggingIn: false,
      isRegistering: false,
      loginError: new Error('Bad credentials'),
      registerError: null,
    } as ReturnType<typeof useAuth>)

    render(<LoginPage />)
    expect(screen.getByText('Bad credentials')).toBeInTheDocument()
  })

  it('submits login form with credentials', async () => {
    const user = userEvent.setup()
    render(<LoginPage />)
    await user.type(screen.getByPlaceholderText('Adresse email'), 'test@test.com')
    await user.type(screen.getByPlaceholderText('Mot de passe'), 'password123')
    await user.click(screen.getByText('Se connecter'))
    await waitFor(() => {
      expect(mockLogin).toHaveBeenCalledWith({ email: 'test@test.com', password: 'password123' })
    })
  })

  it('submits register form with credentials', async () => {
    const user = userEvent.setup()
    render(<LoginPage />)
    await user.click(screen.getByText("Pas encore de compte ? S'inscrire"))
    await user.type(screen.getByPlaceholderText('Adresse email'), 'new@test.com')
    await user.type(screen.getByPlaceholderText('Mot de passe'), 'password123')
    await user.type(screen.getByPlaceholderText('Nom complet (optionnel)'), 'John')
    await user.type(screen.getByPlaceholderText('Téléphone (optionnel)'), '0612345678')
    await user.click(screen.getByText("S'inscrire"))
    await waitFor(() => {
      expect(mockRegister).toHaveBeenCalledWith({
        email: 'new@test.com',
        password: 'password123',
        fullName: 'John',
        phone: '0612345678',
      })
    })
  })

  it('shows Inscription loading state when isRegistering', () => {
    vi.mocked(useAuth).mockReturnValue({
      login: mockLogin,
      register: mockRegister,
      isLoggingIn: false,
      isRegistering: true,
      loginError: null,
      registerError: null,
    } as ReturnType<typeof useAuth>)

    render(<LoginPage />)
    // Toggle to register mode first
    fireEvent.click(screen.getByText("Pas encore de compte ? S'inscrire"))
    expect(screen.getByText('Inscription...')).toBeInTheDocument()
  })

  it('shows loading state when isLoggingIn is true', () => {
    vi.mocked(useAuth).mockReturnValue({
      login: mockLogin,
      register: mockRegister,
      isLoggingIn: true,
      isRegistering: false,
      loginError: null,
      registerError: null,
    } as ReturnType<typeof useAuth>)

    render(<LoginPage />)
    expect(screen.getByText('Connexion...')).toBeInTheDocument()
  })
})
