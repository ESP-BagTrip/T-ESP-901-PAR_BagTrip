'use client'

import { AlertTriangle } from 'lucide-react'
import { EmptyState } from '@/components/ui/empty-state'

export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div className="py-12">
      <EmptyState
        icon={AlertTriangle}
        title="Impossible de charger cette section"
        description={error.message || 'Une erreur est survenue.'}
        action={{ label: 'Réessayer', onClick: reset }}
      />
    </div>
  )
}
