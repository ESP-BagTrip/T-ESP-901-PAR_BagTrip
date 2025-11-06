import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useRouter } from 'next/navigation'
import { setCookie, deleteCookie, getCookie } from 'cookies-next'
import { authService } from '@/services'
import type { LoginCredentials } from '@/types'

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
      setCookie('auth-token', data.token, {
        httpOnly: false,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax',
        maxAge: 60 * 60 * 24 * 7,
      })

      setCookie('refresh-token', data.refreshToken, {
        httpOnly: false,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax',
        maxAge: 60 * 60 * 24 * 30,
      })

      queryClient.setQueryData(QUERY_KEYS.currentUser, data.user)
      router.push('/dashboard')
    },
  })

  const logoutMutation = useMutation({
    mutationFn: authService.logout,
    onSuccess: () => {
      deleteCookie('auth-token')
      deleteCookie('refresh-token')
      queryClient.clear()
      router.push('/login')
    },
  })

  const login = (credentials: LoginCredentials) => {
    loginMutation.mutate(credentials)
  }

  const logout = () => {
    logoutMutation.mutate()
  }

  return {
    user,
    isLoading,
    isAuthenticated: !!user,
    error,
    login,
    logout,
    isLoggingIn: loginMutation.isPending,
    isLoggingOut: logoutMutation.isPending,
    loginError: loginMutation.error,
  }
}
