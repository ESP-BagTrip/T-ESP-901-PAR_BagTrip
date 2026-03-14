import type { ColumnDef } from '@tanstack/react-table'
import type { User } from '@/types'
import { safeFormatDate } from '@/utils/date'

export const usersColumns: ColumnDef<User>[] = [
  {
    accessorKey: 'id',
    header: 'ID',
    cell: ({ row }) => (
      <span className="font-mono text-xs">{(row.getValue('id') as string).slice(0, 8)}...</span>
    ),
  },
  {
    accessorKey: 'email',
    header: 'Email',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('email')}</span>,
  },
  {
    accessorKey: 'plan',
    header: 'Plan',
    cell: ({ row }) => {
      const plan = row.getValue('plan') as string
      const colors: Record<string, string> = {
        FREE: 'bg-gray-100 text-gray-700',
        PREMIUM: 'bg-amber-100 text-amber-700',
        ADMIN: 'bg-purple-100 text-purple-700',
      }
      return (
        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${colors[plan] || colors.FREE}`}>
          {plan || 'FREE'}
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
  {
    accessorKey: 'updated_at',
    header: 'Modifié le',
    cell: ({ row }) => {
      const date = row.getValue('updated_at') as string | null
      return (
        <span className="text-gray-500 text-xs">{safeFormatDate(date, 'dd/MM/yyyy HH:mm')}</span>
      )
    },
  },
]
