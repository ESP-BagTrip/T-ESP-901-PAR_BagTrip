'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/hooks'

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const { user, isLoading, isAuthenticated, isAdmin, logout } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (isLoading) return

    // Not authenticated → bounce to login (the middleware also covers this,
    // but the cookie it inspects can drift from the React Query cache).
    if (!isAuthenticated) {
      router.replace('/login')
      return
    }

    // Authenticated but not an admin → revoke the session and send them out.
    if (!isAdmin) {
      logout()
    }
  }, [isLoading, isAuthenticated, isAdmin, logout, router])

  // Block rendering until we know the user is an admin. This prevents
  // non-admin users from briefly seeing the (empty) admin pages.
  if (isLoading || !user || !isAdmin) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    )
  }

  return <>{children}</>
}
