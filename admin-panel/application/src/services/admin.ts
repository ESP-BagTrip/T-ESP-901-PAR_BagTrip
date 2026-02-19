import { apiClient } from '@/lib/axios'
import { API_ENDPOINTS } from '@/utils/constants'
import type {
  AdminBookingIntent,
  AdminConversation,
  AdminFlightBooking,
  AdminFlightSearch,
  AdminHotelBooking,
  AdminHotelSearch,
  AdminListResponse,
  AdminTrip,
  AdminTraveler,
  AdminTravelerProfile,
  QueryParams,
} from '@/types'

export const adminService = {
  async getAllTrips(params?: QueryParams): Promise<AdminListResponse<AdminTrip>> {
    const response = await apiClient.get<AdminListResponse<AdminTrip>>(API_ENDPOINTS.ADMIN.TRIPS, {
      params,
    })
    return response.data
  },

  async getAllTravelers(params?: QueryParams): Promise<AdminListResponse<AdminTraveler>> {
    const response = await apiClient.get<AdminListResponse<AdminTraveler>>(
      API_ENDPOINTS.ADMIN.TRAVELERS,
      { params }
    )
    return response.data
  },

  async getAllHotelBookings(params?: QueryParams): Promise<AdminListResponse<AdminHotelBooking>> {
    const response = await apiClient.get<AdminListResponse<AdminHotelBooking>>(
      API_ENDPOINTS.ADMIN.HOTEL_BOOKINGS,
      { params }
    )
    return response.data
  },

  async getAllFlightBookings(params?: QueryParams): Promise<AdminListResponse<AdminFlightBooking>> {
    const response = await apiClient.get<AdminListResponse<AdminFlightBooking>>(
      API_ENDPOINTS.ADMIN.FLIGHT_BOOKINGS,
      { params }
    )
    return response.data
  },

  async getAllTravelerProfiles(
    params?: QueryParams
  ): Promise<AdminListResponse<AdminTravelerProfile>> {
    const response = await apiClient.get<AdminListResponse<AdminTravelerProfile>>(
      API_ENDPOINTS.ADMIN.TRAVELER_PROFILES,
      { params }
    )
    return response.data
  },

  async getAllBookingIntents(
    params?: QueryParams
  ): Promise<AdminListResponse<AdminBookingIntent>> {
    const response = await apiClient.get<AdminListResponse<AdminBookingIntent>>(
      API_ENDPOINTS.ADMIN.BOOKING_INTENTS,
      { params }
    )
    return response.data
  },

  async getAllConversations(
    params?: QueryParams
  ): Promise<AdminListResponse<AdminConversation>> {
    const response = await apiClient.get<AdminListResponse<AdminConversation>>(
      API_ENDPOINTS.ADMIN.CONVERSATIONS,
      { params }
    )
    return response.data
  },

  async getAllFlightSearches(
    params?: QueryParams
  ): Promise<AdminListResponse<AdminFlightSearch>> {
    const response = await apiClient.get<AdminListResponse<AdminFlightSearch>>(
      API_ENDPOINTS.ADMIN.FLIGHT_SEARCHES,
      { params }
    )
    return response.data
  },

  async getAllHotelSearches(
    params?: QueryParams
  ): Promise<AdminListResponse<AdminHotelSearch>> {
    const response = await apiClient.get<AdminListResponse<AdminHotelSearch>>(
      API_ENDPOINTS.ADMIN.HOTEL_SEARCHES,
      { params }
    )
    return response.data
  },
}
