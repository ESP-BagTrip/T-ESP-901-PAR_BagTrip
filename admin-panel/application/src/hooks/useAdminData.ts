import { useQuery } from '@tanstack/react-query'
import { adminService } from '@/services'
import { PAGINATION_DEFAULTS } from '@/utils/constants'
import type { QueryParams } from '@/types'

export function useAdminTrips(params?: QueryParams) {
  return useQuery({
    queryKey: ['admin', 'trips', params],
    queryFn: () =>
      adminService.getAllTrips({
        page: params?.page || PAGINATION_DEFAULTS.PAGE,
        limit: params?.limit || PAGINATION_DEFAULTS.LIMIT,
        ...params,
      }),
  })
}

export function useAdminTravelers(params?: QueryParams) {
  return useQuery({
    queryKey: ['admin', 'travelers', params],
    queryFn: () =>
      adminService.getAllTravelers({
        page: params?.page || PAGINATION_DEFAULTS.PAGE,
        limit: params?.limit || PAGINATION_DEFAULTS.LIMIT,
        ...params,
      }),
  })
}

export function useAdminHotelBookings(params?: QueryParams) {
  return useQuery({
    queryKey: ['admin', 'hotel-bookings', params],
    queryFn: () =>
      adminService.getAllHotelBookings({
        page: params?.page || PAGINATION_DEFAULTS.PAGE,
        limit: params?.limit || PAGINATION_DEFAULTS.LIMIT,
        ...params,
      }),
  })
}

export function useAdminFlightBookings(params?: QueryParams) {
  return useQuery({
    queryKey: ['admin', 'flight-bookings', params],
    queryFn: () =>
      adminService.getAllFlightBookings({
        page: params?.page || PAGINATION_DEFAULTS.PAGE,
        limit: params?.limit || PAGINATION_DEFAULTS.LIMIT,
        ...params,
      }),
  })
}

export function useAdminTravelerProfiles(params?: QueryParams) {
  return useQuery({
    queryKey: ['admin', 'traveler-profiles', params],
    queryFn: () =>
      adminService.getAllTravelerProfiles({
        page: params?.page || PAGINATION_DEFAULTS.PAGE,
        limit: params?.limit || PAGINATION_DEFAULTS.LIMIT,
        ...params,
      }),
  })
}

export function useAdminBookingIntents(params?: QueryParams) {
  return useQuery({
    queryKey: ['admin', 'booking-intents', params],
    queryFn: () =>
      adminService.getAllBookingIntents({
        page: params?.page || PAGINATION_DEFAULTS.PAGE,
        limit: params?.limit || PAGINATION_DEFAULTS.LIMIT,
        ...params,
      }),
  })
}

export function useAdminConversations(params?: QueryParams) {
  return useQuery({
    queryKey: ['admin', 'conversations', params],
    queryFn: () =>
      adminService.getAllConversations({
        page: params?.page || PAGINATION_DEFAULTS.PAGE,
        limit: params?.limit || PAGINATION_DEFAULTS.LIMIT,
        ...params,
      }),
  })
}

export function useAdminFlightSearches(params?: QueryParams) {
  return useQuery({
    queryKey: ['admin', 'flight-searches', params],
    queryFn: () =>
      adminService.getAllFlightSearches({
        page: params?.page || PAGINATION_DEFAULTS.PAGE,
        limit: params?.limit || PAGINATION_DEFAULTS.LIMIT,
        ...params,
      }),
  })
}

export function useAdminHotelSearches(params?: QueryParams) {
  return useQuery({
    queryKey: ['admin', 'hotel-searches', params],
    queryFn: () =>
      adminService.getAllHotelSearches({
        page: params?.page || PAGINATION_DEFAULTS.PAGE,
        limit: params?.limit || PAGINATION_DEFAULTS.LIMIT,
        ...params,
      }),
  })
}
