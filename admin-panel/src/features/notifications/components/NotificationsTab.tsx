'use client'

import { useState } from 'react'
import { DataTable } from '@/components/DataTable'
import { Button } from '@/components/ui/button'
import { notificationsColumns } from '../columns'
import { useNotificationsTab } from '../hooks'
import { SendNotificationModal } from './SendNotificationModal'

export default function NotificationsTab({ isActive }: { isActive: boolean }) {
  const { data, isLoading, setPage } = useNotificationsTab({ enabled: isActive })
  const [showModal, setShowModal] = useState(false)

  return (
    <div>
      <div className="flex justify-end mb-4">
        <Button onClick={() => setShowModal(true)}>Envoyer une notification</Button>
      </div>

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
        onPaginationChange={newPage => setPage(newPage)}
      />

      <SendNotificationModal open={showModal} onClose={() => setShowModal(false)} />
    </div>
  )
}
