'use client'

import { DataTable } from '@/components/DataTable'
import { DataTableToolbar } from '@/components/DataTableToolbar'
import { PageHeader } from '@/components/layout/PageHeader'
import { useTripsTab } from '@/features/trips/hooks'
import { tripsColumns } from '@/features/trips/columns'

const FILTERS = [
  {
    key: 'status',
    label: 'Statut',
    options: [
      { value: 'DRAFT', label: 'Draft' },
      { value: 'PLANNED', label: 'Planned' },
      { value: 'ONGOING', label: 'En cours' },
      { value: 'COMPLETED', label: 'Terminé' },
    ],
  },
]

export default function TripsPage() {
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
  } = useTripsTab()

  return (
    <div>
      <PageHeader title="Voyages" description="Tous les voyages créés sur la plateforme." />
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
        columns={tripsColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
