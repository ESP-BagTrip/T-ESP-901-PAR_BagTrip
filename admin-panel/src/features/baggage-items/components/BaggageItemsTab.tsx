'use client'

import { DataTable } from '@/components/DataTable'
import { baggageItemsColumns } from '../columns'
import { useBaggageItemsTab } from '../hooks'

export default function BaggageItemsTab({ isActive }: { isActive: boolean }) {
  const { data, isLoading, setPage } = useBaggageItemsTab({ enabled: isActive })

  return (
    <DataTable
      data={data?.items || []}
      columns={baggageItemsColumns}
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
