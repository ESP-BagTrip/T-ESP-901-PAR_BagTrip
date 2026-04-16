'use client'

import { useTheme } from 'next-themes'
import { LogOut, Monitor, Moon, Sun } from 'lucide-react'

import { PageHeader } from '@/components/layout/PageHeader'
import { useAuth } from '@/hooks'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group'

export default function SettingsPage() {
  const { user, logout } = useAuth()
  const { theme, setTheme } = useTheme()

  return (
    <div className="max-w-3xl space-y-6">
      <PageHeader title="Paramètres" description="Profil, apparence et session." />

      {/* Profile */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Profil</CardTitle>
          <CardDescription>Informations liées à votre compte administrateur.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label className="text-xs uppercase tracking-wider text-muted-foreground">
                Email
              </Label>
              <p className="text-sm font-medium text-foreground">{user?.email ?? '—'}</p>
            </div>
            <div className="space-y-1.5">
              <Label className="text-xs uppercase tracking-wider text-muted-foreground">Plan</Label>
              <div>
                <Badge variant="outline" className="text-xs">
                  {user?.plan ?? '—'}
                </Badge>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Appearance */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Apparence</CardTitle>
          <CardDescription>Choisissez le thème utilisé par l&apos;interface admin.</CardDescription>
        </CardHeader>
        <CardContent>
          <RadioGroup
            value={theme ?? 'system'}
            onValueChange={setTheme}
            className="grid grid-cols-1 gap-3 sm:grid-cols-3"
          >
            <ThemeOption value="light" icon={Sun} label="Clair" />
            <ThemeOption value="dark" icon={Moon} label="Sombre" />
            <ThemeOption value="system" icon={Monitor} label="Système" />
          </RadioGroup>
        </CardContent>
      </Card>

      {/* Plans & Quotas */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Plans &amp; Quotas IA</CardTitle>
          <CardDescription>
            Limites IA par plan. Modifiable via l&apos;API config (endpoint à créer).
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <PlanCard name="FREE" aiLimit={3} viewersLimit={2} />
            <PlanCard name="PREMIUM" aiLimit="Illimité" viewersLimit={10} />
            <PlanCard name="ADMIN" aiLimit="Illimité" viewersLimit="Illimité" />
          </div>
          <p className="mt-3 text-xs text-muted-foreground">
            Ces valeurs sont actuellement définies dans le code (api/src/config/plans.py). Un
            endpoint PATCH /admin/config sera ajouté pour les rendre éditables.
          </p>
        </CardContent>
      </Card>

      {/* Feature Flags */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Feature Flags</CardTitle>
          <CardDescription>
            Activer / désactiver des fonctionnalités de l&apos;application.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="rounded-md border border-dashed border-border p-8 text-center">
            <p className="text-sm text-muted-foreground">
              Le système de feature flags sera disponible quand la table app_config et les endpoints
              GET/PATCH /admin/config seront créés côté API (Migration 0028).
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Session */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Session</CardTitle>
          <CardDescription>Déconnectez-vous de la console admin.</CardDescription>
        </CardHeader>
        <CardContent>
          <Separator className="mb-4" />
          <Button variant="destructive" onClick={logout}>
            <LogOut className="size-4" />
            Se déconnecter
          </Button>
        </CardContent>
      </Card>
    </div>
  )
}

function PlanCard({
  name,
  aiLimit,
  viewersLimit,
}: {
  name: string
  aiLimit: number | string
  viewersLimit: number | string
}) {
  return (
    <div className="rounded-md border border-border bg-background p-4 space-y-2">
      <Badge variant="outline" className="text-xs">
        {name}
      </Badge>
      <div className="space-y-1 text-sm">
        <div className="flex justify-between">
          <span className="text-muted-foreground">Générations IA</span>
          <span className="font-medium tabular-nums">{aiLimit}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-muted-foreground">Viewers / trip</span>
          <span className="font-medium tabular-nums">{viewersLimit}</span>
        </div>
      </div>
    </div>
  )
}

function ThemeOption({
  value,
  icon: Icon,
  label,
}: {
  value: string
  icon: typeof Sun
  label: string
}) {
  return (
    <Label
      htmlFor={`theme-${value}`}
      className="flex cursor-pointer items-center gap-3 rounded-md border border-border bg-card p-4 transition-colors has-[[data-state=checked]]:border-primary has-[[data-state=checked]]:bg-primary-subtle"
    >
      <RadioGroupItem id={`theme-${value}`} value={value} />
      <Icon className="size-4 text-muted-foreground" />
      <span className="text-sm font-medium text-foreground">{label}</span>
    </Label>
  )
}
