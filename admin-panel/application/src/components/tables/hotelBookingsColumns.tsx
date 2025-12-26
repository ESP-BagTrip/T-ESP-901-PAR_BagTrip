import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminHotelBooking } from '@/types'

export const hotelBookingsColumns: ColumnDef<AdminHotelBooking>[] = [
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
    accessorKey: 'hotel_id',
    header: 'Hotel ID',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('hotel_id') || '—'}</span>,
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
    accessorKey: 'amadeus_booking_id',
    header: 'Amadeus Booking ID',
    cell: ({ row }) => {
      const bookingId = row.getValue('amadeus_booking_id') as string | null
      return (
        <span className="font-mono text-xs text-gray-600">
          {bookingId ? `${bookingId.slice(0, 12)}...` : '—'}
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
        <span className="text-gray-500 text-xs">{safeFormatDate(date, 'dd/MM/yyyy HH:mm')}</span>
      )
    },
  },
]
