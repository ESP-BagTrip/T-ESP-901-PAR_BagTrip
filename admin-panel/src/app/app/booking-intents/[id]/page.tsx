'use client'

import { use, useState } from 'react'
import Link from 'next/link'
import { useQuery } from '@tanstack/react-query'
import { Ban, CircleDollarSign } from 'lucide-react'

import { PageHeader } from '@/components/layout/PageHeader'
import { ConfirmDialog } from '@/components/ConfirmDialog'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Skeleton } from '@/components/ui/skeleton'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { adminService } from '@/services'
import { safeFormatDate } from '@/utils/date'
import { formatCurrency } from '@/utils/format'
import {
  useCancelBooking,
  useForceBookingStatus,
  useMarkRefunded,
} from '@/features/booking-intents/mutations'
import { cn } from '@/lib/utils'

interface BookingDetail {
  id: string
  user_id: string
  user_email: string
  trip_id: string
  trip_title: string | null
  type: string
  status: string
  amount: number
  currency: string
  stripe_payment_intent_id: string | null
  stripe_charge_id: string | null
  amadeus_order_id: string | null
  last_error: Record<string, unknown> | null
  created_at: string
  updated_at: string
}

const ALL_STATUSES = [
  'INIT',
  'AUTHORIZED',
  'BOOKING_PENDING',
  'BOOKED',
  'CAPTURED',
  'FAILED',
  'CANCELLED',
  'PAYMENT_CAPTURE_FAILED',
  'REFUNDED',
]

const STATUS_BADGE: Record<
  string,
  'default' | 'secondary' | 'success' | 'warning' | 'destructive'
> = {
  INIT: 'secondary',
  AUTHORIZED: 'default',
  BOOKING_PENDING: 'warning',
  BOOKED: 'default',
  CAPTURED: 'success',
  FAILED: 'destructive',
  CANCELLED: 'secondary',
  PAYMENT_CAPTURE_FAILED: 'destructive',
  REFUNDED: 'warning',
}

const TIMELINE_ORDER = ['INIT', 'AUTHORIZED', 'BOOKING_PENDING', 'BOOKED', 'CAPTURED']

export default function BookingDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params)

  const { data: booking, isLoading } = useQuery<BookingDetail>({
    queryKey: ['admin', 'booking-detail', id],
    queryFn: () => adminService.getBookingIntentDetail(id),
  })

  const [cancelOpen, setCancelOpen] = useState(false)
  const [refundOpen, setRefundOpen] = useState(false)

  const cancelMutation = useCancelBooking(id)
  const refundMutation = useMarkRefunded(id)
  const statusMutation = useForceBookingStatus(id)

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

  if (!booking) {
    return <div className="py-12 text-center text-muted-foreground">Booking introuvable.</div>
  }

  const currentStepIdx = TIMELINE_ORDER.indexOf(booking.status)
  const isTerminal = ['FAILED', 'CANCELLED', 'PAYMENT_CAPTURE_FAILED', 'REFUNDED'].includes(
    booking.status
  )

  return (
    <div className="space-y-6">
      <PageHeader
        title={`Booking #${booking.id.slice(0, 8)}`}
        description={`${formatCurrency(booking.amount, { currency: booking.currency })} · ${booking.type}`}
        actions={
          <div className="flex items-center gap-2">
            {booking.status !== 'CANCELLED' && (
              <Button variant="outline" size="sm" onClick={() => setCancelOpen(true)}>
                <Ban className="size-4" /> Annuler
              </Button>
            )}
            {booking.status !== 'REFUNDED' && (
              <Button variant="outline" size="sm" onClick={() => setRefundOpen(true)}>
                <CircleDollarSign className="size-4" /> Rembourser
              </Button>
            )}
          </div>
        }
      />

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Details */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Détails</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Field label="Statut">
              <Badge variant={STATUS_BADGE[booking.status] ?? 'outline'}>{booking.status}</Badge>
            </Field>
            <Field label="Utilisateur">
              <Link
                href={`/app/users/${booking.user_id}`}
                className="text-sm text-primary hover:underline"
              >
                {booking.user_email}
              </Link>
            </Field>
            <Field label="Voyage">
              <Link
                href={`/app/trips/${booking.trip_id}`}
                className="text-sm text-primary hover:underline"
              >
                {booking.trip_title ?? booking.trip_id.slice(0, 8)}
              </Link>
            </Field>
            <Field
              label="Montant"
              value={formatCurrency(booking.amount, { currency: booking.currency })}
            />
            <Field label="Créé le" value={safeFormatDate(booking.created_at, 'dd/MM/yyyy HH:mm')} />
          </CardContent>
        </Card>

        {/* References */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Références</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Field label="Stripe PI" value={booking.stripe_payment_intent_id ?? '—'} />
            <Field label="Stripe Charge" value={booking.stripe_charge_id ?? '—'} />
            <Field label="Amadeus Order" value={booking.amadeus_order_id ?? '—'} />
            <div className="pt-2">
              <p className="mb-1.5 text-[11px] font-medium uppercase tracking-wider text-muted-foreground">
                Forcer le statut
              </p>
              <Select
                value={booking.status}
                onValueChange={s => statusMutation.mutate(s)}
                disabled={statusMutation.isPending}
              >
                <SelectTrigger className="w-48">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {ALL_STATUSES.map(s => (
                    <SelectItem key={s} value={s}>
                      {s}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Timeline */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Timeline</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-0">
            {TIMELINE_ORDER.map((step, i) => {
              const reached = currentStepIdx >= i
              const current = booking.status === step
              return (
                <div key={step} className="flex items-center">
                  <div className="flex flex-col items-center gap-1">
                    <div
                      className={cn(
                        'flex size-8 items-center justify-center rounded-full border-2 text-xs font-medium transition-colors',
                        current
                          ? 'border-primary bg-primary text-primary-foreground'
                          : reached
                            ? 'border-success bg-success/10 text-success'
                            : 'border-border bg-muted text-muted-foreground'
                      )}
                    >
                      {i + 1}
                    </div>
                    <span className="max-w-20 text-center text-[10px] text-muted-foreground">
                      {step}
                    </span>
                  </div>
                  {i < TIMELINE_ORDER.length - 1 && (
                    <div
                      className={cn(
                        'mx-1 h-0.5 w-8 rounded-full',
                        reached && currentStepIdx > i ? 'bg-success' : 'bg-border'
                      )}
                    />
                  )}
                </div>
              )
            })}
            {isTerminal && (
              <>
                <div className="mx-1 h-0.5 w-8 rounded-full bg-destructive" />
                <div className="flex flex-col items-center gap-1">
                  <div className="flex size-8 items-center justify-center rounded-full border-2 border-destructive bg-destructive/10 text-xs font-medium text-destructive">
                    !
                  </div>
                  <span className="max-w-20 text-center text-[10px] text-destructive">
                    {booking.status}
                  </span>
                </div>
              </>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Error */}
      {booking.last_error && (
        <Alert variant="destructive">
          <AlertDescription>
            <pre className="overflow-auto whitespace-pre-wrap text-xs">
              {JSON.stringify(booking.last_error, null, 2)}
            </pre>
          </AlertDescription>
        </Alert>
      )}

      {/* Confirm dialogs */}
      <ConfirmDialog
        open={cancelOpen}
        onOpenChange={setCancelOpen}
        title="Annuler ce booking ?"
        description="Le statut sera changé en CANCELLED. Cette action ne rembourse pas automatiquement le paiement Stripe."
        confirmLabel="Annuler le booking"
        variant="destructive"
        onConfirm={() =>
          cancelMutation.mutate(undefined, { onSuccess: () => setCancelOpen(false) })
        }
        isPending={cancelMutation.isPending}
      />
      <ConfirmDialog
        open={refundOpen}
        onOpenChange={setRefundOpen}
        title="Marquer comme remboursé ?"
        description="Le statut sera changé en REFUNDED. Le remboursement Stripe doit être effectué manuellement dans le dashboard Stripe."
        confirmLabel="Marquer remboursé"
        variant="destructive"
        onConfirm={() =>
          refundMutation.mutate(undefined, { onSuccess: () => setRefundOpen(false) })
        }
        isPending={refundMutation.isPending}
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
      <span className="text-[11px] font-medium uppercase tracking-wider text-muted-foreground">
        {label}
      </span>
      <span className="text-right text-sm text-foreground">{children ?? value}</span>
    </div>
  )
}
