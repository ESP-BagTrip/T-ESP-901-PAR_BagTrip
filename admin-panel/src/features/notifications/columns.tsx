import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminNotification } from '@/types'

export const notificationsColumns: ColumnDef<AdminNotification>[] = [
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
    accessorKey: 'trip_title',
    header: 'Trip',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('trip_title') || '—'}</span>,
  },
  {
    accessorKey: 'type',
    header: 'Type',
    cell: ({ row }) => {
      const type = row.getValue('type') as string
      const typeColors: Record<string, string> = {
        DEPARTURE_REMINDER: 'bg-primary/15 text-primary',
        FLIGHT_H4: 'bg-indigo-100 text-indigo-800',
        FLIGHT_H1: 'bg-chart-4/15 text-chart-4',
        MORNING_SUMMARY: 'bg-warning/15 text-warning',
        ACTIVITY_H1: 'bg-success/15 text-success',
        BUDGET_ALERT: 'bg-orange-100 text-orange-800',
        TRIP_ENDED: 'bg-secondary text-foreground',
        TRIP_SHARED: 'bg-teal-100 text-teal-800',
        ADMIN: 'bg-destructive/15 text-destructive',
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
    accessorKey: 'title',
    header: 'Titre',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('title')}</span>,
  },
  {
    accessorKey: 'body',
    header: 'Message',
    cell: ({ row }) => {
      const body = row.getValue('body') as string
      return (
        <span className="text-muted-foreground text-xs" title={body}>
          {body.length > 50 ? `${body.slice(0, 50)}...` : body}
        </span>
      )
    },
  },
  {
    accessorKey: 'is_read',
    header: 'Lu',
    cell: ({ row }) => {
      const isRead = row.getValue('is_read') as boolean
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
            isRead ? 'bg-success/15 text-success' : 'bg-destructive/15 text-destructive'
          }`}
        >
          {isRead ? 'Lu' : 'Non lu'}
        </span>
      )
    },
  },
  {
    accessorKey: 'sent_at',
    header: 'Envoyé le',
    cell: ({ row }) => {
      const date = row.getValue('sent_at') as string | null
      return (
        <span className="text-muted-foreground text-xs">
          {date ? safeFormatDate(date, 'dd/MM/yyyy HH:mm') : '—'}
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
