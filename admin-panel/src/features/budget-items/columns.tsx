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
    cell: ({ row }) => <span className="text-foreground">{row.getValue('trip_title') || '—'}</span>,
  },
  {
    accessorKey: 'user_email',
    header: 'Utilisateur',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('user_email')}</span>,
  },
  {
    accessorKey: 'label',
    header: 'Libellé',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('label')}</span>,
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
        FLIGHT: 'bg-primary/15 text-primary',
        ACCOMMODATION: 'bg-chart-4/15 text-chart-4',
        FOOD: 'bg-orange-100 text-orange-800',
        ACTIVITY: 'bg-success/15 text-success',
        TRANSPORT: 'bg-warning/15 text-warning',
        OTHER: 'bg-secondary text-foreground',
      }
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
            categoryColors[category] || 'bg-secondary text-foreground'
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
            planned ? 'bg-primary/15 text-primary' : 'bg-success/15 text-success'
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
      return <span className="text-foreground">{safeFormatDate(date, 'dd/MM/yyyy')}</span>
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
