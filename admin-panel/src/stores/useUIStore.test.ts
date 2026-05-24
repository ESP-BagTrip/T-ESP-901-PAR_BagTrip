import { describe, it, expect, beforeEach, vi } from 'vitest'

// Mock localStorage before importing the store
const localStorageMock = (() => {
  let store: Record<string, string> = {}
  return {
    getItem: vi.fn((key: string) => store[key] ?? null),
    setItem: vi.fn((key: string, value: string) => {
      store[key] = value
    }),
    removeItem: vi.fn((key: string) => {
      delete store[key]
    }),
    clear: vi.fn(() => {
      store = {}
    }),
    get length() {
      return Object.keys(store).length
    },
    key: vi.fn((index: number) => Object.keys(store)[index] ?? null),
  }
})()

Object.defineProperty(globalThis, 'localStorage', { value: localStorageMock })

// Import after mock
const { useUIStore } = await import('@/stores/useUIStore')

describe('useUIStore', () => {
  beforeEach(() => {
    useUIStore.setState({ sidebarCollapsed: false })
  })

  it('has sidebarCollapsed defaulting to false', () => {
    expect(useUIStore.getState().sidebarCollapsed).toBe(false)
  })

  it('sets sidebarCollapsed to true via setSidebarCollapsed', () => {
    useUIStore.getState().setSidebarCollapsed(true)
    expect(useUIStore.getState().sidebarCollapsed).toBe(true)
  })

  it('sets sidebarCollapsed back to false', () => {
    useUIStore.getState().setSidebarCollapsed(true)
    useUIStore.getState().setSidebarCollapsed(false)
    expect(useUIStore.getState().sidebarCollapsed).toBe(false)
  })

  it('toggles sidebarCollapsed from false to true', () => {
    useUIStore.getState().toggleSidebarCollapsed()
    expect(useUIStore.getState().sidebarCollapsed).toBe(true)
  })

  it('toggles sidebarCollapsed from true to false', () => {
    useUIStore.setState({ sidebarCollapsed: true })
    useUIStore.getState().toggleSidebarCollapsed()
    expect(useUIStore.getState().sidebarCollapsed).toBe(false)
  })

  it('toggles multiple times correctly', () => {
    useUIStore.getState().toggleSidebarCollapsed()
    expect(useUIStore.getState().sidebarCollapsed).toBe(true)
    useUIStore.getState().toggleSidebarCollapsed()
    expect(useUIStore.getState().sidebarCollapsed).toBe(false)
  })

  it('exposes setSidebarCollapsed and toggleSidebarCollapsed as functions', () => {
    const state = useUIStore.getState()
    expect(typeof state.setSidebarCollapsed).toBe('function')
    expect(typeof state.toggleSidebarCollapsed).toBe('function')
  })
})
