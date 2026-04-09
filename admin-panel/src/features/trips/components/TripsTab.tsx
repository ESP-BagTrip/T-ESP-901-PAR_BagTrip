'use client'

import { DataTable } from '@/components/DataTable'
import { tripsColumns } from '../columns'
import { useTripsTab } from '../hooks'

export default function TripsTab({ isActive }: { isActive: boolean }) {
  const { data, isLoading, setPage } = useTripsTab({ enabled: isActive })

  return (
    <DataTable
      data={data?.items || []}
      columns={tripsColumns}
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
