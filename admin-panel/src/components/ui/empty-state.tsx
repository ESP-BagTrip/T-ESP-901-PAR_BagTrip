import * as React from 'react'
import type { LucideIcon } from 'lucide-react'

import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'

export interface EmptyStateAction {
  label: string
  onClick?: () => void
  href?: string
}

export interface EmptyStateProps extends React.HTMLAttributes<HTMLDivElement> {
  icon?: LucideIcon
  title: string
  description?: string
  action?: EmptyStateAction
}

/**
 * Ive-style empty state: icône dans un halo discret, titre, description,
 * CTA optionnel. Utilisé dans error.tsx, pages sans données, états filtrés.
 */
export function EmptyState({
  icon: Icon,
  title,
  description,
  action,
  className,
  ...props
}: EmptyStateProps) {
  return (
    <div
      role="status"
      className={cn(
        'flex flex-col items-center justify-center gap-4 rounded-md border border-dashed border-border bg-card px-6 py-16 text-center',
        className
      )}
      {...props}
    >
      {Icon && (
        <div
          aria-hidden="true"
          className="flex size-12 items-center justify-center rounded-full bg-muted text-muted-foreground"
        >
          <Icon className="size-5" />
        </div>
      )}
      <div className="space-y-1">
        <p className="text-base font-semibold text-foreground">{title}</p>
        {description && <p className="max-w-md text-sm text-muted-foreground">{description}</p>}
      </div>
      {action && (
        <div>
          {action.href ? (
            <Button asChild variant="outline" size="sm">
              <a href={action.href}>{action.label}</a>
            </Button>
          ) : (
            <Button variant="outline" size="sm" onClick={action.onClick}>
              {action.label}
            </Button>
          )}
        </div>
      )}
    </div>
  )
}
