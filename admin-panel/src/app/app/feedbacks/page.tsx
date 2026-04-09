'use client'

import { DataTable } from '@/components/DataTable'
import { PageHeader } from '@/components/layout/PageHeader'
import { useFeedbacksTab } from '@/features/feedbacks/hooks'
import { feedbacksColumns } from '@/features/feedbacks/columns'

export default function FeedbacksPage() {
  const { rows, isLoading, page, limit, total, total_pages, setPage } = useFeedbacksTab()

  return (
    <div>
      <PageHeader title="Retours" description="Notes et commentaires post-voyage." />
      <DataTable
        data={rows}
        columns={feedbacksColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
