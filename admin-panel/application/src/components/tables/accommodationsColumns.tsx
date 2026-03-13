import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminAccommodation } from '@/types'

export const accommodationsColumns: ColumnDef<AdminAccommodation>[] = [
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
    cell: ({ row }) => (
      <span className="text-gray-900">{row.getValue('trip_title') || '—'}</span>
    ),
  },
  {
    accessorKey: 'user_email',
    header: 'Utilisateur',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('user_email')}</span>,
  },
  {
    accessorKey: 'name',
    header: 'Nom',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('name')}</span>,
  },
  {
    accessorKey: 'check_in',
    header: 'Arrivée',
    cell: ({ row }) => {
      const date = row.getValue('check_in') as string | null
      return <span className="text-gray-900">{safeFormatDate(date, 'dd/MM/yyyy')}</span>
    },
  },
  {
    accessorKey: 'check_out',
    header: 'Départ',
    cell: ({ row }) => {
      const date = row.getValue('check_out') as string | null
      return <span className="text-gray-900">{safeFormatDate(date, 'dd/MM/yyyy')}</span>
    },
  },
  {
    accessorKey: 'price',
    header: 'Prix',
    cell: ({ row }) => {
      const price = row.getValue('price') as number | null
      return <span className="text-gray-900">{price != null ? `${price.toFixed(2)} €` : '—'}</span>
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
