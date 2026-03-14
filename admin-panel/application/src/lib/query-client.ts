import { QueryClient, MutationCache } from '@tanstack/react-query'
import { toast } from 'sonner'

export const queryClient = new QueryClient({
  mutationCache: new MutationCache({
    onError: (error: unknown) => {
      const axiosError = error as { response?: { data?: { detail?: string } } }
      const message = axiosError?.response?.data?.detail || 'Une erreur est survenue'
      toast.error(message)
    },
  }),
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5,
      gcTime: 1000 * 60 * 10,
      retry: (failureCount, error: unknown) => {
        const axiosError = error as { response?: { status?: number } }
        if (axiosError?.response?.status === 401 || axiosError?.response?.status === 403) {
          return false
        }
        return failureCount < 3
      },
    },
    mutations: {
      retry: (failureCount, error: unknown) => {
        const axiosError = error as { response?: { status?: number } }
        if (
          axiosError?.response?.status &&
          axiosError.response.status >= 400 &&
          axiosError.response.status < 500
        ) {
          return false
        }
        return failureCount < 3
      },
    },
  },
})
