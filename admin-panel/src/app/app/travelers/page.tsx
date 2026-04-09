'use client'

import { DataTable } from '@/components/DataTable'
import { PageHeader } from '@/components/layout/PageHeader'
import { useTravelersTab } from '@/features/travelers/hooks'
import { travelersColumns } from '@/features/travelers/columns'

export default function TravelersPage() {
  const { rows, isLoading, page, limit, total, total_pages, setPage } = useTravelersTab()

  return (
    <div>
      <PageHeader
        title="Voyageurs"
        description="Détails des voyageurs enregistrés pour chaque voyage."
      />
      <DataTable
        data={rows}
        columns={travelersColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
