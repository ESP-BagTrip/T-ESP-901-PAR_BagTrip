'use client'

import { LogOut } from 'lucide-react'

import { useAuth } from '@/hooks'
import { Button } from '@/components/ui/button'
import { Tooltip, TooltipContent, TooltipTrigger } from '@/components/ui/tooltip'
import { Separator } from '@/components/ui/separator'
import { UserPill } from './UserPill'
import { ThemeToggle } from './ThemeToggle'

interface SidebarFooterProps {
  collapsed: boolean
}

export function SidebarFooter({ collapsed }: SidebarFooterProps) {
  const { user, logout } = useAuth()

  if (!user) return null

  return (
    <div className="mt-auto border-t border-sidebar-border px-3 py-3">
      <UserPill user={user} collapsed={collapsed} />
      <Separator className="my-2" />
      <div
        className={
          collapsed ? 'flex flex-col items-center gap-1' : 'flex items-center justify-between gap-1'
        }
      >
        <ThemeToggle />
        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant="ghost"
              size="icon-sm"
              onClick={logout}
              aria-label="Se déconnecter"
              className="text-muted-foreground hover:text-destructive"
            >
              <LogOut className="size-4" />
            </Button>
          </TooltipTrigger>
          <TooltipContent side={collapsed ? 'right' : 'top'}>Déconnexion</TooltipContent>
        </Tooltip>
      </div>
    </div>
  )
}
