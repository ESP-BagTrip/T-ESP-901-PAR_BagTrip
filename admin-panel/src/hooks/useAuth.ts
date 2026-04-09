import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useRouter } from 'next/navigation'
import { authService } from '@/services'
import type { LoginCredentials, User } from '@/types'

const QUERY_KEYS = {
  currentUser: ['auth', 'currentUser'],
}

function hasAuthCookie(): boolean {
  if (typeof document === 'undefined') return false
  return document.cookie.includes('auth-status=authenticated')
}

const isAdminUser = (user: User | null | undefined): boolean => user?.plan === 'ADMIN'

export class NotAdminError extends Error {
  constructor() {
    super('Accès réservé aux administrateurs.')
    this.name = 'NotAdminError'
  }
}

export const useAuth = () => {
  const queryClient = useQueryClient()
  const router = useRouter()

  const {
    data: user,
    isLoading,
    error,
  } = useQuery({
    queryKey: QUERY_KEYS.currentUser,
    queryFn: authService.getCurrentUser,
    enabled: hasAuthCookie(),
    retry: false,
  })

  const loginMutation = useMutation({
    mutationFn: async (credentials: LoginCredentials) => {
      const data = await authService.login(credentials)
      if (!isAdminUser(data.user)) {
        // Revoke the session that the API just opened for a non-admin user.
        try {
          await authService.logout()
        } catch {
          // Ignore — we still want to surface the access error below.
        }
        queryClient.removeQueries({ queryKey: QUERY_KEYS.currentUser })
        throw new NotAdminError()
      }
      return data
    },
    onSuccess: data => {
      queryClient.setQueryData(QUERY_KEYS.currentUser, data.user)
      router.push('/app')
    },
  })

  const logout = async () => {
    try {
      await authService.logout()
    } catch {
      // Ignore errors on logout
    }
    queryClient.clear()
    router.push('/login')
  }

  const login = (credentials: LoginCredentials) => {
    loginMutation.mutate(credentials)
  }

  return {
    user,
    isLoading,
    isAuthenticated: !!user,
    isAdmin: isAdminUser(user),
    error,
    login,
    logout,
    isLoggingIn: loginMutation.isPending,
    loginError: loginMutation.error,
  }
}
