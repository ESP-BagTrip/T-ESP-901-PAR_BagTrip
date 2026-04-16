import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminFlightBooking } from '@/types'

export const flightBookingsColumns: ColumnDef<AdminFlightBooking>[] = [
  {
    accessorKey: 'id',
    header: 'ID',
    cell: ({ row }) => (
      <span className="font-mono text-xs">{(row.getValue('id') as string).slice(0, 8)}...</span>
    ),
  },
  {
    accessorKey: 'trip_title',
    header: 'Trip',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('trip_title') || '—'}</span>,
  },
  {
    accessorKey: 'user_email',
    header: 'Utilisateur',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('user_email')}</span>,
  },
  {
    accessorKey: 'status',
    header: 'Statut',
    cell: ({ row }) => {
      const status = row.getValue('status') as string | null
      const statusColors: Record<string, string> = {
        CONFIRMED: 'bg-success/15 text-success',
        PENDING: 'bg-warning/15 text-warning',
        CANCELLED: 'bg-destructive/15 text-destructive',
      }
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
            statusColors[status || ''] || 'bg-secondary text-foreground'
          }`}
        >
          {status || '—'}
        </span>
      )
    },
  },
  {
    accessorKey: 'amadeus_flight_order_id',
    header: 'Amadeus Order ID',
    cell: ({ row }) => {
      const orderId = row.getValue('amadeus_flight_order_id') as string | null
      return (
        <span className="font-mono text-xs text-muted-foreground">
          {orderId ? `${orderId.slice(0, 12)}...` : '—'}
        </span>
      )
    },
  },
  {
    accessorKey: 'booking_reference',
    header: 'Référence',
    cell: ({ row }) => {
      const ref = row.getValue('booking_reference') as string | null
      return <span className="text-foreground">{ref || '—'}</span>
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
