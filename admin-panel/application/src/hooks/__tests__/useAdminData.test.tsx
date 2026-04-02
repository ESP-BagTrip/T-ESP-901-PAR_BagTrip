import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { type ReactNode } from 'react'
import {
  useAdminTrips,
  useAdminTravelers,
  useAdminFlightBookings,
  useAdminTravelerProfiles,
  useAdminBookingIntents,
  useAdminFlightSearches,
  useAdminAccommodations,
  useAdminBaggageItems,
  useAdminActivities,
  useAdminBudgetItems,
  useAdminTripShares,
  useAdminNotifications,
} from '../useAdminData'

const mockListResponse = { items: [], total: 0, page: 1, limit: 10, total_pages: 0 }

vi.mock('@/services', () => ({
  adminService: {
    getAllTrips: vi.fn().mockResolvedValue({ items: [], total: 0, page: 1, limit: 10, total_pages: 0 }),
    getAllTravelers: vi.fn().mockResolvedValue({ items: [], total: 0, page: 1, limit: 10, total_pages: 0 }),
    getAllFlightBookings: vi.fn().mockResolvedValue({ items: [], total: 0, page: 1, limit: 10, total_pages: 0 }),
    getAllTravelerProfiles: vi.fn().mockResolvedValue({ items: [], total: 0, page: 1, limit: 10, total_pages: 0 }),
    getAllBookingIntents: vi.fn().mockResolvedValue({ items: [], total: 0, page: 1, limit: 10, total_pages: 0 }),
    getAllFlightSearches: vi.fn().mockResolvedValue({ items: [], total: 0, page: 1, limit: 10, total_pages: 0 }),
    getAllAccommodations: vi.fn().mockResolvedValue({ items: [], total: 0, page: 1, limit: 10, total_pages: 0 }),
    getAllBaggageItems: vi.fn().mockResolvedValue({ items: [], total: 0, page: 1, limit: 10, total_pages: 0 }),
    getAllActivities: vi.fn().mockResolvedValue({ items: [], total: 0, page: 1, limit: 10, total_pages: 0 }),
    getAllBudgetItems: vi.fn().mockResolvedValue({ items: [], total: 0, page: 1, limit: 10, total_pages: 0 }),
    getAllTripShares: vi.fn().mockResolvedValue({ items: [], total: 0, page: 1, limit: 10, total_pages: 0 }),
    getAllNotifications: vi.fn().mockResolvedValue({ items: [], total: 0, page: 1, limit: 10, total_pages: 0 }),
  },
}))

function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  })
  return ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

describe('useAdminData hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('useAdminTrips returns data', async () => {
    const { result } = renderHook(() => useAdminTrips(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockListResponse)
  })

  it('useAdminTravelers returns data', async () => {
    const { result } = renderHook(() => useAdminTravelers(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockListResponse)
  })

  it('useAdminFlightBookings returns data', async () => {
    const { result } = renderHook(() => useAdminFlightBookings(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockListResponse)
  })

  it('useAdminTravelerProfiles returns data', async () => {
    const { result } = renderHook(() => useAdminTravelerProfiles(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockListResponse)
  })

  it('useAdminBookingIntents returns data', async () => {
    const { result } = renderHook(() => useAdminBookingIntents(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockListResponse)
  })

  it('useAdminFlightSearches returns data', async () => {
    const { result } = renderHook(() => useAdminFlightSearches(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockListResponse)
  })

  it('useAdminAccommodations returns data', async () => {
    const { result } = renderHook(() => useAdminAccommodations(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockListResponse)
  })

  it('useAdminBaggageItems returns data', async () => {
    const { result } = renderHook(() => useAdminBaggageItems(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockListResponse)
  })

  it('useAdminActivities returns data', async () => {
    const { result } = renderHook(() => useAdminActivities(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockListResponse)
  })

  it('useAdminBudgetItems returns data', async () => {
    const { result } = renderHook(() => useAdminBudgetItems(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockListResponse)
  })

  it('useAdminTripShares returns data', async () => {
    const { result } = renderHook(() => useAdminTripShares(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockListResponse)
  })

  it('useAdminNotifications returns data', async () => {
    const { result } = renderHook(() => useAdminNotifications(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(mockListResponse)
  })

  it('useAdminTrips passes custom params', async () => {
    const { adminService } = await import('@/services')
    const params = { page: 2, limit: 20 }
    const { result } = renderHook(() => useAdminTrips(params), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(adminService.getAllTrips).toHaveBeenCalledWith(
      expect.objectContaining({ page: 2, limit: 20 })
    )
  })
})
