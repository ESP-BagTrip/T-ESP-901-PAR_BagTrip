import { describe, it, expect } from 'vitest'
import { TAB_REGISTRY } from '../registry'

describe('TAB_REGISTRY', () => {
  it('has 15 entries', () => {
    expect(TAB_REGISTRY).toHaveLength(15)
  })

  it('each has id, name, component', () => {
    TAB_REGISTRY.forEach((tab) => {
      expect(typeof tab.id).toBe('string')
      expect(typeof tab.name).toBe('string')
      expect(tab.component).toBeDefined()
      expect(typeof tab.component).toBe('object')
    })
  })

  it('has unique ids', () => {
    const ids = TAB_REGISTRY.map((t) => t.id)
    expect(new Set(ids).size).toBe(ids.length)
  })

  it('contains all expected tabs', () => {
    const ids = TAB_REGISTRY.map((t) => t.id)
    const expected = [
      'dashboard',
      'users',
      'trips',
      'profiles',
      'travelers',
      'bookingIntents',
      'flights',
      'flightSearches',
      'accommodations',
      'baggageItems',
      'activities',
      'budgetItems',
      'tripShares',
      'feedbacks',
      'notifications',
    ]
    expected.forEach((id) => expect(ids).toContain(id))
  })

  it('has correct names', () => {
    const tab = TAB_REGISTRY.find((t) => t.id === 'dashboard')
    expect(tab?.name).toBe('Dashboard')
    const usersTab = TAB_REGISTRY.find((t) => t.id === 'users')
    expect(usersTab?.name).toBe('Utilisateurs')
  })
})
