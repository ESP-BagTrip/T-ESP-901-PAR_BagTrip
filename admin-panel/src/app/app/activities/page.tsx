'use client'

import { DataTable } from '@/components/DataTable'
import { PageHeader } from '@/components/layout/PageHeader'
import { useActivitiesTab } from '@/features/activities/hooks'
import { activitiesColumns } from '@/features/activities/columns'

export default function ActivitiesPage() {
  const { rows, isLoading, page, limit, total, total_pages, setPage } = useActivitiesTab()

  return (
    <div>
      <PageHeader title="Activités" description="Activités planifiées par les voyageurs." />
      <DataTable
        data={rows}
        columns={activitiesColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
