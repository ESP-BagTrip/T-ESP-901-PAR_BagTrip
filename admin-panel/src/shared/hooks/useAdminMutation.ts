'use client'

import { useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'

interface UseAdminMutationOptions<TVariables, TData = unknown> {
  mutationFn: (variables: TVariables) => Promise<TData>
  /** Query keys to invalidate on success. */
  invalidateKeys?: readonly (readonly unknown[])[]
  /** Toast message on success. */
  successMessage?: string
  /** Called after successful mutation + invalidation. */
  onSuccess?: (data: TData) => void
}

/**
 * Generic admin mutation hook: calls mutationFn, toasts, invalidates.
 * Wraps useMutation with opinionated defaults for the backoffice.
 */
export function useAdminMutation<TVariables, TData = unknown>({
  mutationFn,
  invalidateKeys = [],
  successMessage,
  onSuccess,
}: UseAdminMutationOptions<TVariables, TData>) {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn,
    onSuccess: async data => {
      // Invalidate all related queries
      await Promise.all(
        invalidateKeys.map(key => queryClient.invalidateQueries({ queryKey: [...key] }))
      )
      if (successMessage) {
        toast.success(successMessage)
      }
      onSuccess?.(data)
    },
    onError: (error: Error) => {
      toast.error(error.message || 'Une erreur est survenue')
    },
  })
}
