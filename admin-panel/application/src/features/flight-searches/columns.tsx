import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminFlightSearch } from '@/types'

export const flightSearchesColumns: ColumnDef<AdminFlightSearch>[] = [
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
    accessorKey: 'origin_iata',
    header: 'Origine',
    cell: ({ row }) => (
      <span className="font-semibold text-gray-900">{row.getValue('origin_iata')}</span>
    ),
  },
  {
    accessorKey: 'destination_iata',
    header: 'Destination',
    cell: ({ row }) => (
      <span className="font-semibold text-gray-900">{row.getValue('destination_iata')}</span>
    ),
  },
  {
    accessorKey: 'departure_date',
    header: 'Départ',
    cell: ({ row }) => {
      const date = row.getValue('departure_date') as string | null
      return <span className="text-gray-900">{safeFormatDate(date, 'dd/MM/yyyy')}</span>
    },
  },
  {
    accessorKey: 'return_date',
    header: 'Retour',
    cell: ({ row }) => {
      const date = row.getValue('return_date') as string | null
      return <span className="text-gray-900">{safeFormatDate(date, 'dd/MM/yyyy')}</span>
    },
  },
  {
    accessorKey: 'adults',
    header: 'Adultes',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('adults')}</span>,
  },
  {
    accessorKey: 'children',
    header: 'Enfants',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('children') ?? '—'}</span>,
  },
  {
    accessorKey: 'travel_class',
    header: 'Classe',
    cell: ({ row }) => (
      <span className="text-gray-900">{row.getValue('travel_class') || '—'}</span>
    ),
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
