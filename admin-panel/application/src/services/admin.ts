import { apiClient } from '@/lib/axios'
import { API_ENDPOINTS } from '@/utils/constants'
import type {
  AdminAccommodation,
  AdminActivity,
  AdminBaggageItem,
  AdminBookingIntent,
  AdminBudgetItem,
  AdminFlightBooking,
  AdminFlightSearch,
  AdminListResponse,
  AdminNotification,
  AdminTrip,
  AdminTraveler,
  AdminTravelerProfile,
  AdminTripShare,
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

  async getAllBookingIntents(params?: QueryParams): Promise<AdminListResponse<AdminBookingIntent>> {
    const response = await apiClient.get<AdminListResponse<AdminBookingIntent>>(
      API_ENDPOINTS.ADMIN.BOOKING_INTENTS,
      { params }
    )
    return response.data
  },

  async getAllFlightSearches(params?: QueryParams): Promise<AdminListResponse<AdminFlightSearch>> {
    const response = await apiClient.get<AdminListResponse<AdminFlightSearch>>(
      API_ENDPOINTS.ADMIN.FLIGHT_SEARCHES,
      { params }
    )
    return response.data
  },

  async getAllAccommodations(params?: QueryParams): Promise<AdminListResponse<AdminAccommodation>> {
    const response = await apiClient.get<AdminListResponse<AdminAccommodation>>(
      API_ENDPOINTS.ADMIN.ACCOMMODATIONS,
      { params }
    )
    return response.data
  },

  async getAllBaggageItems(params?: QueryParams): Promise<AdminListResponse<AdminBaggageItem>> {
    const response = await apiClient.get<AdminListResponse<AdminBaggageItem>>(
      API_ENDPOINTS.ADMIN.BAGGAGE_ITEMS,
      { params }
    )
    return response.data
  },

  async getAllActivities(params?: QueryParams): Promise<AdminListResponse<AdminActivity>> {
    const response = await apiClient.get<AdminListResponse<AdminActivity>>(
      API_ENDPOINTS.ADMIN.ACTIVITIES,
      { params }
    )
    return response.data
  },

  async getAllBudgetItems(params?: QueryParams): Promise<AdminListResponse<AdminBudgetItem>> {
    const response = await apiClient.get<AdminListResponse<AdminBudgetItem>>(
      API_ENDPOINTS.ADMIN.BUDGET_ITEMS,
      { params }
    )
    return response.data
  },

  async getAllTripShares(params?: QueryParams): Promise<AdminListResponse<AdminTripShare>> {
    const response = await apiClient.get<AdminListResponse<AdminTripShare>>(
      API_ENDPOINTS.ADMIN.TRIP_SHARES,
      { params }
    )
    return response.data
  },

  async getAllNotifications(params?: QueryParams): Promise<AdminListResponse<AdminNotification>> {
    const response = await apiClient.get<AdminListResponse<AdminNotification>>(
      API_ENDPOINTS.ADMIN.NOTIFICATIONS,
      { params }
    )
    return response.data
  },

  async updateUserPlan(userId: string, plan: string): Promise<void> {
    await apiClient.patch(`${API_ENDPOINTS.USERS}/${userId}/plan`, { plan })
  },

  async sendNotification(payload: {
    user_ids: string[]
    title: string
    body: string
    type?: string
    trip_id?: string | null
  }): Promise<{ message: string; count: number }> {
    const response = await apiClient.post(API_ENDPOINTS.ADMIN.NOTIFICATIONS_SEND, payload)
    return response.data
  },
}
