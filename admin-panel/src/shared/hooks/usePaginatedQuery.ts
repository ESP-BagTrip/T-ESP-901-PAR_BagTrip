'use client'

import { useCallback, useMemo } from 'react'
import { usePathname, useRouter, useSearchParams } from 'next/navigation'
import { useQuery } from '@tanstack/react-query'

import { PAGINATION_DEFAULTS } from '@/utils/constants'

/**
 * Supported backend response shapes:
 *  - PaginatedResponse<T>: { data: T[], pagination: { page, limit, total, total_pages } }
 *  - AdminListResponse<T>: { items: T[], page, limit, total, total_pages }
 */
export interface RawPaginated<T> {
  data?: T[]
  items?: T[]
  total?: number
  page?: number
  limit?: number
  total_pages?: number
  pagination?: {
    page: number
    limit: number
    total: number
    total_pages: number
  }
}

function normalize<T>(raw: RawPaginated<T> | undefined, fallbackLimit: number) {
  if (!raw) {
    return { rows: [] as T[], page: 1, limit: fallbackLimit, total: 0, total_pages: 0 }
  }
  if (raw.pagination) {
    return {
      rows: raw.data ?? [],
      page: raw.pagination.page,
      limit: raw.pagination.limit,
      total: raw.pagination.total,
      total_pages: raw.pagination.total_pages,
    }
  }
  return {
    rows: raw.items ?? raw.data ?? [],
    page: raw.page ?? 1,
    limit: raw.limit ?? fallbackLimit,
    total: raw.total ?? 0,
    total_pages: raw.total_pages ?? 0,
  }
}

interface UsePaginatedQueryOptions<T> {
  queryKey: readonly unknown[]
  queryFn: (params: { page: number; limit: number }) => Promise<RawPaginated<T>>
  defaultLimit?: number
}

/**
 * Paginated query backed by URL search params (?page=N).
 * Generic over the row item type T.
 */
export function usePaginatedQuery<T>({
  queryKey,
  queryFn,
  defaultLimit,
}: UsePaginatedQueryOptions<T>) {
  const router = useRouter()
  const pathname = usePathname()
  const searchParams = useSearchParams()

  const page = useMemo(() => {
    const raw = Number(searchParams?.get('page'))
    return Number.isFinite(raw) && raw >= 1 ? Math.floor(raw) : 1
  }, [searchParams])

  const limit = useMemo(() => {
    const raw = Number(searchParams?.get('limit'))
    if (Number.isFinite(raw) && raw >= 1) return Math.floor(raw)
    return defaultLimit ?? PAGINATION_DEFAULTS.LIMIT
  }, [searchParams, defaultLimit])

  const query = useQuery({
    queryKey: [...queryKey, { page, limit }],
    queryFn: () => queryFn({ page, limit }),
  })

  const normalized = useMemo(() => normalize<T>(query.data, limit), [query.data, limit])

  const setPage = useCallback(
    (next: number) => {
      const params = new URLSearchParams(searchParams?.toString() ?? '')
      if (next <= 1) {
        params.delete('page')
      } else {
        params.set('page', String(next))
      }
      const q = params.toString()
      router.replace(q ? `${pathname}?${q}` : (pathname ?? ''), { scroll: false })
    },
    [pathname, router, searchParams]
  )

  return {
    isLoading: query.isLoading,
    isError: query.isError,
    error: query.error,
    refetch: query.refetch,
    rows: normalized.rows,
    page: normalized.page,
    limit: normalized.limit,
    total: normalized.total,
    total_pages: normalized.total_pages,
    setPage,
  }
}
