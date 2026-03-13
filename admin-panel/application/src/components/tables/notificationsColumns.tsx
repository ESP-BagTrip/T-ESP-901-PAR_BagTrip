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
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('user_email')}</span>,
  },
  {
    accessorKey: 'trip_title',
    header: 'Trip',
    cell: ({ row }) => (
      <span className="text-gray-900">{row.getValue('trip_title') || '—'}</span>
    ),
  },
  {
    accessorKey: 'type',
    header: 'Type',
    cell: ({ row }) => {
      const type = row.getValue('type') as string
      const typeColors: Record<string, string> = {
        DEPARTURE_REMINDER: 'bg-blue-100 text-blue-800',
        FLIGHT_H4: 'bg-indigo-100 text-indigo-800',
        FLIGHT_H1: 'bg-purple-100 text-purple-800',
        MORNING_SUMMARY: 'bg-yellow-100 text-yellow-800',
        ACTIVITY_H1: 'bg-green-100 text-green-800',
        BUDGET_ALERT: 'bg-orange-100 text-orange-800',
        TRIP_ENDED: 'bg-gray-100 text-gray-800',
      }
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
            typeColors[type] || 'bg-gray-100 text-gray-800'
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
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('title')}</span>,
  },
  {
    accessorKey: 'body',
    header: 'Message',
    cell: ({ row }) => {
      const body = row.getValue('body') as string
      return (
        <span className="text-gray-600 text-xs" title={body}>
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
            isRead ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
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
        <span className="text-gray-500 text-xs">
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
        <span className="text-gray-500 text-xs">{safeFormatDate(date, 'dd/MM/yyyy HH:mm')}</span>
      )
    },
  },
]
