'use client'

import { DataTable } from '@/components/DataTable'
import { DataTableToolbar, type FilterConfig } from '@/components/DataTableToolbar'
import { PageHeader } from '@/components/layout/PageHeader'
import { useTripSharesTab } from '@/features/trip-shares/hooks'
import { tripSharesColumns } from '@/features/trip-shares/columns'

const FILTERS: FilterConfig[] = []

export default function TripSharesPage() {
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
  } = useTripSharesTab()

  return (
    <div>
      <PageHeader title="Partages de voyage" description="Invitations de collaboration." />
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
        columns={tripSharesColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
