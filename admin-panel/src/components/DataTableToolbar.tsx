'use client'

import { Search, X } from 'lucide-react'

import { Input } from '@/components/ui/input'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'

export interface FilterConfig {
  key: string
  label: string
  options: { value: string; label: string }[]
}

interface DataTableToolbarProps {
  /** Search input value (controlled). */
  searchValue?: string
  /** Called on every keystroke — debounce is handled by the caller. */
  onSearch?: (value: string) => void
  searchPlaceholder?: string
  /** Filter select configurations. */
  filters?: FilterConfig[]
  /** Currently active filter values. */
  activeFilters?: Record<string, string | undefined>
  /** Called when a filter changes. `value` is undefined to clear. */
  onFilterChange?: (key: string, value: string | undefined) => void
  /** Called to reset all filters and search. */
  onReset?: () => void
  /** Right-side slot: Export buttons, Create button, etc. */
  actions?: React.ReactNode
  /** Appears when rows are selected. Replaces the regular toolbar content. */
  bulkActions?: React.ReactNode
  /** Number of selected rows. */
  selectedCount?: number
  className?: string
}

export function DataTableToolbar({
  searchValue,
  onSearch,
  searchPlaceholder = 'Rechercher…',
  filters,
  activeFilters,
  onFilterChange,
  onReset,
  actions,
  bulkActions,
  selectedCount = 0,
  className,
}: DataTableToolbarProps) {
  const hasActiveFilters =
    (searchValue && searchValue.length > 0) ||
    Object.values(activeFilters ?? {}).some(v => v != null && v !== '')

  // Bulk mode: show selected count + bulk actions
  if (selectedCount > 0 && bulkActions) {
    return (
      <div
        className={cn(
          'mb-4 flex items-center justify-between gap-4 rounded-md border border-primary/20 bg-primary-subtle px-4 py-3',
          className
        )}
      >
        <p className="text-sm font-medium text-foreground">
          {selectedCount} élément{selectedCount > 1 ? 's' : ''} sélectionné
          {selectedCount > 1 ? 's' : ''}
        </p>
        <div className="flex items-center gap-2">{bulkActions}</div>
      </div>
    )
  }

  return (
    <div className={cn('mb-4 flex flex-wrap items-center gap-3', className)}>
      {/* Search */}
      {onSearch && (
        <div className="relative w-full max-w-xs">
          <Search className="absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            value={searchValue ?? ''}
            onChange={e => onSearch(e.target.value)}
            placeholder={searchPlaceholder}
            className="pl-9"
          />
        </div>
      )}

      {/* Filters */}
      {filters?.map(filter => (
        <Select
          key={filter.key}
          value={activeFilters?.[filter.key] ?? ''}
          onValueChange={v => onFilterChange?.(filter.key, v === '' ? undefined : v)}
        >
          <SelectTrigger className="w-[160px]">
            <SelectValue placeholder={filter.label} />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="">Tous</SelectItem>
            {filter.options.map(opt => (
              <SelectItem key={opt.value} value={opt.value}>
                {opt.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      ))}

      {/* Reset */}
      {hasActiveFilters && onReset && (
        <Button
          variant="ghost"
          size="sm"
          onClick={onReset}
          className="gap-1.5 text-muted-foreground"
        >
          <X className="size-3.5" />
          Réinitialiser
        </Button>
      )}

      {/* Right-side actions */}
      {actions && <div className="ml-auto flex items-center gap-2">{actions}</div>}
    </div>
  )
}
