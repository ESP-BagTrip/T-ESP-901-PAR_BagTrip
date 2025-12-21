import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminTrip } from '@/types'

export const tripsColumns: ColumnDef<AdminTrip>[] = [
  {
    accessorKey: 'id',
    header: 'ID',
    cell: ({ row }) => (
      <span className="font-mono text-xs">{row.getValue('id').slice(0, 8)}...</span>
    ),
  },
  {
    accessorKey: 'user_email',
    header: 'Utilisateur',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('user_email')}</span>,
  },
  {
    accessorKey: 'title',
    header: 'Titre',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('title') || '—'}</span>,
  },
  {
    accessorKey: 'origin_iata',
    header: 'Origine',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('origin_iata') || '—'}</span>,
  },
  {
    accessorKey: 'destination_iata',
    header: 'Destination',
    cell: ({ row }) => (
      <span className="text-gray-900">{row.getValue('destination_iata') || '—'}</span>
    ),
  },
  {
    accessorKey: 'start_date',
    header: 'Date de départ',
    cell: ({ row }) => {
      const date = row.getValue('start_date') as string | null
      return <span className="text-gray-900">{safeFormatDate(date, 'dd/MM/yyyy')}</span>
    },
  },
  {
    accessorKey: 'end_date',
    header: 'Date de retour',
    cell: ({ row }) => {
      const date = row.getValue('end_date') as string | null
      return <span className="text-gray-900">{safeFormatDate(date, 'dd/MM/yyyy')}</span>
    },
  },
  {
    accessorKey: 'status',
    header: 'Statut',
    cell: ({ row }) => {
      const status = row.getValue('status') as string | null
      const statusColors: Record<string, string> = {
        draft: 'bg-gray-100 text-gray-800',
        planned: 'bg-blue-100 text-blue-800',
        booked: 'bg-green-100 text-green-800',
        cancelled: 'bg-red-100 text-red-800',
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
