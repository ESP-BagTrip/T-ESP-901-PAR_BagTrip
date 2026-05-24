import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminTravelerProfile } from '@/types'

export const profilesColumns: ColumnDef<AdminTravelerProfile>[] = [
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
    cell: ({ row }) => <span className="text-foreground">{row.getValue('user_email')}</span>,
  },
  {
    accessorKey: 'travel_types',
    header: 'Types de voyage',
    cell: ({ row }) => {
      const types = row.getValue('travel_types') as string[] | null
      return <span className="text-foreground">{types ? types.join(', ') : '—'}</span>
    },
  },
  {
    accessorKey: 'travel_style',
    header: 'Style',
    cell: ({ row }) => (
      <span className="text-foreground">{row.getValue('travel_style') || '—'}</span>
    ),
  },
  {
    accessorKey: 'budget',
    header: 'Budget',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('budget') || '—'}</span>,
  },
  {
    accessorKey: 'companions',
    header: 'Compagnons',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('companions') || '—'}</span>,
  },
  {
    accessorKey: 'is_completed',
    header: 'Complété',
    cell: ({ row }) => {
      const completed = row.getValue('is_completed') as boolean
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
            completed ? 'bg-success/15 text-success' : 'bg-warning/15 text-warning'
          }`}
        >
          {completed ? 'Oui' : 'Non'}
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
