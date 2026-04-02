import { describe, it, expect, vi, beforeEach } from 'vitest'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'
import { adminService } from '@/services'

vi.mock('@/shared/hooks/usePaginatedQuery', () => ({
  usePaginatedQuery: vi.fn(() => ({ data: null, isLoading: false, page: 1, setPage: vi.fn() })),
}))

vi.mock('@/services', () => ({
  adminService: { getAllBudgetItems: vi.fn() },
}))

describe('useBudgetItemsTab', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should call usePaginatedQuery with correct queryKey', async () => {
    const { useBudgetItemsTab } = await import('@/features/budget-items/hooks')
    useBudgetItemsTab({ enabled: true })

    expect(usePaginatedQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'budgetItems'],
        enabled: true,
      })
    )
  })

  it('should pass enabled=false correctly', async () => {
    const { useBudgetItemsTab } = await import('@/features/budget-items/hooks')
    useBudgetItemsTab({ enabled: false })

    expect(usePaginatedQuery).toHaveBeenCalledWith(
      expect.objectContaining({ enabled: false })
    )
  })

  it('should use adminService.getAllBudgetItems as queryFn', async () => {
    const { useBudgetItemsTab } = await import('@/features/budget-items/hooks')
    useBudgetItemsTab({ enabled: true })

    const call = vi.mocked(usePaginatedQuery).mock.calls[0][0]
    const params = { page: 1, limit: 10 }
    call.queryFn(params)

    expect(adminService.getAllBudgetItems).toHaveBeenCalledWith(params)
  })
})
