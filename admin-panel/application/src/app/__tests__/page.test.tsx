import { describe, it, expect } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import Home from '../page'

describe('Home page', () => {
  it('renders hero title "BagTrip Administration"', () => {
    render(<Home />)
    expect(screen.getByText('BagTrip Administration')).toBeInTheDocument()
  })

  it('renders stats section with stat cards', () => {
    render(<Home />)
    expect(screen.getByText('Performances en temps réel')).toBeInTheDocument()
    expect(screen.getByText('Utilisateurs actifs')).toBeInTheDocument()
    expect(screen.getByText('12,543')).toBeInTheDocument()
    expect(screen.getByText('8,247')).toBeInTheDocument()
    expect(screen.getByText('4.8/5')).toBeInTheDocument()
    expect(screen.getByText('245,680')).toBeInTheDocument()
  })

  it('renders features grid by default', () => {
    render(<Home />)
    expect(screen.getByText('Gestion Utilisateurs')).toBeInTheDocument()
    expect(screen.getByText('Gestion Voyages')).toBeInTheDocument()
    expect(screen.getByText('Support Client')).toBeInTheDocument()
    expect(screen.getByText('Analytics & BI')).toBeInTheDocument()
  })

  it('clicking Technologies tab shows tech stack content with Frontend and Backend & Infra', () => {
    render(<Home />)
    fireEvent.click(screen.getByText('Technologies'))

    expect(screen.getByText('Frontend')).toBeInTheDocument()
    expect(screen.getByText('Backend & Infra')).toBeInTheDocument()
    expect(screen.getByText('Next.js 15')).toBeInTheDocument()
    expect(screen.getByText('TypeScript')).toBeInTheDocument()
    expect(screen.getByText('TailwindCSS 4')).toBeInTheDocument()
    expect(screen.getByText('React Query')).toBeInTheDocument()
    expect(screen.getByText('Node.js + Express')).toBeInTheDocument()
    expect(screen.getByText('PostgreSQL')).toBeInTheDocument()
    expect(screen.getByText('JWT + OAuth')).toBeInTheDocument()
    expect(screen.getByText('Docker')).toBeInTheDocument()
  })

  it('renders footer with links', () => {
    render(<Home />)
    expect(screen.getByText('Liens utiles')).toBeInTheDocument()
    expect(screen.getByText('Documentation')).toBeInTheDocument()
    expect(screen.getByText('Support')).toBeInTheDocument()
  })

  it('renders login button in nav', () => {
    render(<Home />)
    const navLinks = screen.getAllByText('Connexion')
    expect(navLinks.length).toBeGreaterThan(0)
  })
})
