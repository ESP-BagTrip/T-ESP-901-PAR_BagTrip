'use client'

import { Menu } from 'lucide-react'

import { Sheet, SheetContent, SheetTrigger } from '@/components/ui/sheet'
import { Button } from '@/components/ui/button'
import { Breadcrumb } from './Breadcrumb'

interface TopbarProps {
  /** Right-side slot: date range picker, notif bell, etc. */
  actions?: React.ReactNode
  /** The mobile sidebar sheet content (a simplified version of Sidebar). */
  mobileSidebar?: React.ReactNode
}

export function Topbar({ actions, mobileSidebar }: TopbarProps) {
  return (
    <header
      role="banner"
      className="sticky top-0 z-30 flex h-14 items-center gap-3 border-b border-border bg-background/80 px-4 backdrop-blur-md lg:px-8"
    >
      {/* Mobile sidebar trigger */}
      {mobileSidebar && (
        <Sheet>
          <SheetTrigger asChild>
            <Button
              variant="ghost"
              size="icon-sm"
              aria-label="Ouvrir le menu"
              className="lg:hidden"
            >
              <Menu className="size-4" />
            </Button>
          </SheetTrigger>
          <SheetContent side="left" className="w-72 p-0">
            {mobileSidebar}
          </SheetContent>
        </Sheet>
      )}

      <nav aria-label="Fil d’Ariane" className="min-w-0 flex-1">
        <Breadcrumb />
      </nav>

      {actions && <div className="flex items-center gap-2">{actions}</div>}
    </header>
  )
}
