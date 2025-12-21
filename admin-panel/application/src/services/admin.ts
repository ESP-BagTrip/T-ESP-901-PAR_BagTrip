import { apiClient } from '@/lib/axios'
import { API_ENDPOINTS } from '@/utils/constants'
import type {
  AdminFlightBooking,
  AdminHotelBooking,
  AdminListResponse,
  AdminTrip,
  AdminTraveler,
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
}
