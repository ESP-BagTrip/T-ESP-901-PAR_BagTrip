'use client'

import { DataTable } from '@/components/DataTable'
import { PageHeader } from '@/components/layout/PageHeader'
import { useTripSharesTab } from '@/features/trip-shares/hooks'
import { tripSharesColumns } from '@/features/trip-shares/columns'

export default function TripSharesPage() {
  const { rows, isLoading, page, limit, total, total_pages, setPage } = useTripSharesTab()

  return (
    <div>
      <PageHeader
        title="Partages de voyage"
        description="Invitations de collaboration sur les voyages."
      />
      <DataTable
        data={rows}
        columns={tripSharesColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
