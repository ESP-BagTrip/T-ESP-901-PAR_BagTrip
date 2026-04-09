import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminBaggageItem } from '@/types'

export const baggageItemsColumns: ColumnDef<AdminBaggageItem>[] = [
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
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('trip_title') || '—'}</span>,
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
    accessorKey: 'category',
    header: 'Catégorie',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('category') || '—'}</span>,
  },
  {
    accessorKey: 'quantity',
    header: 'Qté',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('quantity') ?? 1}</span>,
  },
  {
    accessorKey: 'is_packed',
    header: 'Emballé',
    cell: ({ row }) => {
      const isPacked = row.getValue('is_packed') as boolean | null
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
            isPacked ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
          }`}
        >
          {isPacked ? 'Oui' : 'Non'}
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
