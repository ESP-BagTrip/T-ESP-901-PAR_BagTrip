import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { TooltipProvider } from '@/components/ui/tooltip'
import { UserPill } from './UserPill'
import type { User } from '@/types'

const makeUser = (overrides: Partial<User> = {}): User => ({
  id: '1',
  email: 'john.doe@example.com',
  plan: 'FREE',
  created_at: '2024-01-01',
  updated_at: null,
  ...overrides,
})

function renderWithProviders(ui: React.ReactElement) {
  return render(<TooltipProvider>{ui}</TooltipProvider>)
}

describe('UserPill', () => {
  describe('initials extraction', () => {
    it('extracts initials from two-part email local (dot separator)', () => {
      renderWithProviders(<UserPill user={makeUser({ email: 'john.doe@test.com' })} collapsed={false} />)
      expect(screen.getByText('JD')).toBeInTheDocument()
    })

    it('extracts initials from two-part email local (dash separator)', () => {
      renderWithProviders(<UserPill user={makeUser({ email: 'jane-smith@test.com' })} collapsed={false} />)
      expect(screen.getByText('JS')).toBeInTheDocument()
    })

    it('extracts initials from two-part email local (underscore separator)', () => {
      renderWithProviders(<UserPill user={makeUser({ email: 'bob_ross@test.com' })} collapsed={false} />)
      expect(screen.getByText('BR')).toBeInTheDocument()
    })

    it('extracts first two chars when single-part email local', () => {
      renderWithProviders(<UserPill user={makeUser({ email: 'admin@test.com' })} collapsed={false} />)
      expect(screen.getByText('AD')).toBeInTheDocument()
    })
  })

  describe('expanded state', () => {
    it('shows email text', () => {
      renderWithProviders(<UserPill user={makeUser()} collapsed={false} />)
      expect(screen.getByText('john.doe@example.com')).toBeInTheDocument()
    })

    it('shows plan badge', () => {
      renderWithProviders(<UserPill user={makeUser({ plan: 'PREMIUM' })} collapsed={false} />)
      expect(screen.getByText('PREMIUM')).toBeInTheDocument()
    })
  })

  describe('collapsed state', () => {
    it('renders initials in avatar', () => {
      renderWithProviders(<UserPill user={makeUser({ email: 'john.doe@test.com' })} collapsed={true} />)
      expect(screen.getByText('JD')).toBeInTheDocument()
    })

    it('does not show email as direct paragraph', () => {
      renderWithProviders(<UserPill user={makeUser()} collapsed={true} />)
      // In collapsed mode, email is only in tooltip content (not rendered until hover)
      // The initials should be visible
      expect(screen.getByText('JD')).toBeInTheDocument()
      // No <p> tag with the email in the DOM
      const paragraphs = document.querySelectorAll('p')
      const emailParagraph = Array.from(paragraphs).find(p => p.textContent === 'john.doe@example.com')
      expect(emailParagraph).toBeUndefined()
    })
  })
})
