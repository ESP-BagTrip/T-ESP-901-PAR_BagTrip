import { create } from 'zustand'

interface DashboardState {
  activeTab: string
  setActiveTab: (tab: string) => void
}

export const useDashboardStore = create<DashboardState>(set => ({
  activeTab: 'users',
  setActiveTab: (tab: string) => set({ activeTab: tab }),
}))
