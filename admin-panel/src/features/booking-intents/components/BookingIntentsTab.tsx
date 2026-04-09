'use client'

import { DataTable } from '@/components/DataTable'
import { bookingIntentsColumns } from '../columns'
import { useBookingIntentsTab } from '../hooks'

export default function BookingIntentsTab({ isActive }: { isActive: boolean }) {
  const { data, isLoading, setPage } = useBookingIntentsTab({ enabled: isActive })

  return (
    <DataTable
      data={data?.items || []}
      columns={bookingIntentsColumns}
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
