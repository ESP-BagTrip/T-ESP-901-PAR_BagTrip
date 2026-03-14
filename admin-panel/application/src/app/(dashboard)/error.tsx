'use client'

import { Button } from '@/components/ui/button'

export default function DashboardError({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full text-center space-y-4">
        <h2 className="text-2xl font-bold text-gray-900">Erreur du tableau de bord</h2>
        <p className="text-sm text-gray-600">{error.message || 'Impossible de charger le tableau de bord.'}</p>
        <Button onClick={reset}>Réessayer</Button>
      </div>
    </div>
  )
}
