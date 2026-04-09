'use client'

import { DataTable } from '@/components/DataTable'
import { tripSharesColumns } from '../columns'
import { useTripSharesTab } from '../hooks'

export default function TripSharesTab({ isActive }: { isActive: boolean }) {
  const { data, isLoading, setPage } = useTripSharesTab({ enabled: isActive })

  return (
    <DataTable
      data={data?.items || []}
      columns={tripSharesColumns}
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
