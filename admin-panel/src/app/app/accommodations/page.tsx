'use client'

import { DataTable } from '@/components/DataTable'
import { PageHeader } from '@/components/layout/PageHeader'
import { useAccommodationsTab } from '@/features/accommodations/hooks'
import { accommodationsColumns } from '@/features/accommodations/columns'

export default function AccommodationsPage() {
  const { rows, isLoading, page, limit, total, total_pages, setPage } = useAccommodationsTab()

  return (
    <div>
      <PageHeader title="Hébergements" description="Hébergements liés aux voyages." />
      <DataTable
        data={rows}
        columns={accommodationsColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
