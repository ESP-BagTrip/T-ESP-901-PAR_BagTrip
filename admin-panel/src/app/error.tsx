'use client'

import { Button } from '@/components/ui/button'

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="w-full max-w-md space-y-4 text-center">
        <h2 className="text-2xl font-bold text-foreground">Une erreur est survenue</h2>
        <p className="text-sm text-muted-foreground">{error.message || 'Erreur inattendue.'}</p>
        <Button onClick={reset}>Réessayer</Button>
      </div>
    </div>
  )
}
