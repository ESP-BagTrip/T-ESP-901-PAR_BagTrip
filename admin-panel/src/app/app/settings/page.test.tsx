import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { useAuth } from '@/hooks'

const mockLogout = vi.fn()
vi.mock('@/hooks', () => ({
  useAuth: vi.fn(() => ({
    user: { email: 'admin@bagtrip.com', plan: 'ADMIN' },
    logout: mockLogout,
  })),
}))
vi.mock('next-themes', () => ({
  useTheme: vi.fn(() => ({ theme: 'system', setTheme: vi.fn() })),
}))
vi.mock('@/components/layout/PageHeader', () => ({
  PageHeader: ({ title, description }: { title: string; description: string }) => (
    <div><h1>{title}</h1><p>{description}</p></div>
  ),
}))
vi.mock('@/components/ui/card', () => ({
  Card: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  CardContent: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  CardDescription: ({ children }: { children: React.ReactNode }) => <p>{children}</p>,
  CardHeader: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  CardTitle: ({ children }: { children: React.ReactNode }) => <h2>{children}</h2>,
}))
vi.mock('@/components/ui/label', () => ({
  Label: ({ children, ...props }: React.ComponentProps<'label'> & { children: React.ReactNode }) => <label {...props}>{children}</label>,
}))
vi.mock('@/components/ui/button', () => ({
  Button: ({ children, ...props }: React.ComponentProps<'button'>) => <button {...props}>{children}</button>,
}))
vi.mock('@/components/ui/badge', () => ({
  Badge: ({ children }: { children: React.ReactNode }) => <span>{children}</span>,
}))
vi.mock('@/components/ui/separator', () => ({
  Separator: () => <hr />,
}))
vi.mock('@/components/ui/radio-group', () => ({
  RadioGroup: ({ children, ...props }: { children: React.ReactNode; value?: string; onValueChange?: (v: string) => void; className?: string }) => (
    <div role="radiogroup" data-value={props.value}>{children}</div>
  ),
  RadioGroupItem: ({ value, id }: { value: string; id?: string }) => (
    <input type="radio" id={id} value={value} data-state="unchecked" readOnly />
  ),
}))

import SettingsPage from './page'

describe('SettingsPage', () => {
  beforeEach(() => {
    mockLogout.mockClear()
  })

  it('renders settings heading', () => {
    render(<SettingsPage />)
    expect(screen.getByText('Paramètres')).toBeInTheDocument()
  })

  it('renders profile section with user email', () => {
    render(<SettingsPage />)
    expect(screen.getByText('admin@bagtrip.com')).toBeInTheDocument()
  })

  it('renders user plan badge', () => {
    render(<SettingsPage />)
    expect(screen.getAllByText('ADMIN').length).toBeGreaterThan(0)
  })

  it('renders appearance section with theme options', () => {
    render(<SettingsPage />)
    expect(screen.getByText('Apparence')).toBeInTheDocument()
    expect(screen.getByText('Clair')).toBeInTheDocument()
    expect(screen.getByText('Sombre')).toBeInTheDocument()
  })

  it('renders plans & quotas section', () => {
    render(<SettingsPage />)
    expect(screen.getByText('Plans & Quotas IA')).toBeInTheDocument()
    expect(screen.getByText('FREE')).toBeInTheDocument()
    expect(screen.getByText('PREMIUM')).toBeInTheDocument()
  })

  it('renders feature flags section', () => {
    render(<SettingsPage />)
    expect(screen.getByText('Feature Flags')).toBeInTheDocument()
  })

  it('renders session section with logout button', () => {
    render(<SettingsPage />)
    expect(screen.getByText('Session')).toBeInTheDocument()
    expect(screen.getByText('Se déconnecter')).toBeInTheDocument()
  })

  it('calls logout when clicking disconnect button', async () => {
    const user = userEvent.setup()
    render(<SettingsPage />)
    await user.click(screen.getByText('Se déconnecter'))
    expect(mockLogout).toHaveBeenCalledTimes(1)
  })

  it('renders with null user gracefully', () => {
    vi.mocked(useAuth).mockReturnValueOnce({ user: null, logout: mockLogout } as any)
    render(<SettingsPage />)
    // Should show '—' for missing user fields
    const dashes = screen.getAllByText('—')
    expect(dashes.length).toBeGreaterThanOrEqual(1)
  })

  it('renders PlanCard with numeric limits', () => {
    render(<SettingsPage />)
    expect(screen.getByText('3')).toBeInTheDocument()
    expect(screen.getByText('2')).toBeInTheDocument()
  })

  it('renders PlanCard with unlimited text', () => {
    render(<SettingsPage />)
    const unlimitedTexts = screen.getAllByText('Illimité')
    expect(unlimitedTexts.length).toBeGreaterThanOrEqual(2)
  })
})
