'use client'

import { CalendarDays } from 'lucide-react'

import { RANGE_PRESETS, useDateRange } from '@/hooks/useDateRange'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'

/**
 * Minimal date range picker: presets only (7d / 30d / 90d / 1y).
 * Custom calendar range can be added later — Ive discipline = don't add until needed.
 */
export function DateRangePicker() {
  const { preset, label, setRange } = useDateRange()

  return (
    <Popover>
      <PopoverTrigger asChild>
        <Button variant="outline" size="sm" className="gap-2 font-normal">
          <CalendarDays className="size-4" aria-hidden="true" />
          <span>{label}</span>
        </Button>
      </PopoverTrigger>
      <PopoverContent align="end" className="w-56 p-2">
        <p className="px-2 pb-2 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
          Période
        </p>
        <div className="flex flex-col gap-0.5">
          {RANGE_PRESETS.map(p => (
            <button
              key={p.value}
              type="button"
              onClick={() => setRange(p.value)}
              className={cn(
                'flex items-center justify-between rounded-sm px-2 py-1.5 text-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
                preset === p.value
                  ? 'bg-accent text-accent-foreground'
                  : 'text-foreground hover:bg-accent'
              )}
            >
              <span>
                {p.label === '7j'
                  ? '7 derniers jours'
                  : p.label === '30j'
                    ? '30 derniers jours'
                    : p.label === '90j'
                      ? '90 derniers jours'
                      : '12 derniers mois'}
              </span>
              {preset === p.value && (
                <span aria-hidden="true" className="text-muted-foreground">
                  •
                </span>
              )}
            </button>
          ))}
        </div>
      </PopoverContent>
    </Popover>
  )
}
