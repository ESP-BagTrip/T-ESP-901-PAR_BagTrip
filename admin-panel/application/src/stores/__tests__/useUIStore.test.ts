import { describe, it, expect, beforeEach, vi } from 'vitest'

// Mock zustand/middleware to bypass persist storage issues in test env
vi.mock('zustand/middleware', () => ({
  persist: (fn: unknown) => fn,
}))

import { useUIStore } from '@/stores/useUIStore'

describe('useUIStore', () => {
  beforeEach(() => {
    useUIStore.setState({ sidebarOpen: true, theme: 'light' })
  })

  it('should have correct initial state', () => {
    const state = useUIStore.getState()
    expect(state.sidebarOpen).toBe(true)
    expect(state.theme).toBe('light')
  })

  it('should set sidebarOpen with setSidebarOpen', () => {
    const { setSidebarOpen } = useUIStore.getState()

    setSidebarOpen(false)
    expect(useUIStore.getState().sidebarOpen).toBe(false)

    setSidebarOpen(true)
    expect(useUIStore.getState().sidebarOpen).toBe(true)
  })

  it('should toggle sidebar with toggleSidebar', () => {
    const { toggleSidebar } = useUIStore.getState()

    toggleSidebar()
    expect(useUIStore.getState().sidebarOpen).toBe(false)

    toggleSidebar()
    expect(useUIStore.getState().sidebarOpen).toBe(true)
  })

  it('should set theme with setTheme', () => {
    const { setTheme } = useUIStore.getState()

    setTheme('dark')
    expect(useUIStore.getState().theme).toBe('dark')

    setTheme('light')
    expect(useUIStore.getState().theme).toBe('light')
  })
})
