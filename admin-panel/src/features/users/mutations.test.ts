import { describe, it, expect, vi } from 'vitest'
import { useAdminMutation } from '@/shared/hooks/useAdminMutation'
import {
  useUpdateUser,
  useResetAiQuota,
  useBanUser,
  useUnbanUser,
  useDeleteUser,
  useBulkChangePlan,
  useBulkBan,
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
    updateUser: vi.fn(),
    resetAiQuota: vi.fn(),
    banUser: vi.fn(),
    unbanUser: vi.fn(),
    deleteUser: vi.fn(),
    bulkChangePlan: vi.fn(),
    bulkBan: vi.fn(),
  },
}))

describe('users mutations', () => {
  it('useUpdateUser calls useAdminMutation with correct config', () => {
    vi.mocked(useAdminMutation).mockClear()
    useUpdateUser('user-1')
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([
          ['users'],
          ['admin', 'users'],
          ['admin', 'user-detail', 'user-1'],
        ]),
        successMessage: 'Utilisateur mis à jour',
      })
    )
  })

  it('useResetAiQuota calls useAdminMutation with correct config', () => {
    vi.mocked(useAdminMutation).mockClear()
    useResetAiQuota('user-2')
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([
          ['admin', 'user-detail', 'user-2'],
        ]),
        successMessage: 'Quota IA réinitialisé',
      })
    )
  })

  it('useBanUser calls useAdminMutation with correct config', () => {
    vi.mocked(useAdminMutation).mockClear()
    useBanUser('user-3')
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([
          ['users'],
          ['admin', 'users'],
          ['admin', 'user-detail', 'user-3'],
        ]),
        successMessage: 'Utilisateur banni',
      })
    )
  })

  it('useUnbanUser calls useAdminMutation with correct config', () => {
    vi.mocked(useAdminMutation).mockClear()
    useUnbanUser('user-4')
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([
          ['users'],
          ['admin', 'users'],
          ['admin', 'user-detail', 'user-4'],
        ]),
        successMessage: 'Utilisateur débanni',
      })
    )
  })

  it('useDeleteUser calls useAdminMutation with correct config', () => {
    vi.mocked(useAdminMutation).mockClear()
    useDeleteUser()
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([
          ['users'],
          ['admin', 'users'],
        ]),
        successMessage: 'Utilisateur supprimé',
      })
    )
  })

  it('useBulkChangePlan calls useAdminMutation with correct config', () => {
    vi.mocked(useAdminMutation).mockClear()
    useBulkChangePlan()
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([
          ['users'],
          ['admin', 'users'],
        ]),
        successMessage: 'Plans mis à jour',
      })
    )
  })

  it('useBulkBan calls useAdminMutation with correct config', () => {
    vi.mocked(useAdminMutation).mockClear()
    useBulkBan()
    expect(useAdminMutation).toHaveBeenCalledWith(
      expect.objectContaining({
        invalidateKeys: expect.arrayContaining([
          ['users'],
          ['admin', 'users'],
        ]),
        successMessage: 'Utilisateurs bannis',
      })
    )
  })
})
