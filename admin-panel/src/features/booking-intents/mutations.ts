'use client'

import { adminService } from '@/services'
import { useAdminMutation } from '@/shared/hooks/useAdminMutation'

const KEYS = [['admin', 'booking-intents']] as const

export function useForceBookingStatus(intentId: string) {
  return useAdminMutation({
    mutationFn: (status: string) => adminService.forceBookingStatus(intentId, status),
    invalidateKeys: [...KEYS, ['admin', 'booking-detail', intentId]],
    successMessage: 'Statut mis à jour',
  })
}

export function useCancelBooking(intentId: string) {
  return useAdminMutation({
    mutationFn: () => adminService.cancelBooking(intentId),
    invalidateKeys: [...KEYS, ['admin', 'booking-detail', intentId]],
    successMessage: 'Booking annulé',
  })
}

export function useMarkRefunded(intentId: string) {
  return useAdminMutation({
    mutationFn: () => adminService.markBookingRefunded(intentId),
    invalidateKeys: [...KEYS, ['admin', 'booking-detail', intentId]],
    successMessage: 'Booking marqué comme remboursé',
  })
}
