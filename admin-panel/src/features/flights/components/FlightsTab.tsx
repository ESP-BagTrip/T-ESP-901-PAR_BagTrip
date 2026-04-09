'use client'

import { DataTable } from '@/components/DataTable'
import { flightBookingsColumns } from '../columns'
import { useFlightsTab } from '../hooks'

export default function FlightsTab({ isActive }: { isActive: boolean }) {
  const { data, isLoading, setPage } = useFlightsTab({ enabled: isActive })

  return (
    <DataTable
      data={data?.items || []}
      columns={flightBookingsColumns}
      isLoading={isLoading}
      pagination={
        data
          ? {
              page: data.page,
              limit: data.limit,
              total: data.total,
              total_pages: data.total_pages,
            }
          : undefined
      }
      onPaginationChange={newPage => setPage(newPage)}
    />
  )
}
