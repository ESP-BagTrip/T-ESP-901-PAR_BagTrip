'use client'

import { useState } from 'react'

import { cn } from '@/lib/utils'
import { useUIStore } from '@/stores/useUIStore'
import { Sidebar } from './Sidebar'
import { Topbar } from './Topbar'
import { CommandPalette } from './CommandPalette'

/**
 * Shell du dashboard admin : sidebar fixe + topbar sticky + main max-w-1440.
 * Gère aussi le state d'ouverture de la CommandPalette.
 */
export function AppShell({ children }: { children: React.ReactNode }) {
  const collapsed = useUIStore(s => s.sidebarCollapsed)
  const [paletteOpen, setPaletteOpen] = useState(false)

  return (
    <div className="min-h-screen bg-background">
      <Sidebar onOpenCommandPalette={() => setPaletteOpen(true)} />
      <CommandPalette open={paletteOpen} onOpenChange={setPaletteOpen} />

      <div
        className={cn(
          'flex min-h-screen flex-col transition-[padding-left] duration-200 ease-out',
          collapsed ? 'lg:pl-16' : 'lg:pl-60'
        )}
      >
        <Topbar />
        <main className="flex-1">
          <div className="mx-auto w-full max-w-[1440px] px-4 py-6 lg:px-8 lg:py-8">{children}</div>
        </main>
      </div>
    </div>
  )
}
