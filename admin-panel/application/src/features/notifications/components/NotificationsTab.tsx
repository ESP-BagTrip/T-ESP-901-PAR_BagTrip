'use client'

import { DataTable } from '@/components/DataTable'
import { notificationsColumns } from '../columns'
import { useNotificationsTab } from '../hooks'

export default function NotificationsTab({ isActive }: { isActive: boolean }) {
  const { data, isLoading, setPage } = useNotificationsTab({ enabled: isActive })

  return (
    <DataTable
      data={data?.items || []}
      columns={notificationsColumns}
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
