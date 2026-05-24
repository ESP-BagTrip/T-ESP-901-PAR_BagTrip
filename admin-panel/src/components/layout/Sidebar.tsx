'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { ChevronsLeft, ChevronsRight, Search } from 'lucide-react'

import { cn } from '@/lib/utils'
import { useUIStore } from '@/stores/useUIStore'
import { NAV_SECTIONS, SECONDARY_NAV, type NavItem } from '@/config/navigation'
import { Tooltip, TooltipContent, TooltipTrigger } from '@/components/ui/tooltip'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Button } from '@/components/ui/button'
import { Kbd } from '@/components/ui/kbd'
import { SidebarFooter } from './SidebarFooter'

function isItemActive(pathname: string, href: string): boolean {
  if (href === '/app') return pathname === '/app'
  return pathname === href || pathname.startsWith(`${href}/`)
}

interface SidebarProps {
  onOpenCommandPalette: () => void
}

export function Sidebar({ onOpenCommandPalette }: SidebarProps) {
  const pathname = usePathname()
  const collapsed = useUIStore(s => s.sidebarCollapsed)
  const toggleCollapsed = useUIStore(s => s.toggleSidebarCollapsed)

  return (
    <aside
      aria-label="Navigation principale"
      data-collapsed={collapsed}
      className={cn(
        'fixed left-0 top-0 z-40 hidden h-screen flex-col border-r border-sidebar-border bg-sidebar text-sidebar-foreground transition-[width] duration-200 ease-out lg:flex',
        collapsed ? 'w-16' : 'w-60'
      )}
    >
      {/* Header */}
      <div className="flex h-14 items-center justify-between gap-2 border-b border-sidebar-border px-4">
        {!collapsed && (
          <Link
            href="/app"
            className="flex items-center gap-2 text-sm font-semibold tracking-tight"
          >
            <span>BagTrip</span>
            <span className="rounded bg-sidebar-accent px-1.5 py-0.5 font-mono text-[10px] uppercase tracking-wider text-muted-foreground">
              Admin
            </span>
          </Link>
        )}
        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant="ghost"
              size="icon-sm"
              aria-expanded={!collapsed}
              aria-label={collapsed ? 'Déplier la sidebar' : 'Replier la sidebar'}
              onClick={toggleCollapsed}
              className="text-muted-foreground hover:text-foreground"
            >
              {collapsed ? (
                <ChevronsRight className="size-4" />
              ) : (
                <ChevronsLeft className="size-4" />
              )}
            </Button>
          </TooltipTrigger>
          <TooltipContent side="right">{collapsed ? 'Déplier' : 'Replier'}</TooltipContent>
        </Tooltip>
      </div>

      {/* Search trigger */}
      <div className="px-3 py-3">
        <Tooltip>
          <TooltipTrigger asChild>
            <button
              type="button"
              onClick={onOpenCommandPalette}
              className={cn(
                'group flex w-full items-center gap-2 rounded-md border border-sidebar-border bg-background px-2.5 text-sm text-muted-foreground shadow-xs transition-colors hover:border-border hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-sidebar',
                collapsed ? 'h-8 justify-center' : 'h-9 justify-between'
              )}
            >
              <span className="flex items-center gap-2">
                <Search className="size-4" aria-hidden="true" />
                {!collapsed && <span>Rechercher…</span>}
              </span>
              {!collapsed && (
                <span className="flex items-center gap-0.5">
                  <Kbd>⌘</Kbd>
                  <Kbd>K</Kbd>
                </span>
              )}
            </button>
          </TooltipTrigger>
          {collapsed && <TooltipContent side="right">Rechercher (⌘K)</TooltipContent>}
        </Tooltip>
      </div>

      {/* Nav */}
      <ScrollArea className="flex-1">
        <nav aria-label="Primary" className="space-y-5 px-3 pb-6">
          {NAV_SECTIONS.map(section => (
            <div key={section.label} role="group" aria-label={section.label}>
              {!collapsed && (
                <p className="mb-1 px-2 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">
                  {section.label}
                </p>
              )}
              <ul className="space-y-0.5">
                {section.items.map(item => (
                  <SidebarItem
                    key={item.href}
                    item={item}
                    active={isItemActive(pathname ?? '', item.href)}
                    collapsed={collapsed}
                  />
                ))}
              </ul>
            </div>
          ))}

          <div>
            {!collapsed && (
              <p className="mb-1 px-2 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">
                Système
              </p>
            )}
            <ul className="space-y-0.5">
              {SECONDARY_NAV.map(item => (
                <SidebarItem
                  key={item.href}
                  item={item}
                  active={isItemActive(pathname ?? '', item.href)}
                  collapsed={collapsed}
                />
              ))}
            </ul>
          </div>
        </nav>
      </ScrollArea>

      <SidebarFooter collapsed={collapsed} />
    </aside>
  )
}

function SidebarItem({
  item,
  active,
  collapsed,
}: {
  item: NavItem
  active: boolean
  collapsed: boolean
}) {
  const Icon = item.icon
  const link = (
    <Link
      href={item.href}
      aria-current={active ? 'page' : undefined}
      className={cn(
        'group flex items-center gap-2.5 rounded-md px-2.5 py-1.5 text-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-sidebar',
        active
          ? 'bg-sidebar-accent font-medium text-sidebar-accent-foreground'
          : 'text-muted-foreground hover:bg-sidebar-accent/60 hover:text-sidebar-foreground',
        collapsed && 'justify-center px-0'
      )}
    >
      <Icon className="size-4 shrink-0" aria-hidden="true" />
      {!collapsed && <span className="truncate">{item.label}</span>}
      {collapsed && <span className="sr-only">{item.label}</span>}
    </Link>
  )

  if (!collapsed) return <li>{link}</li>

  return (
    <li>
      <Tooltip>
        <TooltipTrigger asChild>{link}</TooltipTrigger>
        <TooltipContent side="right">{item.label}</TooltipContent>
      </Tooltip>
    </li>
  )
}
