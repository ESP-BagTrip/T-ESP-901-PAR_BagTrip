import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminTrip } from '@/types'

export const tripsColumns: ColumnDef<AdminTrip>[] = [
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
    accessorKey: 'title',
    header: 'Titre',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('title') || '—'}</span>,
  },
  {
    accessorKey: 'destination_name',
    header: 'Destination',
    cell: ({ row }) => {
      const name = row.getValue('destination_name') as string | null
      const iata = row.original.destination_iata
      return <span className="text-foreground">{name || iata || '—'}</span>
    },
  },
  {
    accessorKey: 'origin_iata',
    header: 'Origine',
    cell: ({ row }) => (
      <span className="text-foreground">{row.getValue('origin_iata') || '—'}</span>
    ),
  },
  {
    accessorKey: 'start_date',
    header: 'Départ',
    cell: ({ row }) => {
      const date = row.getValue('start_date') as string | null
      return <span className="text-foreground">{safeFormatDate(date, 'dd/MM/yyyy')}</span>
    },
  },
  {
    accessorKey: 'end_date',
    header: 'Retour',
    cell: ({ row }) => {
      const date = row.getValue('end_date') as string | null
      return <span className="text-foreground">{safeFormatDate(date, 'dd/MM/yyyy')}</span>
    },
  },
  {
    accessorKey: 'nb_travelers',
    header: 'Voyageurs',
    cell: ({ row }) => {
      const n = row.getValue('nb_travelers') as number | null
      return <span className="tabular-nums text-foreground">{n ?? '—'}</span>
    },
  },
  {
    accessorKey: 'status',
    header: 'Statut',
    cell: ({ row }) => {
      const status = row.getValue('status') as string | null
      const statusColors: Record<string, string> = {
        DRAFT: 'bg-secondary text-foreground',
        PLANNED: 'bg-primary/15 text-primary',
        ONGOING: 'bg-success/15 text-success',
        COMPLETED: 'bg-chart-4/15 text-chart-4',
      }
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
            statusColors[status || ''] || 'bg-secondary text-foreground'
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
        <span className="text-muted-foreground text-xs">
          {safeFormatDate(date, 'dd/MM/yyyy HH:mm')}
        </span>
      )
    },
  },
]
