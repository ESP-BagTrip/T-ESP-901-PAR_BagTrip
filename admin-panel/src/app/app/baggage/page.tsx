'use client'

import { DataTable } from '@/components/DataTable'
import { DataTableToolbar, type FilterConfig } from '@/components/DataTableToolbar'
import { PageHeader } from '@/components/layout/PageHeader'
import { useBaggageItemsTab } from '@/features/baggage-items/hooks'
import { baggageItemsColumns } from '@/features/baggage-items/columns'

const FILTERS: FilterConfig[] = []

export default function BaggagePage() {
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
  } = useBaggageItemsTab()

  return (
    <div>
      <PageHeader title="Bagages" description="Items de bagage par voyage." />
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
        columns={baggageItemsColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
