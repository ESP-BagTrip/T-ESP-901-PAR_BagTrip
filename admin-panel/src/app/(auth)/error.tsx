'use client'

import { Button } from '@/components/ui/button'

export default function AuthError({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="w-full max-w-md space-y-4 text-center">
        <h2 className="text-2xl font-semibold tracking-tight text-foreground">
          Erreur d&apos;authentification
        </h2>
        <p className="text-sm text-muted-foreground">
          {error.message || 'Impossible de se connecter.'}
        </p>
        <Button onClick={reset}>Réessayer</Button>
      </div>
    </div>
  )
}
