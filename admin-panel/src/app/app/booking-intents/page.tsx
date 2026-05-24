'use client'

import { DataTable } from '@/components/DataTable'
import { DataTableToolbar } from '@/components/DataTableToolbar'
import { PageHeader } from '@/components/layout/PageHeader'
import { useBookingIntentsTab } from '@/features/booking-intents/hooks'
import { bookingIntentsColumns } from '@/features/booking-intents/columns'

const FILTERS = [
  {
    key: 'status',
    label: 'Statut',
    options: [
      { value: 'INIT', label: 'Init' },
      { value: 'CAPTURED', label: 'Captured' },
      { value: 'FAILED', label: 'Failed' },
      { value: 'CANCELLED', label: 'Cancelled' },
    ],
  },
]

export default function BookingIntentsPage() {
  const {
    rows,
    isLoading,
    page,
    limit,
    total,
    total_pages,
    setPage,
    search,
    setSearch,
    filters,
    setFilter,
    resetFilters,
  } = useBookingIntentsTab()

  return (
    <div>
      <PageHeader title="Intentions de paiement" description="Funnel Stripe booking intents." />
      <DataTableToolbar
        searchValue={search}
        onSearch={setSearch}
        searchPlaceholder="Rechercher…"
        filters={FILTERS}
        activeFilters={filters}
        onFilterChange={setFilter}
        onReset={resetFilters}
      />
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
