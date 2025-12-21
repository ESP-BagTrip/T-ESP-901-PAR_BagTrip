import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminFlightBooking } from '@/types'

export const flightBookingsColumns: ColumnDef<AdminFlightBooking>[] = [
  {
    accessorKey: 'id',
    header: 'ID',
    cell: ({ row }) => (
      <span className="font-mono text-xs">{row.getValue('id').slice(0, 8)}...</span>
    ),
  },
  {
    accessorKey: 'trip_title',
    header: 'Trip',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('trip_title') || '—'}</span>,
  },
  {
    accessorKey: 'user_email',
    header: 'Utilisateur',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('user_email')}</span>,
  },
  {
    accessorKey: 'status',
    header: 'Statut',
    cell: ({ row }) => {
      const status = row.getValue('status') as string | null
      const statusColors: Record<string, string> = {
        CONFIRMED: 'bg-green-100 text-green-800',
        PENDING: 'bg-yellow-100 text-yellow-800',
        CANCELLED: 'bg-red-100 text-red-800',
      }
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
            statusColors[status || ''] || 'bg-gray-100 text-gray-800'
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
        <span className="font-mono text-xs text-gray-600">
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
      return <span className="text-gray-900">{ref || '—'}</span>
    },
  },
  {
    accessorKey: 'created_at',
    header: 'Créé le',
    cell: ({ row }) => {
      const date = row.getValue('created_at') as string | null
      return (
        <span className="text-gray-500 text-xs">{safeFormatDate(date, 'dd/MM/yyyy HH:mm')}</span>
      )
    },
  },
]
