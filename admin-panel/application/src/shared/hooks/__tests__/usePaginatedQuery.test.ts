import { describe, it, expect, vi } from 'vitest'
import { renderHook, act, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import React from 'react'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'

function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })
  return ({ children }: { children: React.ReactNode }) =>
    React.createElement(QueryClientProvider, { client: queryClient }, children)
}

describe('usePaginatedQuery', () => {
  it('should have initial page of 1', () => {
    const queryFn = vi.fn().mockResolvedValue({ data: [] })
    const { result } = renderHook(
      () =>
        usePaginatedQuery({
          queryKey: ['test'],
          queryFn,
          enabled: true,
        }),
      { wrapper: createWrapper() }
    )

    expect(result.current.page).toBe(1)
  })

  it('should update page when setPage is called', async () => {
    const queryFn = vi.fn().mockResolvedValue({ data: [] })
    const { result } = renderHook(
      () =>
        usePaginatedQuery({
          queryKey: ['test'],
          queryFn,
          enabled: true,
        }),
      { wrapper: createWrapper() }
    )

    act(() => {
      result.current.setPage(3)
    })

    expect(result.current.page).toBe(3)
  })

  it('should call queryFn with correct params', async () => {
    const queryFn = vi.fn().mockResolvedValue({ data: [] })
    renderHook(
      () =>
        usePaginatedQuery({
          queryKey: ['test'],
          queryFn,
          enabled: true,
        }),
      { wrapper: createWrapper() }
    )

    await waitFor(() => {
      expect(queryFn).toHaveBeenCalledWith(
        expect.objectContaining({ page: 1, limit: expect.any(Number) })
      )
    })
  })

  it('should not fetch when enabled is false', async () => {
    const queryFn = vi.fn().mockResolvedValue({ data: [] })
    renderHook(
      () =>
        usePaginatedQuery({
          queryKey: ['test-disabled'],
          queryFn,
          enabled: false,
        }),
      { wrapper: createWrapper() }
    )

    // Give it a tick to ensure no call is made
    await new Promise((r) => setTimeout(r, 50))
    expect(queryFn).not.toHaveBeenCalled()
  })
})
