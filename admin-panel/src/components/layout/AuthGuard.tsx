'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { Loader2 } from 'lucide-react'

import { useAuth } from '@/hooks'

/**
 * Client-side auth guard for the `/app/*` area.
 * Mirrors the server middleware check but also validates `isAdmin`
 * against the React Query cache (cookie and cache can drift).
 */
export function AuthGuard({ children }: { children: React.ReactNode }) {
  const { user, isLoading, isAuthenticated, isAdmin, logout } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (isLoading) return

    if (!isAuthenticated) {
      router.replace('/login')
      return
    }

    if (!isAdmin) {
      logout()
    }
  }, [isLoading, isAuthenticated, isAdmin, logout, router])

  if (isLoading || !user || !isAdmin) {
    return (
      <div
        role="status"
        aria-live="polite"
        className="flex min-h-screen items-center justify-center bg-background"
      >
        <Loader2 className="size-6 animate-spin text-muted-foreground" />
        <span className="sr-only">Chargement…</span>
      </div>
    )
  }

  return <>{children}</>
}
