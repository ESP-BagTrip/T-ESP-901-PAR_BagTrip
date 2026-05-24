import { render, screen } from '@testing-library/react'

vi.mock('next/link', () => ({
  default: ({ children, href, ...props }: { children: React.ReactNode; href: string }) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
}))

import Home from './page'

describe('Home (Landing Page)', () => {
  it('renders without crashing', () => {
    render(<Home />)
    expect(screen.getByText('BagTrip Administration')).toBeInTheDocument()
  })

  it('renders the hero section', () => {
    render(<Home />)
    expect(screen.getByText(/Plateforme d'administration/)).toBeInTheDocument()
  })

  it('renders login links', () => {
    render(<Home />)
    const loginLinks = screen.getAllByText('Connexion')
    expect(loginLinks.length).toBeGreaterThan(0)
  })

  it('renders stats section', () => {
    render(<Home />)
    expect(screen.getByText('Performances en temps réel')).toBeInTheDocument()
  })

  it('renders features section', () => {
    render(<Home />)
    expect(screen.getByText(/Interface d'administration complète/)).toBeInTheDocument()
  })

  it('renders all stat cards', () => {
    render(<Home />)
    expect(screen.getByText('12,543')).toBeInTheDocument()
    expect(screen.getByText('8,247')).toBeInTheDocument()
    expect(screen.getByText('4.8/5')).toBeInTheDocument()
    expect(screen.getByText('245,680')).toBeInTheDocument()
  })

  it('renders feature cards', () => {
    render(<Home />)
    expect(screen.getByText('Gestion Utilisateurs')).toBeInTheDocument()
    expect(screen.getByText('Gestion Voyages')).toBeInTheDocument()
    expect(screen.getByText('Support Client')).toBeInTheDocument()
    expect(screen.getByText('Analytics & BI')).toBeInTheDocument()
  })

  it('switches to tech tab', async () => {
    const { default: userEvent } = await import('@testing-library/user-event')
    const user = userEvent.setup()
    render(<Home />)
    await user.click(screen.getByText('Technologies'))
    expect(screen.getByText('Frontend')).toBeInTheDocument()
    expect(screen.getByText('Backend & Infra')).toBeInTheDocument()
    expect(screen.getByText('Next.js 15')).toBeInTheDocument()
  })

  it('switches back to features tab', async () => {
    const { default: userEvent } = await import('@testing-library/user-event')
    const user = userEvent.setup()
    render(<Home />)
    await user.click(screen.getByText('Technologies'))
    await user.click(screen.getByText('Fonctionnalités'))
    expect(screen.getByText('Gestion Utilisateurs')).toBeInTheDocument()
  })

  it('renders footer section', () => {
    render(<Home />)
    expect(screen.getByText('Liens utiles')).toBeInTheDocument()
    expect(screen.getByText(/admin@bagtrip\.com/)).toBeInTheDocument()
  })

  it('renders CTA section', () => {
    render(<Home />)
    expect(screen.getByText(/Prêt à découvrir BagTrip Admin/)).toBeInTheDocument()
  })
})
