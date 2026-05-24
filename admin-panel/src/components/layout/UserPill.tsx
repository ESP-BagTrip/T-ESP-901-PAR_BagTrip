'use client'

import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { Badge } from '@/components/ui/badge'
import { Tooltip, TooltipContent, TooltipTrigger } from '@/components/ui/tooltip'
import type { User } from '@/types'

function initialsFrom(email: string): string {
  const [local] = email.split('@')
  if (!local) return '??'
  const parts = local.split(/[._-]/).filter(Boolean)
  const pick = parts.length >= 2 ? `${parts[0]![0]}${parts[1]![0]}` : local.slice(0, 2)
  return pick.toUpperCase()
}

interface UserPillProps {
  user: User
  collapsed: boolean
}

export function UserPill({ user, collapsed }: UserPillProps) {
  const initials = initialsFrom(user.email)

  if (collapsed) {
    return (
      <Tooltip>
        <TooltipTrigger asChild>
          <div className="flex justify-center">
            <Avatar className="size-8">
              <AvatarFallback className="text-xs">{initials}</AvatarFallback>
            </Avatar>
          </div>
        </TooltipTrigger>
        <TooltipContent side="right">
          <div className="flex flex-col gap-1">
            <span className="font-medium">{user.email}</span>
            <span className="text-xs uppercase text-muted-foreground">{user.plan}</span>
          </div>
        </TooltipContent>
      </Tooltip>
    )
  }

  return (
    <div className="flex items-center gap-2 px-1">
      <Avatar className="size-8 shrink-0">
        <AvatarFallback className="text-xs">{initials}</AvatarFallback>
      </Avatar>
      <div className="min-w-0 flex-1">
        <p className="truncate text-xs font-medium text-sidebar-foreground">{user.email}</p>
        <Badge variant="outline" className="mt-0.5 h-4 px-1 text-[10px] font-medium">
          {user.plan}
        </Badge>
      </div>
    </div>
  )
}
