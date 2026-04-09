'use client'

import { DataTable } from '@/components/DataTable'
import { PageHeader } from '@/components/layout/PageHeader'
import { useNotificationsTab } from '@/features/notifications/hooks'
import { notificationsColumns } from '@/features/notifications/columns'

export default function NotificationsPage() {
  const { rows, isLoading, page, limit, total, total_pages, setPage } = useNotificationsTab()

  return (
    <div>
      <PageHeader
        title="Notifications"
        description="Notifications push envoyées aux utilisateurs."
      />
      <DataTable
        data={rows}
        columns={notificationsColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
