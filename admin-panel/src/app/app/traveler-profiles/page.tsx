'use client'

import { DataTable } from '@/components/DataTable'
import { PageHeader } from '@/components/layout/PageHeader'
import { useProfilesTab } from '@/features/profiles/hooks'
import { profilesColumns } from '@/features/profiles/columns'

export default function TravelerProfilesPage() {
  const { rows, isLoading, page, limit, total, total_pages, setPage } = useProfilesTab()

  return (
    <div>
      <PageHeader
        title="Profils voyageurs"
        description="Préférences de voyage déclarées par les utilisateurs."
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
