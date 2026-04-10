import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminTripShare } from '@/types'

export const tripSharesColumns: ColumnDef<AdminTripShare>[] = [
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
    header: 'Utilisateur partagé',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('user_email')}</span>,
  },
  {
    accessorKey: 'role',
    header: 'Rôle',
    cell: ({ row }) => (
      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary/15 text-primary">
        {row.getValue('role')}
      </span>
    ),
  },
  {
    accessorKey: 'invited_at',
    header: 'Invité le',
    cell: ({ row }) => {
      const date = row.getValue('invited_at') as string | null
      return (
        <span className="text-muted-foreground text-xs">
          {safeFormatDate(date, 'dd/MM/yyyy HH:mm')}
        </span>
      )
    },
  },
]
