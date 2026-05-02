'use client'

import { use, useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { useQuery } from '@tanstack/react-query'
import { Archive, Trash2 } from 'lucide-react'

import { PageHeader } from '@/components/layout/PageHeader'
import { ConfirmDialog } from '@/components/ConfirmDialog'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { adminService } from '@/services'
import { safeFormatDate } from '@/utils/date'
import { formatCurrency, formatNumber } from '@/utils/format'
import { useArchiveTrip, useDeleteTrip } from '@/features/trips/mutations'
import type { AdminTripDetail } from '@/types/admin'

const STATUS_BADGE: Record<string, 'default' | 'secondary' | 'success' | 'warning'> = {
  DRAFT: 'secondary',
  PLANNED: 'default',
  ONGOING: 'warning',
  COMPLETED: 'success',
}

export default function TripDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params)
  const router = useRouter()

  const { data: trip, isLoading } = useQuery<AdminTripDetail>({
    queryKey: ['admin', 'trip-detail', id],
    queryFn: () => adminService.getTripDetail(id),
  })

  const [deleteOpen, setDeleteOpen] = useState(false)
  const deleteMutation = useDeleteTrip()
  const archiveMutation = useArchiveTrip(id)

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <Skeleton className="h-48" />
      </div>
    )
  }

  if (!trip) {
    return <div className="py-12 text-center text-muted-foreground">Voyage introuvable.</div>
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title={trip.title ?? 'Sans titre'}
        description={`${trip.destination_name ?? trip.destination_iata ?? '—'} · ${safeFormatDate(trip.start_date, 'dd/MM/yyyy')} → ${safeFormatDate(trip.end_date, 'dd/MM/yyyy')}`}
        actions={
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" asChild>
              <Link href={`/app/users/${trip.user_id}`}>Voir l&apos;utilisateur</Link>
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => archiveMutation.mutate(undefined)}
              disabled={archiveMutation.isPending || !!trip.archived_at}
            >
              <Archive className="size-4" /> {trip.archived_at ? 'Archivé' : 'Archiver'}
            </Button>
            <Button variant="destructive" size="sm" onClick={() => setDeleteOpen(true)}>
              <Trash2 className="size-4" /> Supprimer
            </Button>
          </div>
        }
      />

      {/* Info card */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Informations</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
            <Field label="Statut">
              <Badge variant={STATUS_BADGE[trip.status ?? ''] ?? 'outline'}>
                {trip.status ?? '—'}
              </Badge>
            </Field>
            <Field label="Utilisateur">
              <Link
                href={`/app/users/${trip.user_id}`}
                className="text-sm text-primary hover:underline"
              >
                {trip.user_email}
              </Link>
            </Field>
            <Field label="Budget cible" value={formatCurrency(trip.budget_target)} />
            <Field label="Estimation IA" value={formatCurrency(trip.budget_estimated)} />
            <Field label="Réel" value={formatCurrency(trip.budget_actual)} />
            <Field label="Voyageurs" value={formatNumber(trip.nb_travelers)} />
            <Field label="Origine" value={trip.origin ?? '—'} />
            <Field label="Activités" value={String(trip.activities_count)} />
            <Field label="Hébergements" value={String(trip.accommodations_count)} />
            <Field label="Partages" value={String(trip.shares_count)} />
          </div>
        </CardContent>
      </Card>

      {/* Tabs placeholder — sub-entity DataTables are added here in future iteration */}
      <Tabs defaultValue="overview">
        <TabsList>
          <TabsTrigger value="overview">Vue d&apos;ensemble</TabsTrigger>
        </TabsList>
        <TabsContent value="overview">
          <div className="rounded-md border border-dashed border-border p-12 text-center text-sm text-muted-foreground">
            Les onglets détaillés (Activités, Hébergements, Budget, Bagages, Partages) seront
            ajoutés lors de l&apos;intégration des DataTables internes par sous-entité.
            <br />
            En attendant, utilisez les pages listes existantes filtrées.
          </div>
        </TabsContent>
      </Tabs>

      {/* Confirm delete */}
      <ConfirmDialog
        open={deleteOpen}
        onOpenChange={setDeleteOpen}
        title="Supprimer ce voyage ?"
        description={`"${trip.title}" et toutes ses données associées (activités, hébergements, budget, bagages, partages) seront définitivement supprimés.`}
        confirmLabel="Supprimer définitivement"
        variant="destructive"
        onConfirm={() => deleteMutation.mutate(id, { onSuccess: () => router.push('/app/trips') })}
        isPending={deleteMutation.isPending}
      />
    </div>
  )
}

function Field({
  label,
  value,
  children,
}: {
  label: string
  value?: string
  children?: React.ReactNode
}) {
  return (
    <div className="space-y-1">
      <p className="text-[11px] font-medium uppercase tracking-wider text-muted-foreground">
        {label}
      </p>
      <div className="text-sm text-foreground">{children ?? value}</div>
    </div>
  )
}
