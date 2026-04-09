'use client'

import { DataTable } from '@/components/DataTable'
import { PageHeader } from '@/components/layout/PageHeader'
import { useFlightsTab } from '@/features/flights/hooks'
import { flightBookingsColumns } from '@/features/flights/columns'

export default function FlightBookingsPage() {
  const { rows, isLoading, page, limit, total, total_pages, setPage } = useFlightsTab()

  return (
    <div>
      <PageHeader title="Réservations vols" description="Commandes Amadeus finalisées." />
      <DataTable
        data={rows}
        columns={flightBookingsColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
