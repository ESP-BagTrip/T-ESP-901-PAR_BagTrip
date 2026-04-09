'use client'

import { DataTable } from '@/components/DataTable'
import { PageHeader } from '@/components/layout/PageHeader'
import { useFlightSearchesTab } from '@/features/flight-searches/hooks'
import { flightSearchesColumns } from '@/features/flight-searches/columns'

export default function FlightSearchesPage() {
  const { rows, isLoading, page, limit, total, total_pages, setPage } = useFlightSearchesTab()

  return (
    <div>
      <PageHeader title="Recherches vols" description="Historique des recherches Amadeus." />
      <DataTable
        data={rows}
        columns={flightSearchesColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
