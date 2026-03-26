import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { PAGINATION_DEFAULTS } from '@/utils/constants'

interface UsePaginatedQueryOptions<TData> {
  queryKey: string[]
  queryFn: (params: { page: number; limit: number }) => Promise<TData>
  enabled?: boolean
}

export function usePaginatedQuery<TData>({
  queryKey,
  queryFn,
  enabled = true,
}: UsePaginatedQueryOptions<TData>) {
  const [page, setPage] = useState(1)

  const query = useQuery({
    queryKey: [...queryKey, page],
    queryFn: () => queryFn({ page, limit: PAGINATION_DEFAULTS.LIMIT }),
    enabled,
  })

  return {
    ...query,
    page,
    setPage,
  }
}
