import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { Feedback } from '@/types/feedback'

export const feedbacksColumns: ColumnDef<Feedback>[] = [
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
    cell: ({ row }) => (
      <span className="text-gray-900">{row.getValue('trip_title') || '—'}</span>
    ),
  },
  {
    accessorKey: 'user_email',
    header: 'Utilisateur',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('user_email')}</span>,
  },
  {
    accessorKey: 'overall_rating',
    header: 'Note',
    cell: ({ row }) => {
      const rating = row.getValue('overall_rating') as number
      return <span className="text-gray-900">{'★'.repeat(rating)}{'☆'.repeat(5 - rating)}</span>
    },
  },
  {
    accessorKey: 'highlights',
    header: 'Points forts',
    cell: ({ row }) => {
      const text = row.getValue('highlights') as string | null
      return (
        <span className="text-gray-700 text-xs max-w-[200px] truncate block">
          {text || '—'}
        </span>
      )
    },
  },
  {
    accessorKey: 'lowlights',
    header: 'Points faibles',
    cell: ({ row }) => {
      const text = row.getValue('lowlights') as string | null
      return (
        <span className="text-gray-700 text-xs max-w-[200px] truncate block">
          {text || '—'}
        </span>
      )
    },
  },
  {
    accessorKey: 'would_recommend',
    header: 'Recommande',
    cell: ({ row }) => {
      const recommends = row.getValue('would_recommend') as boolean
      return (
        <span
          className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
            recommends ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
          }`}
        >
          {recommends ? 'Oui' : 'Non'}
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
