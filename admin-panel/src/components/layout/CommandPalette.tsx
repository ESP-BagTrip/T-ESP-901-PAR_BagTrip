'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useTheme } from 'next-themes'
import { LogOut, Monitor, Moon, Sun } from 'lucide-react'

import {
  CommandDialog,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
  CommandSeparator,
} from '@/components/ui/command'
import { NAV_SECTIONS, SECONDARY_NAV } from '@/config/navigation'
import { useAuth } from '@/hooks'

interface CommandPaletteProps {
  open: boolean
  onOpenChange: (open: boolean) => void
}

export function CommandPalette({ open, onOpenChange }: CommandPaletteProps) {
  const router = useRouter()
  const { setTheme } = useTheme()
  const { logout } = useAuth()

  // ⌘K / Ctrl+K shortcut
  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'k' && (e.metaKey || e.ctrlKey)) {
        e.preventDefault()
        onOpenChange(!open)
      }
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [open, onOpenChange])

  const run = (fn: () => void) => {
    onOpenChange(false)
    fn()
  }

  return (
    <CommandDialog
      open={open}
      onOpenChange={onOpenChange}
      title="Rechercher"
      description="Navigation et actions rapides"
    >
      <CommandInput placeholder="Tapez une commande ou recherchez…" />
      <CommandList>
        <CommandEmpty>Aucun résultat.</CommandEmpty>
        {NAV_SECTIONS.map(section => (
          <CommandGroup key={section.label} heading={section.label}>
            {section.items.map(item => {
              const Icon = item.icon
              return (
                <CommandItem
                  key={item.href}
                  value={`${item.label} ${(item.keywords ?? []).join(' ')}`}
                  onSelect={() => run(() => router.push(item.href))}
                >
                  <Icon className="size-4" />
                  <span>{item.label}</span>
                </CommandItem>
              )
            })}
          </CommandGroup>
        ))}

        <CommandSeparator />

        <CommandGroup heading="Système">
          {SECONDARY_NAV.map(item => {
            const Icon = item.icon
            return (
              <CommandItem
                key={item.href}
                value={`${item.label} ${(item.keywords ?? []).join(' ')}`}
                onSelect={() => run(() => router.push(item.href))}
              >
                <Icon className="size-4" />
                <span>{item.label}</span>
              </CommandItem>
            )
          })}
        </CommandGroup>

        <CommandSeparator />

        <CommandGroup heading="Actions">
          <CommandItem value="theme light clair" onSelect={() => run(() => setTheme('light'))}>
            <Sun className="size-4" /> Thème clair
          </CommandItem>
          <CommandItem value="theme dark sombre" onSelect={() => run(() => setTheme('dark'))}>
            <Moon className="size-4" /> Thème sombre
          </CommandItem>
          <CommandItem value="theme system" onSelect={() => run(() => setTheme('system'))}>
            <Monitor className="size-4" /> Thème système
          </CommandItem>
          <CommandItem value="logout deconnexion" onSelect={() => run(logout)}>
            <LogOut className="size-4" /> Se déconnecter
          </CommandItem>
        </CommandGroup>
      </CommandList>
    </CommandDialog>
  )
}
