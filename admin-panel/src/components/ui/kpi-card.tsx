import Link from 'next/link'
import { ArrowDownRight, ArrowUpRight, Minus } from 'lucide-react'

import { cn } from '@/lib/utils'
import { Sparkline } from '@/components/ui/sparkline'
import { Skeleton } from '@/components/ui/skeleton'

interface KPICardProps {
  label: string
  value: string
  /** Percentage delta vs previous period. Null hides the delta badge. */
  delta?: number | null
  /** Raw points for the sparkline. */
  trend?: number[]
  /** Tone controls the sparkline color (currentColor). */
  tone?: 'primary' | 'success' | 'warning' | 'danger' | 'muted'
  /** Link target — if set, the whole card becomes a drill-down. */
  href?: string
  /** Text shown next to the delta (e.g. "vs période précédente"). */
  deltaLabel?: string
  isLoading?: boolean
}

const TONE_CLASS: Record<NonNullable<KPICardProps['tone']>, string> = {
  primary: 'text-primary',
  success: 'text-success',
  warning: 'text-warning',
  danger: 'text-destructive',
  muted: 'text-muted-foreground',
}

export function KPICard({
  label,
  value,
  delta,
  trend,
  tone = 'primary',
  href,
  deltaLabel = 'vs période précédente',
  isLoading,
}: KPICardProps) {
  const content = (
    <div
      className={cn(
        'group relative flex h-full flex-col justify-between gap-4 rounded-md border border-border bg-card p-6 shadow-xs transition-colors',
        href && 'hover:border-border/80 hover:shadow-sm'
      )}
    >
      <div className="flex items-start justify-between gap-3">
        <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
          {label}
        </span>
        {trend && trend.length > 0 && <Sparkline data={trend} className={TONE_CLASS[tone]} />}
      </div>
      {isLoading ? (
        <Skeleton className="h-9 w-32" />
      ) : (
        <p className="text-[32px] font-bold leading-10 tracking-tight tabular-nums text-foreground">
          {value}
        </p>
      )}
      <DeltaRow delta={delta} label={deltaLabel} />
    </div>
  )

  if (!href) return content
  return (
    <Link
      href={href}
      className="focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background rounded-md"
    >
      {content}
    </Link>
  )
}

function DeltaRow({ delta, label }: { delta: number | null | undefined; label: string }) {
  if (delta == null) {
    return (
      <p className="text-xs text-muted-foreground">
        <Minus className="mr-1 inline size-3 align-text-bottom" />— {label}
      </p>
    )
  }
  const up = delta > 0
  const flat = delta === 0
  const Icon = flat ? Minus : up ? ArrowUpRight : ArrowDownRight
  const tone = flat ? 'text-muted-foreground' : up ? 'text-success' : 'text-destructive'
  const sign = flat ? '' : up ? '+' : ''
  return (
    <p className="flex items-center gap-1 text-xs">
      <span className={cn('flex items-center gap-0.5 font-medium tabular-nums', tone)}>
        <Icon className="size-3" />
        {sign}
        {delta.toFixed(1)}%
      </span>
      <span className="text-muted-foreground">{label}</span>
    </p>
  )
}
