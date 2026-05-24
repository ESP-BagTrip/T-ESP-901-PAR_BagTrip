'use client'

import { use, useState } from 'react'
import { useRouter } from 'next/navigation'
import { useQuery } from '@tanstack/react-query'
import { Ban, Pencil, RotateCcw, ShieldOff, Trash2 } from 'lucide-react'

import { PageHeader } from '@/components/layout/PageHeader'
import { ConfirmDialog } from '@/components/ConfirmDialog'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { adminService } from '@/services'
import { safeFormatDate } from '@/utils/date'
import { formatNumber } from '@/utils/format'
import { UserEditSheet } from '@/features/users/components/UserEditSheet'
import {
  useBanUser,
  useUnbanUser,
  useDeleteUser,
  useResetAiQuota,
} from '@/features/users/mutations'
import type { AdminUserDetail } from '@/types/admin'

const PLAN_BADGE: Record<string, 'default' | 'warning' | 'secondary'> = {
  FREE: 'secondary',
  PREMIUM: 'warning',
  ADMIN: 'default',
}

export default function UserDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params)
  const router = useRouter()

  const { data: user, isLoading } = useQuery<AdminUserDetail>({
    queryKey: ['admin', 'user-detail', id],
    queryFn: () => adminService.getUserDetail(id),
  })

  const [editOpen, setEditOpen] = useState(false)
  const [banOpen, setBanOpen] = useState(false)
  const [deleteOpen, setDeleteOpen] = useState(false)

  const banMutation = useBanUser(id)
  const unbanMutation = useUnbanUser(id)
  const deleteMutation = useDeleteUser()
  const resetQuotaMutation = useResetAiQuota(id)

  const isBanned = !!user?.banned_at

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-10 w-64" />
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <Skeleton className="h-48" />
          <Skeleton className="h-48" />
        </div>
      </div>
    )
  }

  if (!user) {
    return <div className="py-12 text-center text-muted-foreground">Utilisateur introuvable.</div>
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title={user.email}
        description={`Membre depuis ${safeFormatDate(user.created_at, 'dd/MM/yyyy')}`}
        actions={
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" onClick={() => setEditOpen(true)}>
              <Pencil className="size-4" /> Modifier
            </Button>
            {isBanned ? (
              <Button
                variant="outline"
                size="sm"
                onClick={() => unbanMutation.mutate(undefined)}
                disabled={unbanMutation.isPending}
              >
                <ShieldOff className="size-4" /> Débannir
              </Button>
            ) : (
              <Button variant="outline" size="sm" onClick={() => setBanOpen(true)}>
                <Ban className="size-4" /> Bannir
              </Button>
            )}
            <Button variant="destructive" size="sm" onClick={() => setDeleteOpen(true)}>
              <Trash2 className="size-4" /> Supprimer
            </Button>
          </div>
        }
      />

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Profile */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Profil</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Field label="Email" value={user.email} />
            <Field label="Nom" value={user.full_name ?? '—'} />
            <Field label="Téléphone" value={user.phone ?? '—'} />
            <Field label="Plan">
              <Badge variant={PLAN_BADGE[user.plan] ?? 'outline'}>{user.plan}</Badge>
            </Field>
            {user.plan_expires_at && (
              <Field label="Expire le" value={safeFormatDate(user.plan_expires_at, 'dd/MM/yyyy')} />
            )}
            {isBanned && (
              <Field label="Banni">
                <Badge variant="destructive">
                  Banni le {safeFormatDate(user.banned_at!, 'dd/MM/yyyy')}
                </Badge>
                {user.ban_reason && (
                  <span className="ml-2 text-xs text-muted-foreground">{user.ban_reason}</span>
                )}
              </Field>
            )}
            <Field label="Voyages" value={formatNumber(user.trips_count)} />
            <Field label="Paiements" value={formatNumber(user.bookings_count)} />
          </CardContent>
        </Card>

        {/* AI Quota */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Quotas IA</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Field label="Générations utilisées" value={String(user.ai_generations_count)} />
            {user.ai_generations_reset_at && (
              <Field
                label="Dernier reset"
                value={safeFormatDate(user.ai_generations_reset_at, 'dd/MM/yyyy HH:mm')}
              />
            )}
            <Button
              variant="outline"
              size="sm"
              onClick={() => resetQuotaMutation.mutate(undefined)}
              disabled={resetQuotaMutation.isPending}
            >
              <RotateCcw className="size-4" /> Réinitialiser le quota
            </Button>
          </CardContent>
        </Card>
      </div>

      {/* Sheets & Dialogs */}
      <UserEditSheet user={user} open={editOpen} onClose={() => setEditOpen(false)} />

      <ConfirmDialog
        open={banOpen}
        onOpenChange={setBanOpen}
        title="Bannir cet utilisateur ?"
        description={`${user.email} ne pourra plus se connecter à BagTrip. Cette action est réversible.`}
        confirmLabel="Bannir"
        variant="destructive"
        onConfirm={() => banMutation.mutate('', { onSuccess: () => setBanOpen(false) })}
        isPending={banMutation.isPending}
      />

      <ConfirmDialog
        open={deleteOpen}
        onOpenChange={setDeleteOpen}
        title="Supprimer cet utilisateur ?"
        description={`${user.email} sera supprimé (soft-delete). Ses voyages et données resteront en base mais ne seront plus accessibles.`}
        confirmLabel="Supprimer"
        variant="destructive"
        onConfirm={() => deleteMutation.mutate(id, { onSuccess: () => router.push('/app/users') })}
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
    <div className="flex items-start justify-between gap-4">
      <span className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
        {label}
      </span>
      <span className="text-sm text-foreground">{children ?? value}</span>
    </div>
  )
}
