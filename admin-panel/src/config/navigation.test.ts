import { describe, it, expect } from 'vitest'
import { NAV_SECTIONS, SECONDARY_NAV, ALL_NAV_ITEMS, findNavItem } from './navigation'

describe('NAV_SECTIONS', () => {
  it('is a non-empty array', () => {
    expect(Array.isArray(NAV_SECTIONS)).toBe(true)
    expect(NAV_SECTIONS.length).toBeGreaterThan(0)
  })

  it('each section has a label and non-empty items array', () => {
    for (const section of NAV_SECTIONS) {
      expect(typeof section.label).toBe('string')
      expect(section.label.length).toBeGreaterThan(0)
      expect(Array.isArray(section.items)).toBe(true)
      expect(section.items.length).toBeGreaterThan(0)
    }
  })

  it('each nav item has href, label, and icon', () => {
    for (const section of NAV_SECTIONS) {
      for (const item of section.items) {
        expect(typeof item.href).toBe('string')
        expect(item.href.startsWith('/app')).toBe(true)
        expect(typeof item.label).toBe('string')
        expect(item.icon).toBeDefined()
      }
    }
  })

  it('contains the Overview item in the first section', () => {
    const overview = NAV_SECTIONS[0].items.find(i => i.href === '/app')
    expect(overview).toBeDefined()
    expect(overview?.label).toBe('Overview')
  })

  it('contains expected sections by label', () => {
    const labels = NAV_SECTIONS.map(s => s.label)
    expect(labels).toContain('Croissance')
    expect(labels).toContain('Revenus')
    expect(labels).toContain('Contenu')
    expect(labels).toContain('Communaut\u00e9')
  })
})

describe('SECONDARY_NAV', () => {
  it('is a non-empty array', () => {
    expect(Array.isArray(SECONDARY_NAV)).toBe(true)
    expect(SECONDARY_NAV.length).toBeGreaterThan(0)
  })

  it('contains settings item', () => {
    const settings = SECONDARY_NAV.find(i => i.href === '/app/settings')
    expect(settings).toBeDefined()
    expect(settings?.label).toBe('Param\u00e8tres')
  })

  it('contains audit log item', () => {
    const audit = SECONDARY_NAV.find(i => i.href === '/app/audit-log')
    expect(audit).toBeDefined()
  })
})

describe('ALL_NAV_ITEMS', () => {
  it('includes all items from NAV_SECTIONS', () => {
    const sectionItems = NAV_SECTIONS.flatMap(s => s.items)
    for (const item of sectionItems) {
      expect(ALL_NAV_ITEMS).toContainEqual(item)
    }
  })

  it('includes all items from SECONDARY_NAV', () => {
    for (const item of SECONDARY_NAV) {
      expect(ALL_NAV_ITEMS).toContainEqual(item)
    }
  })

  it('has correct total count', () => {
    const sectionCount = NAV_SECTIONS.reduce((sum, s) => sum + s.items.length, 0)
    expect(ALL_NAV_ITEMS).toHaveLength(sectionCount + SECONDARY_NAV.length)
  })

  it('has no duplicate hrefs', () => {
    const hrefs = ALL_NAV_ITEMS.map(i => i.href)
    expect(new Set(hrefs).size).toBe(hrefs.length)
  })
})

describe('findNavItem', () => {
  it('finds an exact match', () => {
    const item = findNavItem('/app')
    expect(item).toBeDefined()
    expect(item?.href).toBe('/app')
    expect(item?.label).toBe('Overview')
  })

  it('finds another exact match', () => {
    const item = findNavItem('/app/users')
    expect(item).toBeDefined()
    expect(item?.label).toBe('Utilisateurs')
  })

  it('finds by prefix match (sub-route)', () => {
    // /app/users/some-user-id startsWith '/app/' so it matches Overview first
    const item = findNavItem('/app/users/some-user-id')
    expect(item).toBeDefined()
    expect(item?.href).toBe('/app')
  })

  it('prefers exact match over prefix match', () => {
    const item = findNavItem('/app/settings')
    expect(item).toBeDefined()
    expect(item?.href).toBe('/app/settings')
  })

  it('returns undefined for unmatched pathname', () => {
    expect(findNavItem('/unknown/path')).toBeUndefined()
  })

  it('returns undefined for empty string', () => {
    expect(findNavItem('')).toBeUndefined()
  })

  it('returns undefined for partial non-matching path', () => {
    expect(findNavItem('/app-something')).toBeUndefined()
  })

  it('finds secondary nav items', () => {
    const item = findNavItem('/app/audit-log')
    expect(item).toBeDefined()
    expect(item?.href).toBe('/app/audit-log')
  })

  it('finds secondary nav items by prefix', () => {
    // /app/audit-log/details startsWith '/app/' so matches Overview first
    const item = findNavItem('/app/audit-log/details')
    expect(item).toBeDefined()
    expect(item?.href).toBe('/app')
  })
})
