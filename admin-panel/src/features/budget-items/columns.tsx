import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminBudgetItem } from '@/types'

export const budgetItemsColumns: ColumnDef<AdminBudgetItem>[] = [
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
    accessorKey: 'label',
    header: 'Libellé',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('label')}</span>,
  },
  {
    accessorKey: 'amount',
    header: 'Montant',
    cell: ({ row }) => {
      const amount = row.getValue('amount') as number
      return `${amount.toFixed(2)} €`
    },
  },
  {
    accessorKey: 'category',
    header: 'Catégorie',
    cell: ({ row }) => {
      const category = row.getValue('category') as string
      const categoryColors: Record<string, string> = {
        FLIGHT: 'bg-blue-100 text-blue-800',
        ACCOMMODATION: 'bg-purple-100 text-purple-800',
        FOOD: 'bg-orange-100 text-orange-800',
        ACTIVITY: 'bg-green-100 text-green-800',
        TRANSPORT: 'bg-yellow-100 text-yellow-800',
        OTHER: 'bg-gray-100 text-gray-800',
      }
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
            categoryColors[category] || 'bg-gray-100 text-gray-800'
          }`}
        >
          {category}
        </span>
      )
    },
  },
  {
    accessorKey: 'is_planned',
    header: 'Planifié',
    cell: ({ row }) => {
      const planned = row.getValue('is_planned') as boolean
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
            planned ? 'bg-blue-100 text-blue-800' : 'bg-green-100 text-green-800'
          }`}
        >
          {planned ? 'Planifié' : 'Réel'}
        </span>
      )
    },
  },
  {
    accessorKey: 'date',
    header: 'Date',
    cell: ({ row }) => {
      const date = row.getValue('date') as string | null
      return <span className="text-gray-900">{safeFormatDate(date, 'dd/MM/yyyy')}</span>
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
