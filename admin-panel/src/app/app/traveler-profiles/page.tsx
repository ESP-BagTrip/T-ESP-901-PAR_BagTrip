'use client'

import { DataTable } from '@/components/DataTable'
import { DataTableToolbar, type FilterConfig } from '@/components/DataTableToolbar'
import { PageHeader } from '@/components/layout/PageHeader'
import { useProfilesTab } from '@/features/profiles/hooks'
import { profilesColumns } from '@/features/profiles/columns'

const FILTERS: FilterConfig[] = []

export default function TravelerProfilesPage() {
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
  } = useProfilesTab()

  return (
    <div>
      <PageHeader title="Profils voyageurs" description="Préférences de voyage des utilisateurs." />
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
        columns={profilesColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
