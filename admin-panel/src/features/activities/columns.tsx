import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminActivity } from '@/types'

export const activitiesColumns: ColumnDef<AdminActivity>[] = [
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
    accessorKey: 'title',
    header: 'Titre',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('title')}</span>,
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
    accessorKey: 'category',
    header: 'Catégorie',
    cell: ({ row }) => {
      const category = row.getValue('category') as string
      const categoryColors: Record<string, string> = {
        VISIT: 'bg-primary/15 text-primary',
        RESTAURANT: 'bg-orange-100 text-orange-800',
        TRANSPORT: 'bg-warning/15 text-warning',
        LEISURE: 'bg-success/15 text-success',
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
    accessorKey: 'estimated_cost',
    header: 'Coût estimé',
    cell: ({ row }) => {
      const cost = row.getValue('estimated_cost') as number | null
      return cost != null ? `${cost.toFixed(2)} €` : '—'
    },
  },
  {
    accessorKey: 'is_booked',
    header: 'Réservé',
    cell: ({ row }) => {
      const booked = row.getValue('is_booked') as boolean
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
            booked ? 'bg-success/15 text-success' : 'bg-secondary text-foreground'
          }`}
        >
          {booked ? 'Oui' : 'Non'}
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
        <span className="text-muted-foreground text-xs">
          {safeFormatDate(date, 'dd/MM/yyyy HH:mm')}
        </span>
      )
    },
  },
]
