'use client'

import { DataTable } from '@/components/DataTable'
import { PageHeader } from '@/components/layout/PageHeader'
import { useBookingIntentsTab } from '@/features/booking-intents/hooks'
import { bookingIntentsColumns } from '@/features/booking-intents/columns'

export default function BookingIntentsPage() {
  const { rows, isLoading, page, limit, total, total_pages, setPage } = useBookingIntentsTab()

  return (
    <div>
      <PageHeader title="Intentions de paiement" description="Funnel Stripe booking intents." />
      <DataTable
        data={rows}
        columns={bookingIntentsColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
