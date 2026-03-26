'use client'

import { DataTable } from '@/components/DataTable'
import { activitiesColumns } from '../columns'
import { useActivitiesTab } from '../hooks'

export default function ActivitiesTab({ isActive }: { isActive: boolean }) {
  const { data, isLoading, setPage } = useActivitiesTab({ enabled: isActive })

  return (
    <DataTable
      data={data?.items || []}
      columns={activitiesColumns}
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
