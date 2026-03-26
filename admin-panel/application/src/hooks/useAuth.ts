import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useRouter } from 'next/navigation'
import { authService } from '@/services'
import type { LoginCredentials, RegisterCredentials } from '@/types'

const QUERY_KEYS = {
  currentUser: ['auth', 'currentUser'],
}

function hasAuthCookie(): boolean {
  if (typeof document === 'undefined') return false
  return document.cookie.includes('auth-status=authenticated')
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
    mutationFn: authService.login,
    onSuccess: data => {
      queryClient.setQueryData(QUERY_KEYS.currentUser, data.user)
      router.push('/dashboard')
    },
  })

  const registerMutation = useMutation({
    mutationFn: authService.register,
    onSuccess: data => {
      queryClient.setQueryData(QUERY_KEYS.currentUser, data.user)
      router.push('/dashboard')
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

  const register = (credentials: RegisterCredentials) => {
    registerMutation.mutate(credentials)
  }

  return {
    user,
    isLoading,
    isAuthenticated: !!user,
    error,
    login,
    register,
    logout,
    isLoggingIn: loginMutation.isPending,
    isRegistering: registerMutation.isPending,
    loginError: loginMutation.error,
    registerError: registerMutation.error,
  }
}
