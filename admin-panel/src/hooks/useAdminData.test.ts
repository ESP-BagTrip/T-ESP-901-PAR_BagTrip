import { describe, it, expect, vi, beforeEach } from 'vitest'
import { renderHook } from '@testing-library/react'
import { useQuery } from '@tanstack/react-query'
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
} from './useAdminData'

vi.mock('@tanstack/react-query', () => ({
  useQuery: vi.fn(() => ({
    data: undefined,
    isLoading: false,
    isError: false,
    error: null,
  })),
}))

vi.mock('@/services', () => ({
  adminService: {
    getAllTrips: vi.fn(),
    getAllTravelers: vi.fn(),
    getAllFlightBookings: vi.fn(),
    getAllTravelerProfiles: vi.fn(),
    getAllBookingIntents: vi.fn(),
    getAllFlightSearches: vi.fn(),
    getAllAccommodations: vi.fn(),
    getAllBaggageItems: vi.fn(),
    getAllActivities: vi.fn(),
    getAllBudgetItems: vi.fn(),
    getAllTripShares: vi.fn(),
    getAllNotifications: vi.fn(),
  },
}))

vi.mock('@/utils/constants', () => ({
  PAGINATION_DEFAULTS: {
    PAGE: 1,
    LIMIT: 10,
  },
}))

describe('useAdminData hooks', () => {
  beforeEach(() => {
    vi.mocked(useQuery).mockClear()
  })

  const params = { page: 1, limit: 20 }

  it('useAdminTrips uses correct queryKey', () => {
    useAdminTrips(params)
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'trips', params],
      })
    )
  })

  it('useAdminTravelers uses correct queryKey', () => {
    useAdminTravelers(params)
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'travelers', params],
      })
    )
  })

  it('useAdminFlightBookings uses correct queryKey', () => {
    useAdminFlightBookings(params)
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'flight-bookings', params],
      })
    )
  })

  it('useAdminTravelerProfiles uses correct queryKey', () => {
    useAdminTravelerProfiles(params)
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'traveler-profiles', params],
      })
    )
  })

  it('useAdminBookingIntents uses correct queryKey', () => {
    useAdminBookingIntents(params)
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'booking-intents', params],
      })
    )
  })

  it('useAdminFlightSearches uses correct queryKey', () => {
    useAdminFlightSearches(params)
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'flight-searches', params],
      })
    )
  })

  it('useAdminAccommodations uses correct queryKey', () => {
    useAdminAccommodations(params)
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'accommodations', params],
      })
    )
  })

  it('useAdminBaggageItems uses correct queryKey', () => {
    useAdminBaggageItems(params)
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'baggage-items', params],
      })
    )
  })

  it('useAdminActivities uses correct queryKey', () => {
    useAdminActivities(params)
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'activities', params],
      })
    )
  })

  it('useAdminBudgetItems uses correct queryKey', () => {
    useAdminBudgetItems(params)
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'budgetItems', params],
      })
    )
  })

  it('useAdminTripShares uses correct queryKey', () => {
    useAdminTripShares(params)
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'trip-shares', params],
      })
    )
  })

  it('useAdminNotifications uses correct queryKey', () => {
    useAdminNotifications(params)
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'notifications', params],
      })
    )
  })

  it('useAdminTrips passes undefined params when none provided', () => {
    useAdminTrips()
    expect(useQuery).toHaveBeenCalledWith(
      expect.objectContaining({
        queryKey: ['admin', 'trips', undefined],
      })
    )
  })

  /* ---- queryFn verification: each hook calls the right admin service method ---- */

  it('useAdminTrips queryFn calls adminService.getAllTrips with merged pagination', async () => {
    const { adminService } = await import('@/services')
    renderHook(() => useAdminTrips({ page: 2, limit: 5 }))
    const opts = vi.mocked(useQuery).mock.calls[0][0]
    opts.queryFn!({} as never)
    expect(adminService.getAllTrips).toHaveBeenCalledWith(
      expect.objectContaining({ page: 2, limit: 5 })
    )
  })

  it('useAdminTravelers queryFn calls adminService.getAllTravelers', async () => {
    const { adminService } = await import('@/services')
    renderHook(() => useAdminTravelers())
    const opts = vi.mocked(useQuery).mock.calls[0][0]
    opts.queryFn!({} as never)
    expect(adminService.getAllTravelers).toHaveBeenCalledWith(
      expect.objectContaining({ page: 1, limit: 10 })
    )
  })

  it('useAdminFlightBookings queryFn calls adminService.getAllFlightBookings', async () => {
    const { adminService } = await import('@/services')
    renderHook(() => useAdminFlightBookings())
    const opts = vi.mocked(useQuery).mock.calls[0][0]
    opts.queryFn!({} as never)
    expect(adminService.getAllFlightBookings).toHaveBeenCalledWith(
      expect.objectContaining({ page: 1, limit: 10 })
    )
  })

  it('useAdminTravelerProfiles queryFn calls adminService.getAllTravelerProfiles', async () => {
    const { adminService } = await import('@/services')
    renderHook(() => useAdminTravelerProfiles())
    const opts = vi.mocked(useQuery).mock.calls[0][0]
    opts.queryFn!({} as never)
    expect(adminService.getAllTravelerProfiles).toHaveBeenCalledWith(
      expect.objectContaining({ page: 1, limit: 10 })
    )
  })

  it('useAdminBookingIntents queryFn calls adminService.getAllBookingIntents', async () => {
    const { adminService } = await import('@/services')
    renderHook(() => useAdminBookingIntents())
    const opts = vi.mocked(useQuery).mock.calls[0][0]
    opts.queryFn!({} as never)
    expect(adminService.getAllBookingIntents).toHaveBeenCalledWith(
      expect.objectContaining({ page: 1, limit: 10 })
    )
  })

  it('useAdminFlightSearches queryFn calls adminService.getAllFlightSearches', async () => {
    const { adminService } = await import('@/services')
    renderHook(() => useAdminFlightSearches())
    const opts = vi.mocked(useQuery).mock.calls[0][0]
    opts.queryFn!({} as never)
    expect(adminService.getAllFlightSearches).toHaveBeenCalledWith(
      expect.objectContaining({ page: 1, limit: 10 })
    )
  })

  it('useAdminAccommodations queryFn calls adminService.getAllAccommodations', async () => {
    const { adminService } = await import('@/services')
    renderHook(() => useAdminAccommodations())
    const opts = vi.mocked(useQuery).mock.calls[0][0]
    opts.queryFn!({} as never)
    expect(adminService.getAllAccommodations).toHaveBeenCalledWith(
      expect.objectContaining({ page: 1, limit: 10 })
    )
  })

  it('useAdminBaggageItems queryFn calls adminService.getAllBaggageItems', async () => {
    const { adminService } = await import('@/services')
    renderHook(() => useAdminBaggageItems())
    const opts = vi.mocked(useQuery).mock.calls[0][0]
    opts.queryFn!({} as never)
    expect(adminService.getAllBaggageItems).toHaveBeenCalledWith(
      expect.objectContaining({ page: 1, limit: 10 })
    )
  })

  it('useAdminActivities queryFn calls adminService.getAllActivities', async () => {
    const { adminService } = await import('@/services')
    renderHook(() => useAdminActivities())
    const opts = vi.mocked(useQuery).mock.calls[0][0]
    opts.queryFn!({} as never)
    expect(adminService.getAllActivities).toHaveBeenCalledWith(
      expect.objectContaining({ page: 1, limit: 10 })
    )
  })

  it('useAdminBudgetItems queryFn calls adminService.getAllBudgetItems', async () => {
    const { adminService } = await import('@/services')
    renderHook(() => useAdminBudgetItems())
    const opts = vi.mocked(useQuery).mock.calls[0][0]
    opts.queryFn!({} as never)
    expect(adminService.getAllBudgetItems).toHaveBeenCalledWith(
      expect.objectContaining({ page: 1, limit: 10 })
    )
  })

  it('useAdminTripShares queryFn calls adminService.getAllTripShares', async () => {
    const { adminService } = await import('@/services')
    renderHook(() => useAdminTripShares())
    const opts = vi.mocked(useQuery).mock.calls[0][0]
    opts.queryFn!({} as never)
    expect(adminService.getAllTripShares).toHaveBeenCalledWith(
      expect.objectContaining({ page: 1, limit: 10 })
    )
  })

  it('useAdminNotifications queryFn calls adminService.getAllNotifications', async () => {
    const { adminService } = await import('@/services')
    renderHook(() => useAdminNotifications())
    const opts = vi.mocked(useQuery).mock.calls[0][0]
    opts.queryFn!({} as never)
    expect(adminService.getAllNotifications).toHaveBeenCalledWith(
      expect.objectContaining({ page: 1, limit: 10 })
    )
  })

  /* ---- renderHook return value ---- */

  it('returns data from useQuery via renderHook', () => {
    vi.mocked(useQuery).mockReturnValueOnce({
      data: { items: [], total: 0 },
      isLoading: false,
      isError: false,
      error: null,
    } as ReturnType<typeof useQuery>)

    const { result } = renderHook(() => useAdminTrips())
    expect(result.current.data).toEqual({ items: [], total: 0 })
  })

  /* ---- undefined params fall back to PAGINATION_DEFAULTS ---- */

  it('useAdminTravelers queryFn uses default page when params.page is undefined', async () => {
    const { adminService } = await import('@/services')
    renderHook(() => useAdminTravelers({ search: 'john' } as never))
    const opts = vi.mocked(useQuery).mock.calls[0][0]
    opts.queryFn!({} as never)
    expect(adminService.getAllTravelers).toHaveBeenCalledWith(
      expect.objectContaining({ page: 1, limit: 10, search: 'john' })
    )
  })
})
