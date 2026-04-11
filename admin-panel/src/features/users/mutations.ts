'use client'

import { adminService } from '@/services'
import { useAdminMutation } from '@/shared/hooks/useAdminMutation'

const USER_KEYS = [['users'], ['admin', 'users']] as const

export function useUpdateUser(userId: string) {
  return useAdminMutation({
    mutationFn: (data: Record<string, unknown>) => adminService.updateUser(userId, data),
    invalidateKeys: [...USER_KEYS, ['admin', 'user-detail', userId]],
    successMessage: 'Utilisateur mis à jour',
  })
}

export function useResetAiQuota(userId: string) {
  return useAdminMutation({
    mutationFn: () => adminService.resetAiQuota(userId),
    invalidateKeys: [['admin', 'user-detail', userId]],
    successMessage: 'Quota IA réinitialisé',
  })
}

export function useBanUser(userId: string) {
  return useAdminMutation({
    mutationFn: (reason: string) => adminService.banUser(userId, reason),
    invalidateKeys: [...USER_KEYS, ['admin', 'user-detail', userId]],
    successMessage: 'Utilisateur banni',
  })
}

export function useUnbanUser(userId: string) {
  return useAdminMutation({
    mutationFn: () => adminService.unbanUser(userId),
    invalidateKeys: [...USER_KEYS, ['admin', 'user-detail', userId]],
    successMessage: 'Utilisateur débanni',
  })
}

export function useDeleteUser() {
  return useAdminMutation({
    mutationFn: (userId: string) => adminService.deleteUser(userId),
    invalidateKeys: [...USER_KEYS],
    successMessage: 'Utilisateur supprimé',
  })
}

export function useBulkChangePlan() {
  return useAdminMutation({
    mutationFn: ({ userIds, plan }: { userIds: string[]; plan: string }) =>
      adminService.bulkChangePlan(userIds, plan),
    invalidateKeys: [...USER_KEYS],
    successMessage: 'Plans mis à jour',
  })
}

export function useBulkBan() {
  return useAdminMutation({
    mutationFn: ({ userIds, reason }: { userIds: string[]; reason: string }) =>
      adminService.bulkBan(userIds, reason),
    invalidateKeys: [...USER_KEYS],
    successMessage: 'Utilisateurs bannis',
  })
}
