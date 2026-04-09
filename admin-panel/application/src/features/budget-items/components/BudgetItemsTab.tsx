'use client'

import { DataTable } from '@/components/DataTable'
import { budgetItemsColumns } from '../columns'
import { useBudgetItemsTab } from '../hooks'

export default function BudgetItemsTab({ isActive }: { isActive: boolean }) {
  const { data, isLoading, setPage } = useBudgetItemsTab({ enabled: isActive })

  return (
    <DataTable
      data={data?.items || []}
      columns={budgetItemsColumns}
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
