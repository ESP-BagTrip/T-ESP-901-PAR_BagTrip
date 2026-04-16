import { apiClient } from '@/lib/axios'
import { API_ENDPOINTS } from '@/utils/constants'
import type { Trip, TripCreateRequest, TripListResponse, TripDetailResponse } from '@/types'

export const tripsService = {
  async createTrip(data: TripCreateRequest): Promise<Trip> {
    const response = await apiClient.post<Trip>(API_ENDPOINTS.TRIPS.BASE, data)
    return response.data
  },

  async listTrips(): Promise<TripListResponse> {
    const response = await apiClient.get<TripListResponse>(API_ENDPOINTS.TRIPS.BASE)
    return response.data
  },

  async getTrip(tripId: string): Promise<TripDetailResponse> {
    const response = await apiClient.get<TripDetailResponse>(API_ENDPOINTS.TRIPS.BY_ID(tripId))
    return response.data
  },
}
