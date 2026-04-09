'use client'

import { DataTable } from '@/components/DataTable'
import { feedbacksColumns } from '../columns'
import { useFeedbacksTab } from '../hooks'

export default function FeedbacksTab({ isActive }: { isActive: boolean }) {
  const { data, isLoading, setPage } = useFeedbacksTab({ enabled: isActive })

  return (
    <DataTable
      data={data?.items || []}
      columns={feedbacksColumns}
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
  )
}
