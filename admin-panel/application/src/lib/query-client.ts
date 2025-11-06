import { QueryClient } from '@tanstack/react-query'

export const queryClient = new QueryClient({
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
