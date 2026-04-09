'use client'

import { DataTable } from '@/components/DataTable'
import { PageHeader } from '@/components/layout/PageHeader'
import { useBudgetItemsTab } from '@/features/budget-items/hooks'
import { budgetItemsColumns } from '@/features/budget-items/columns'

export default function BudgetPage() {
  const { rows, isLoading, page, limit, total, total_pages, setPage } = useBudgetItemsTab()

  return (
    <div>
      <PageHeader title="Budget" description="Lignes de budget et dépenses planifiées." />
      <DataTable
        data={rows}
        columns={budgetItemsColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
