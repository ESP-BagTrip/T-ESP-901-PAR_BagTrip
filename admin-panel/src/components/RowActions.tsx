'use client'

import { MoreHorizontal, type LucideIcon } from 'lucide-react'

import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { cn } from '@/lib/utils'

export interface RowAction {
  label: string
  icon?: LucideIcon
  onClick: () => void
  variant?: 'default' | 'destructive'
  /** When true, a separator is added before this item. */
  separator?: boolean
}

interface RowActionsProps {
  actions: RowAction[]
}

/**
 * Generic row-level actions dropdown (MoreHorizontal trigger).
 * Used as the last column in every actionable DataTable.
 */
export function RowActions({ actions }: RowActionsProps) {
  if (actions.length === 0) return null

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          size="icon-xs"
          className="text-muted-foreground"
          aria-label="Actions"
        >
          <MoreHorizontal className="size-4" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-48">
        {actions.map((action, i) => (
          <span key={action.label}>
            {action.separator && i > 0 && <DropdownMenuSeparator />}
            <DropdownMenuItem
              onClick={action.onClick}
              className={cn(
                action.variant === 'destructive' && 'text-destructive focus:text-destructive'
              )}
            >
              {action.icon && <action.icon className="size-4" />}
              {action.label}
            </DropdownMenuItem>
          </span>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
