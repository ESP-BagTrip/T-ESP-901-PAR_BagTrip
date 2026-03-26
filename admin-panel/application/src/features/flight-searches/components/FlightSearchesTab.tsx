'use client'

import { DataTable } from '@/components/DataTable'
import { flightSearchesColumns } from '../columns'
import { useFlightSearchesTab } from '../hooks'

export default function FlightSearchesTab({ isActive }: { isActive: boolean }) {
  const { data, isLoading, setPage } = useFlightSearchesTab({ enabled: isActive })

  return (
    <DataTable
      data={data?.items || []}
      columns={flightSearchesColumns}
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
      onPaginationChange={(newPage) => setPage(newPage)}
    />
  )
}
