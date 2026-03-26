'use client'

import { DataTable } from '@/components/DataTable'
import { accommodationsColumns } from '../columns'
import { useAccommodationsTab } from '../hooks'

export default function AccommodationsTab({ isActive }: { isActive: boolean }) {
  const { data, isLoading, setPage } = useAccommodationsTab({ enabled: isActive })

  return (
    <DataTable
      data={data?.items || []}
      columns={accommodationsColumns}
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
