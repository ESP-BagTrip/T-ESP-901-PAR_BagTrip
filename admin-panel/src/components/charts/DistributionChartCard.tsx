'use client'

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { cn } from '@/lib/utils'

interface DistributionChartCardProps {
  title: string
  description?: string
  data: Array<{ name: string; value: number }>
  isLoading?: boolean
}

/**
 * Horizontal bar distribution — Ive-style. No SVG, just CSS widths.
 * Ideal for small categorical counts (ratings, statuses).
 */
export function DistributionChartCard({
  title,
  description,
  data,
  isLoading,
}: DistributionChartCardProps) {
  const max = Math.max(1, ...data.map(d => d.value))

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">{title}</CardTitle>
        {description && <CardDescription>{description}</CardDescription>}
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="space-y-3">
            {Array.from({ length: 5 }).map((_, i) => (
              <Skeleton key={i} className="h-6 w-full" />
            ))}
          </div>
        ) : data.length === 0 ? (
          <p className="py-12 text-center text-sm text-muted-foreground">Aucune donnée</p>
        ) : (
          <ul className="space-y-3">
            {data.map(d => {
              const pct = (d.value / max) * 100
              return (
                <li key={d.name} className="space-y-1">
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-medium text-foreground">{d.name}</span>
                    <span className="tabular-nums text-muted-foreground">{d.value}</span>
                  </div>
                  <div className="h-1.5 overflow-hidden rounded-full bg-muted">
                    <div
                      className={cn(
                        'h-full rounded-full bg-primary transition-[width] duration-300 ease-out'
                      )}
                      style={{ width: `${pct}%` }}
                      aria-hidden="true"
                    />
                  </div>
                </li>
              )
            })}
          </ul>
        )}
      </CardContent>
    </Card>
  )
}
