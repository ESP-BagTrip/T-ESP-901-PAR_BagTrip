'use client'

import { Skeleton } from '@/components/ui/skeleton'

export function TabSkeleton() {
  return (
    <div className="bg-white rounded-lg shadow overflow-hidden">
      <div className="p-4 space-y-3">
        <Skeleton className="h-10 w-full" />
        <Skeleton className="h-8 w-full" />
        <Skeleton className="h-8 w-full" />
        <Skeleton className="h-8 w-full" />
        <Skeleton className="h-8 w-full" />
        <Skeleton className="h-8 w-3/4" />
      </div>
    </div>
  )
}
