import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface UIState {
  sidebarCollapsed: boolean
  setSidebarCollapsed: (collapsed: boolean) => void
  toggleSidebarCollapsed: () => void
}

/**
 * UI store — user preferences persisted in localStorage.
 * Theme is handled by next-themes, date range by URL, active tab by routing.
 */
export const useUIStore = create<UIState>()(
  persist(
    set => ({
      sidebarCollapsed: false,
      setSidebarCollapsed: (sidebarCollapsed: boolean) => set({ sidebarCollapsed }),
      toggleSidebarCollapsed: () => set(state => ({ sidebarCollapsed: !state.sidebarCollapsed })),
    }),
    {
      name: 'bagtrip-ui-store',
    }
  )
)
