'use client'

import { useCallback, useMemo, useState, useEffect } from 'react'
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

export interface PaginatedQueryParams {
  page: number
  limit: number
  q?: string
  [key: string]: string | number | undefined
}

interface UsePaginatedQueryOptions<T> {
  queryKey: readonly unknown[]
  queryFn: (params: PaginatedQueryParams) => Promise<RawPaginated<T>>
  defaultLimit?: number
  /** Extra filter keys to sync with URL (e.g. ['status', 'plan']). */
  filterKeys?: string[]
}

/**
 * Paginated query backed by URL search params.
 * Supports: ?page=N, ?q=search, ?status=X, ?plan=Y, etc.
 */
export function usePaginatedQuery<T>({
  queryKey,
  queryFn,
  defaultLimit,
  filterKeys = [],
}: UsePaginatedQueryOptions<T>) {
  const router = useRouter()
  const pathname = usePathname()
  const searchParams = useSearchParams()

  // Debounced search: local state for immediate input, URL for queries
  const urlSearch = searchParams?.get('q') ?? ''
  const [searchInput, setSearchInput] = useState(urlSearch)

  // Sync local input when URL changes externally (back/forward)
  useEffect(() => {
    setSearchInput(urlSearch)
  }, [urlSearch])

  // Debounce search → URL
  useEffect(() => {
    const timer = setTimeout(() => {
      if (searchInput !== urlSearch) {
        updateParams({ q: searchInput || undefined, page: undefined })
      }
    }, 300)
    return () => clearTimeout(timer)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchInput])

  const page = useMemo(() => {
    const raw = Number(searchParams?.get('page'))
    return Number.isFinite(raw) && raw >= 1 ? Math.floor(raw) : 1
  }, [searchParams])

  const limit = useMemo(() => {
    const raw = Number(searchParams?.get('limit'))
    if (Number.isFinite(raw) && raw >= 1) return Math.floor(raw)
    return defaultLimit ?? PAGINATION_DEFAULTS.LIMIT
  }, [searchParams, defaultLimit])

  const filters = useMemo(() => {
    const f: Record<string, string | undefined> = {}
    for (const key of filterKeys) {
      f[key] = searchParams?.get(key) ?? undefined
    }
    return f
  }, [searchParams, filterKeys])

  // Build full query params for the API call
  const apiParams = useMemo<PaginatedQueryParams>(() => {
    const p: PaginatedQueryParams = { page, limit }
    if (urlSearch) p.q = urlSearch
    for (const [k, v] of Object.entries(filters)) {
      if (v) p[k] = v
    }
    return p
  }, [page, limit, urlSearch, filters])

  const query = useQuery({
    queryKey: [...queryKey, apiParams],
    queryFn: () => queryFn(apiParams),
  })

  const normalized = useMemo(() => normalize<T>(query.data, limit), [query.data, limit])

  const updateParams = useCallback(
    (updates: Record<string, string | number | undefined>) => {
      const params = new URLSearchParams(searchParams?.toString() ?? '')
      for (const [key, value] of Object.entries(updates)) {
        if (value == null || value === '' || (key === 'page' && Number(value) <= 1)) {
          params.delete(key)
        } else {
          params.set(key, String(value))
        }
      }
      const q = params.toString()
      router.replace(q ? `${pathname}?${q}` : (pathname ?? ''), { scroll: false })
    },
    [pathname, router, searchParams]
  )

  const setPage = useCallback((next: number) => updateParams({ page: next }), [updateParams])

  const setFilter = useCallback(
    (key: string, value: string | undefined) => updateParams({ [key]: value, page: undefined }),
    [updateParams]
  )

  const resetFilters = useCallback(() => {
    const clears: Record<string, undefined> = { q: undefined, page: undefined }
    for (const key of filterKeys) {
      clears[key] = undefined
    }
    updateParams(clears)
    setSearchInput('')
  }, [updateParams, filterKeys])

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
    // Search
    search: searchInput,
    setSearch: setSearchInput,
    // Filters
    filters,
    setFilter,
    resetFilters,
  }
}
