import { describe, it, expect, vi } from 'vitest'
import { useAdminMutation } from '@/shared/hooks/useAdminMutation'
import { useForceBookingStatus, useCancelBooking, useMarkRefunded } from './mutations'

vi.mock('@/shared/hooks/useAdminMutation', () => ({
  useAdminMutation: vi.fn(() => ({
    mutate: vi.fn(),
    mutateAsync: vi.fn(),
    isPending: false,
  })),
}))

vi.mock('@/services', () => ({
  adminService: {
    forceBookingStatus: vi.fn(),
    cancelBooking: vi.fn(),
    markBookingRefunded: vi.fn(),
  },
}))

describe('booking-intents mutations', () => {
  it('useForceBookingStatus calls useAdminMutation with correct config', () => {
    useForceBookingStatus('intent-123')
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([
          ['admin', 'booking-intents'],
          ['admin', 'booking-detail', 'intent-123'],
        ]),
        successMessage: 'Statut mis à jour',
      })
    )
  })

  it('useCancelBooking calls useAdminMutation with correct config', () => {
    vi.mocked(useAdminMutation).mockClear()
    useCancelBooking('intent-456')
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([['admin', 'booking-detail', 'intent-456']]),
        successMessage: 'Booking annulé',
      })
    )
  })

  it('useMarkRefunded calls useAdminMutation with correct config', () => {
    vi.mocked(useAdminMutation).mockClear()
    useMarkRefunded('intent-789')
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([['admin', 'booking-detail', 'intent-789']]),
        successMessage: 'Booking marqué comme remboursé',
      })
    )
  })
})
