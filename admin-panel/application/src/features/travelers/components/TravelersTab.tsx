'use client'

import { DataTable } from '@/components/DataTable'
import { travelersColumns } from '../columns'
import { useTravelersTab } from '../hooks'

export default function TravelersTab({ isActive }: { isActive: boolean }) {
  const { data, isLoading, setPage } = useTravelersTab({ enabled: isActive })

  return (
    <DataTable
      data={data?.items || []}
      columns={travelersColumns}
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
