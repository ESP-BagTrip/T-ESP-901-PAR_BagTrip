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
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('user_email')}</span>,
  },
  {
    accessorKey: 'trip_title',
    header: 'Trip',
    cell: ({ row }) => (
      <span className="text-gray-900">{row.getValue('trip_title') || '—'}</span>
    ),
  },
  {
    accessorKey: 'type',
    header: 'Type',
    cell: ({ row }) => {
      const type = row.getValue('type') as string
      const typeColors: Record<string, string> = {
        flight: 'bg-blue-100 text-blue-800',
        hotel: 'bg-purple-100 text-purple-800',
      }
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
            typeColors[type] || 'bg-gray-100 text-gray-800'
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
        INIT: 'bg-gray-100 text-gray-800',
        AUTHORIZED: 'bg-blue-100 text-blue-800',
        BOOKING_PENDING: 'bg-yellow-100 text-yellow-800',
        BOOKED: 'bg-green-100 text-green-800',
        CAPTURED: 'bg-green-100 text-green-800',
        FAILED: 'bg-red-100 text-red-800',
        CANCELLED: 'bg-red-100 text-red-800',
        PAYMENT_CAPTURE_FAILED: 'bg-red-100 text-red-800',
      }
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
            statusColors[status] || 'bg-gray-100 text-gray-800'
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
      return <span className="text-gray-900">{amount} {currency}</span>
    },
  },
  {
    accessorKey: 'stripe_payment_intent_id',
    header: 'Stripe PI',
    cell: ({ row }) => {
      const pi = row.getValue('stripe_payment_intent_id') as string | null
      return <span className="font-mono text-xs text-gray-500">{pi ? `${pi.slice(0, 12)}...` : '—'}</span>
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
