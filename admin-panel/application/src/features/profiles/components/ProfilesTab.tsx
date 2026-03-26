'use client'

import { DataTable } from '@/components/DataTable'
import { profilesColumns } from '../columns'
import { useProfilesTab } from '../hooks'

export default function ProfilesTab({ isActive }: { isActive: boolean }) {
  const { data, isLoading, setPage } = useProfilesTab({ enabled: isActive })

  return (
    <DataTable
      data={data?.items || []}
      columns={profilesColumns}
      isLoading={isLoading}
      pagination={
        data
          ? {
              page: data.page,
              limit: data.limit,
              total: data.total,
              total_pages: data.total_pages,
            }
          : undefined
      }
      onPaginationChange={(newPage) => setPage(newPage)}
    />
  )
}
