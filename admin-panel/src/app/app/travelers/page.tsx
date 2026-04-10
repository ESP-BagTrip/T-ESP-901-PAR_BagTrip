'use client'

import { DataTable } from '@/components/DataTable'
import { DataTableToolbar, type FilterConfig } from '@/components/DataTableToolbar'
import { PageHeader } from '@/components/layout/PageHeader'
import { useTravelersTab } from '@/features/travelers/hooks'
import { travelersColumns } from '@/features/travelers/columns'

const FILTERS: FilterConfig[] = []

export default function TravelersPage() {
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
  } = useTravelersTab()

  return (
    <div>
      <PageHeader title="Voyageurs" description="Détails des voyageurs enregistrés." />
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
        columns={travelersColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
