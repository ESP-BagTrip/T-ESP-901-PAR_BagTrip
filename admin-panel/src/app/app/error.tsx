'use client'

import { AlertTriangle } from 'lucide-react'

import { EmptyState } from '@/components/ui/empty-state'

export default function AppError({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div className="py-12">
      <EmptyState
        icon={AlertTriangle}
        title="Une erreur est survenue"
        description={error.message || 'Quelque chose s’est mal passé. Réessaie dans un instant.'}
        action={{ label: 'Réessayer', onClick: reset }}
      />
    </div>
  )
}
