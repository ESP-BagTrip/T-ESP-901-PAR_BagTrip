import { cn } from '@/lib/utils'

interface PageHeaderProps {
  title: string
  description?: string
  actions?: React.ReactNode
  className?: string
}

/**
 * Standard page header: Title-2 (24/32/600) + description (small/muted) + actions slot.
 * Ive discipline — breathing room, left-aligned, no decoration.
 */
export function PageHeader({ title, description, actions, className }: PageHeaderProps) {
  return (
    <header
      className={cn(
        'flex flex-col gap-1 pb-6 sm:flex-row sm:items-start sm:justify-between sm:gap-6',
        className
      )}
    >
      <div className="min-w-0 space-y-1">
        <h1 className="text-2xl font-semibold leading-8 tracking-tight text-foreground">{title}</h1>
        {description && <p className="text-sm text-muted-foreground">{description}</p>}
      </div>
      {actions && <div className="flex shrink-0 items-center gap-2">{actions}</div>}
    </header>
  )
}
