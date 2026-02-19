import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useRouter } from 'next/navigation'
import { setCookie, deleteCookie, getCookie } from 'cookies-next'
import { authService } from '@/services'
import type { LoginCredentials, RegisterCredentials } from '@/types'

const QUERY_KEYS = {
  currentUser: ['auth', 'currentUser'],
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
    enabled: !!getCookie('auth-token'),
    retry: false,
  })

  const loginMutation = useMutation({
    mutationFn: authService.login,
    onSuccess: data => {
      setCookie('auth-token', data.access_token, {
        httpOnly: false,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax',
        maxAge: 60 * 60 * 24 * 365, // 365 days to match API
      })

      queryClient.setQueryData(QUERY_KEYS.currentUser, data.user)
      router.push('/dashboard')
    },
  })

  const registerMutation = useMutation({
    mutationFn: authService.register,
    onSuccess: data => {
      setCookie('auth-token', data.access_token, {
        httpOnly: false,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax',
        maxAge: 60 * 60 * 24 * 365, // 365 days to match API
      })

      queryClient.setQueryData(QUERY_KEYS.currentUser, data.user)
      router.push('/dashboard')
    },
  })

  const logout = () => {
    deleteCookie('auth-token')
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
