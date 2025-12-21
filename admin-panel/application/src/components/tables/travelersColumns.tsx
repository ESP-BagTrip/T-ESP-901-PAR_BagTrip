import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminTraveler } from '@/types'

export const travelersColumns: ColumnDef<AdminTraveler>[] = [
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
    accessorKey: 'first_name',
    header: 'Prénom',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('first_name')}</span>,
  },
  {
    accessorKey: 'last_name',
    header: 'Nom',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('last_name')}</span>,
  },
  {
    accessorKey: 'traveler_type',
    header: 'Type',
    cell: ({ row }) => {
      const type = row.getValue('traveler_type') as string
      const typeColors: Record<string, string> = {
        ADULT: 'bg-blue-100 text-blue-800',
        CHILD: 'bg-yellow-100 text-yellow-800',
        INFANT: 'bg-purple-100 text-purple-800',
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
    accessorKey: 'date_of_birth',
    header: 'Date de naissance',
    cell: ({ row }) => {
      const date = row.getValue('date_of_birth') as string | null
      return <span className="text-gray-900">{safeFormatDate(date, 'dd/MM/yyyy')}</span>
    },
  },
  {
    accessorKey: 'gender',
    header: 'Genre',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('gender') || '—'}</span>,
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
