'use client'

import { DataTable } from '@/components/DataTable'
import { usersColumns } from '../columns'
import { useUsersTab } from '../hooks'

export default function UsersTab({ isActive }: { isActive: boolean }) {
  const { data, isLoading, setPage } = useUsersTab({ enabled: isActive })

  return (
    <DataTable
      data={data?.data || []}
      columns={usersColumns}
      isLoading={isLoading}
      pagination={
        data?.pagination
          ? {
              page: data.pagination.page,
              limit: data.pagination.limit,
              total: data.pagination.total,
              total_pages: data.pagination.total_pages,
            }
          : undefined
      }
      onPaginationChange={(newPage) => setPage(newPage)}
    />
  )
}
