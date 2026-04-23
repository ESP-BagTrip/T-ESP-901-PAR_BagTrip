import { describe, it, expect, vi, beforeEach } from 'vitest'

const mockInvalidateQueries = vi.fn().mockResolvedValue(undefined)

vi.mock('@tanstack/react-query', () => ({
  useMutation: vi.fn((opts: Record<string, unknown>) => opts),
  useQueryClient: vi.fn(() => ({
    invalidateQueries: mockInvalidateQueries,
  })),
}))

vi.mock('sonner', () => ({
  toast: { success: vi.fn(), error: vi.fn() },
}))

import { useAdminMutation } from './useAdminMutation'
import { toast } from 'sonner'

beforeEach(() => {
  vi.clearAllMocks()
})

describe('useAdminMutation', () => {
  it('passes the mutationFn to useMutation', () => {
    const mutationFn = vi.fn()
    const result = useAdminMutation({ mutationFn }) as Record<string, unknown>
    expect(result.mutationFn).toBe(mutationFn)
  })

  describe('onSuccess', () => {
    it('invalidates all provided query keys', async () => {
      const result = useAdminMutation({
        mutationFn: vi.fn(),
        invalidateKeys: [['users'], ['stats']],
      }) as Record<string, (data: unknown) => Promise<void>>

      await result.onSuccess('data')

      expect(mockInvalidateQueries).toHaveBeenCalledTimes(2)
      expect(mockInvalidateQueries).toHaveBeenCalledWith({ queryKey: ['users'] })
      expect(mockInvalidateQueries).toHaveBeenCalledWith({ queryKey: ['stats'] })
    })

    it('shows a success toast when successMessage is provided', async () => {
      const result = useAdminMutation({
        mutationFn: vi.fn(),
        successMessage: 'Created!',
      }) as Record<string, (data: unknown) => Promise<void>>

      await result.onSuccess('data')

      expect(toast.success).toHaveBeenCalledWith('Created!')
    })

    it('does not show toast when successMessage is not provided', async () => {
      const result = useAdminMutation({
        mutationFn: vi.fn(),
      }) as Record<string, (data: unknown) => Promise<void>>

      await result.onSuccess('data')

      expect(toast.success).not.toHaveBeenCalled()
    })

    it('calls the user-provided onSuccess callback with data', async () => {
      const onSuccess = vi.fn()
      const result = useAdminMutation({
        mutationFn: vi.fn(),
        onSuccess,
      }) as Record<string, (data: unknown) => Promise<void>>

      await result.onSuccess('response-data')

      expect(onSuccess).toHaveBeenCalledWith('response-data')
    })

    it('does not call onSuccess callback when not provided', async () => {
      const result = useAdminMutation({
        mutationFn: vi.fn(),
      }) as Record<string, (data: unknown) => Promise<void>>

      // Should not throw
      await expect(result.onSuccess('data')).resolves.toBeUndefined()
    })

    it('does not invalidate when invalidateKeys is empty', async () => {
      const result = useAdminMutation({
        mutationFn: vi.fn(),
        invalidateKeys: [],
      }) as Record<string, (data: unknown) => Promise<void>>

      await result.onSuccess('data')

      expect(mockInvalidateQueries).not.toHaveBeenCalled()
    })
  })

  describe('onError', () => {
    it('shows an error toast with the error message', () => {
      const result = useAdminMutation({
        mutationFn: vi.fn(),
      }) as Record<string, (error: Error) => void>

      result.onError(new Error('Network failure'))

      expect(toast.error).toHaveBeenCalledWith('Network failure')
    })

    it('shows a default message when error has no message', () => {
      const result = useAdminMutation({
        mutationFn: vi.fn(),
      }) as Record<string, (error: Error) => void>

      result.onError(new Error(''))

      expect(toast.error).toHaveBeenCalledWith('Une erreur est survenue')
    })
  })
})
