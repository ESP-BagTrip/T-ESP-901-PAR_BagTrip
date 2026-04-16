import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminBookingIntent } from '@/types'

export const bookingIntentsColumns: ColumnDef<AdminBookingIntent>[] = [
  {
    accessorKey: 'id',
    header: 'ID',
    cell: ({ row }) => (
      <span className="font-mono text-xs">{(row.getValue('id') as string).slice(0, 8)}...</span>
    ),
  },
  {
    accessorKey: 'user_email',
    header: 'Utilisateur',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('user_email')}</span>,
  },
  {
    accessorKey: 'trip_title',
    header: 'Trip',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('trip_title') || '—'}</span>,
  },
  {
    accessorKey: 'type',
    header: 'Type',
    cell: ({ row }) => {
      const type = row.getValue('type') as string
      const typeColors: Record<string, string> = {
        flight: 'bg-primary/15 text-primary',
        hotel: 'bg-chart-4/15 text-chart-4',
      }
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
            typeColors[type] || 'bg-secondary text-foreground'
          }`}
        >
          {type}
        </span>
      )
    },
  },
  {
    accessorKey: 'status',
    header: 'Statut',
    cell: ({ row }) => {
      const status = row.getValue('status') as string
      const statusColors: Record<string, string> = {
        INIT: 'bg-secondary text-foreground',
        AUTHORIZED: 'bg-primary/15 text-primary',
        BOOKING_PENDING: 'bg-warning/15 text-warning',
        BOOKED: 'bg-success/15 text-success',
        CAPTURED: 'bg-success/15 text-success',
        FAILED: 'bg-destructive/15 text-destructive',
        CANCELLED: 'bg-destructive/15 text-destructive',
        PAYMENT_CAPTURE_FAILED: 'bg-destructive/15 text-destructive',
      }
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
            statusColors[status] || 'bg-secondary text-foreground'
          }`}
        >
          {status}
        </span>
      )
    },
  },
  {
    accessorKey: 'amount',
    header: 'Montant',
    cell: ({ row }) => {
      const amount = row.getValue('amount') as number
      const currency = row.original.currency
      return (
        <span className="text-foreground">
          {amount} {currency}
        </span>
      )
    },
  },
  {
    accessorKey: 'stripe_payment_intent_id',
    header: 'Stripe PI',
    cell: ({ row }) => {
      const pi = row.getValue('stripe_payment_intent_id') as string | null
      return (
        <span className="font-mono text-xs text-muted-foreground">
          {pi ? `${pi.slice(0, 12)}...` : '—'}
        </span>
      )
    },
  },
  {
    accessorKey: 'created_at',
    header: 'Créé le',
    cell: ({ row }) => {
      const date = row.getValue('created_at') as string | null
      return (
        <span className="text-muted-foreground text-xs">
          {safeFormatDate(date, 'dd/MM/yyyy HH:mm')}
        </span>
      )
    },
  },
]
