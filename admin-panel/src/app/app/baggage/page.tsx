'use client'

import { DataTable } from '@/components/DataTable'
import { PageHeader } from '@/components/layout/PageHeader'
import { useBaggageItemsTab } from '@/features/baggage-items/hooks'
import { baggageItemsColumns } from '@/features/baggage-items/columns'

export default function BaggagePage() {
  const { rows, isLoading, page, limit, total, total_pages, setPage } = useBaggageItemsTab()

  return (
    <div>
      <PageHeader title="Bagages" description="Items de bagage par voyage." />
      <DataTable
        data={rows}
        columns={baggageItemsColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
