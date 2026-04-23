import { describe, it, expect, vi } from 'vitest'
import { useAdminMutation } from '@/shared/hooks/useAdminMutation'
import {
  useUpdateTrip,
  useDeleteTrip,
  useArchiveTrip,
  useDeleteActivity,
  useDeleteAccommodation,
  useDeleteBudgetItem,
  useDeleteBaggageItem,
  useDeleteShare,
} from './mutations'

vi.mock('@/shared/hooks/useAdminMutation', () => ({
  useAdminMutation: vi.fn(() => ({
    mutate: vi.fn(),
    mutateAsync: vi.fn(),
    isPending: false,
  })),
}))

vi.mock('@/services', () => ({
  adminService: {
    updateTrip: vi.fn(),
    deleteTrip: vi.fn(),
    archiveTrip: vi.fn(),
    deleteActivity: vi.fn(),
    deleteAccommodation: vi.fn(),
    deleteBudgetItem: vi.fn(),
    deleteBaggageItem: vi.fn(),
    deleteShare: vi.fn(),
  },
}))

describe('trips mutations', () => {
  it('useUpdateTrip calls useAdminMutation with correct config', () => {
    vi.mocked(useAdminMutation).mockClear()
    useUpdateTrip('trip-1')
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([
          ['admin', 'trips'],
          ['admin', 'trip-detail', 'trip-1'],
        ]),
        successMessage: 'Voyage mis à jour',
      })
    )
  })

  it('useDeleteTrip calls useAdminMutation with correct config', () => {
    vi.mocked(useAdminMutation).mockClear()
    useDeleteTrip()
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([['admin', 'trips']]),
        successMessage: 'Voyage supprimé',
      })
    )
  })

  it('useArchiveTrip calls useAdminMutation with correct config', () => {
    vi.mocked(useAdminMutation).mockClear()
    useArchiveTrip('trip-2')
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([
          ['admin', 'trips'],
          ['admin', 'trip-detail', 'trip-2'],
        ]),
        successMessage: 'Voyage archivé',
      })
    )
  })

  it('useDeleteActivity calls useAdminMutation with correct config', () => {
    vi.mocked(useAdminMutation).mockClear()
    useDeleteActivity('trip-3')
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([
          ['admin', 'trip-detail', 'trip-3'],
          ['admin', 'activities'],
        ]),
        successMessage: 'Activité supprimée',
      })
    )
  })

  it('useDeleteAccommodation calls useAdminMutation with correct config', () => {
    vi.mocked(useAdminMutation).mockClear()
    useDeleteAccommodation('trip-4')
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([
          ['admin', 'trip-detail', 'trip-4'],
          ['admin', 'accommodations'],
        ]),
        successMessage: 'Hébergement supprimé',
      })
    )
  })

  it('useDeleteBudgetItem calls useAdminMutation with correct config', () => {
    vi.mocked(useAdminMutation).mockClear()
    useDeleteBudgetItem('trip-5')
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([
          ['admin', 'trip-detail', 'trip-5'],
          ['admin', 'budgetItems'],
        ]),
        successMessage: 'Ligne de budget supprimée',
      })
    )
  })

  it('useDeleteBaggageItem calls useAdminMutation with correct config', () => {
    vi.mocked(useAdminMutation).mockClear()
    useDeleteBaggageItem('trip-6')
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([
          ['admin', 'trip-detail', 'trip-6'],
          ['admin', 'baggage-items'],
        ]),
        successMessage: 'Élément de bagage supprimé',
      })
    )
  })

  it('useDeleteShare calls useAdminMutation with correct config', () => {
    vi.mocked(useAdminMutation).mockClear()
    useDeleteShare('trip-7')
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([
          ['admin', 'trip-detail', 'trip-7'],
          ['admin', 'trip-shares'],
        ]),
        successMessage: 'Partage révoqué',
      })
    )
  })
})
