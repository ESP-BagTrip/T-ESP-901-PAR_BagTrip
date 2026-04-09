'use client'

import { DataTable } from '@/components/DataTable'
import { PageHeader } from '@/components/layout/PageHeader'
import { useTripsTab } from '@/features/trips/hooks'
import { tripsColumns } from '@/features/trips/columns'

export default function TripsPage() {
  const { rows, isLoading, page, limit, total, total_pages, setPage } = useTripsTab()

  return (
    <div>
      <PageHeader title="Voyages" description="Tous les voyages créés sur la plateforme." />
      <DataTable
        data={rows}
        columns={tripsColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
