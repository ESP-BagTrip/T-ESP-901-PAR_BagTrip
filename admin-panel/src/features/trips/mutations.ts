'use client'

import { adminService } from '@/services'
import { useAdminMutation } from '@/shared/hooks/useAdminMutation'

const TRIP_KEYS = [['admin', 'trips']] as const

export function useUpdateTrip(tripId: string) {
  return useAdminMutation({
    mutationFn: (data: Record<string, unknown>) => adminService.updateTrip(tripId, data),
    invalidateKeys: [...TRIP_KEYS, ['admin', 'trip-detail', tripId]],
    successMessage: 'Voyage mis à jour',
  })
}

export function useDeleteTrip() {
  return useAdminMutation({
    mutationFn: (tripId: string) => adminService.deleteTrip(tripId),
    invalidateKeys: [...TRIP_KEYS],
    successMessage: 'Voyage supprimé',
  })
}

export function useArchiveTrip(tripId: string) {
  return useAdminMutation({
    mutationFn: () => adminService.archiveTrip(tripId),
    invalidateKeys: [...TRIP_KEYS, ['admin', 'trip-detail', tripId]],
    successMessage: 'Voyage archivé',
  })
}

export function useDeleteActivity(tripId: string) {
  return useAdminMutation({
    mutationFn: (activityId: string) => adminService.deleteActivity(tripId, activityId),
    invalidateKeys: [
      ['admin', 'trip-detail', tripId],
      ['admin', 'activities'],
    ],
    successMessage: 'Activité supprimée',
  })
}

export function useDeleteAccommodation(tripId: string) {
  return useAdminMutation({
    mutationFn: (accId: string) => adminService.deleteAccommodation(tripId, accId),
    invalidateKeys: [
      ['admin', 'trip-detail', tripId],
      ['admin', 'accommodations'],
    ],
    successMessage: 'Hébergement supprimé',
  })
}

export function useDeleteBudgetItem(tripId: string) {
  return useAdminMutation({
    mutationFn: (itemId: string) => adminService.deleteBudgetItem(tripId, itemId),
    invalidateKeys: [
      ['admin', 'trip-detail', tripId],
      ['admin', 'budgetItems'],
    ],
    successMessage: 'Ligne de budget supprimée',
  })
}

export function useDeleteBaggageItem(tripId: string) {
  return useAdminMutation({
    mutationFn: (itemId: string) => adminService.deleteBaggageItem(tripId, itemId),
    invalidateKeys: [
      ['admin', 'trip-detail', tripId],
      ['admin', 'baggage-items'],
    ],
    successMessage: 'Élément de bagage supprimé',
  })
}

export function useDeleteShare(tripId: string) {
  return useAdminMutation({
    mutationFn: (shareId: string) => adminService.deleteShare(tripId, shareId),
    invalidateKeys: [
      ['admin', 'trip-detail', tripId],
      ['admin', 'trip-shares'],
    ],
    successMessage: 'Partage révoqué',
  })
}
