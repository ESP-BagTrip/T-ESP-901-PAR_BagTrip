import { describe, it, expect, beforeEach } from 'vitest'
import { useDashboardStore } from '@/stores/useDashboardStore'

describe('useDashboardStore', () => {
  beforeEach(() => {
    useDashboardStore.setState({ activeTab: 'dashboard' })
  })

  it('should have initial state with activeTab set to dashboard', () => {
    const state = useDashboardStore.getState()
    expect(state.activeTab).toBe('dashboard')
  })

  it('should update activeTab when setActiveTab is called', () => {
    const { setActiveTab } = useDashboardStore.getState()

    setActiveTab('users')
    expect(useDashboardStore.getState().activeTab).toBe('users')

    setActiveTab('trips')
    expect(useDashboardStore.getState().activeTab).toBe('trips')
  })
})
