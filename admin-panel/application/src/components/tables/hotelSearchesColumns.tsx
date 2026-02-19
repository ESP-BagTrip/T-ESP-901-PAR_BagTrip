import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminHotelSearch } from '@/types'

export const hotelSearchesColumns: ColumnDef<AdminHotelSearch>[] = [
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
    accessorKey: 'city_code',
    header: 'Ville',
    cell: ({ row }) => (
      <span className="font-semibold text-gray-900">{row.getValue('city_code') || '—'}</span>
    ),
  },
  {
    accessorKey: 'check_in',
    header: 'Check-in',
    cell: ({ row }) => {
      const date = row.getValue('check_in') as string | null
      return <span className="text-gray-900">{safeFormatDate(date, 'dd/MM/yyyy')}</span>
    },
  },
  {
    accessorKey: 'check_out',
    header: 'Check-out',
    cell: ({ row }) => {
      const date = row.getValue('check_out') as string | null
      return <span className="text-gray-900">{safeFormatDate(date, 'dd/MM/yyyy')}</span>
    },
  },
  {
    accessorKey: 'adults',
    header: 'Adultes',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('adults')}</span>,
  },
  {
    accessorKey: 'room_qty',
    header: 'Chambres',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('room_qty')}</span>,
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
