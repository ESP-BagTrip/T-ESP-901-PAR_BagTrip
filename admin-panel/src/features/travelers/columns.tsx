import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminTraveler } from '@/types'

export const travelersColumns: ColumnDef<AdminTraveler>[] = [
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
    accessorKey: 'first_name',
    header: 'Prénom',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('first_name')}</span>,
  },
  {
    accessorKey: 'last_name',
    header: 'Nom',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('last_name')}</span>,
  },
  {
    accessorKey: 'traveler_type',
    header: 'Type',
    cell: ({ row }) => {
      const type = row.getValue('traveler_type') as string
      const typeColors: Record<string, string> = {
        ADULT: 'bg-primary/15 text-primary',
        CHILD: 'bg-warning/15 text-warning',
        INFANT: 'bg-chart-4/15 text-chart-4',
      }
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
            typeColors[type] || 'bg-secondary text-foreground'
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
      return <span className="text-foreground">{safeFormatDate(date, 'dd/MM/yyyy')}</span>
    },
  },
  {
    accessorKey: 'gender',
    header: 'Genre',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('gender') || '—'}</span>,
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
