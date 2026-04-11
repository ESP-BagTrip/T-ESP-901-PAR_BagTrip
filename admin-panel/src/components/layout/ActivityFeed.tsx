'use client'

import { Activity } from 'lucide-react'

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { EmptyState } from '@/components/ui/empty-state'
import { formatRelativeTime } from '@/utils/format'
import type { ActivityLog } from '@/types'

interface ActivityFeedProps {
  items: ActivityLog[]
  isLoading?: boolean
}

export function ActivityFeed({ items, isLoading }: ActivityFeedProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Activité récente</CardTitle>
        <CardDescription>Derniers événements sur la plateforme.</CardDescription>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="space-y-4">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="flex items-start gap-3">
                <Skeleton className="size-8 shrink-0 rounded-full" />
                <div className="flex-1 space-y-2">
                  <Skeleton className="h-3 w-64" />
                  <Skeleton className="h-3 w-24" />
                </div>
              </div>
            ))}
          </div>
        ) : items.length === 0 ? (
          <EmptyState
            icon={Activity}
            title="Aucune activité récente"
            description="Les événements apparaîtront ici dès qu'ils seront enregistrés."
          />
        ) : (
          <ul className="space-y-4">
            {items.map(event => (
              <li key={event.id} className="flex items-start gap-3">
                <div
                  aria-hidden="true"
                  className="mt-0.5 flex size-8 shrink-0 items-center justify-center rounded-full bg-muted text-muted-foreground"
                >
                  <Activity className="size-3.5" />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm text-foreground">
                    <span className="font-medium">
                      {event.user?.email ?? event.userId ?? 'Utilisateur'}
                    </span>{' '}
                    <span className="text-muted-foreground">
                      {event.action} {event.resource}
                    </span>
                  </p>
                  <p className="text-xs text-muted-foreground">{safeRelative(event.timestamp)}</p>
                </div>
              </li>
            ))}
          </ul>
        )}
      </CardContent>
    </Card>
  )
}

function safeRelative(ts: string | null | undefined): string {
  if (!ts) return '—'
  try {
    return formatRelativeTime(ts)
  } catch {
    return '—'
  }
}
