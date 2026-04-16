import { apiClient } from '@/lib/axios'
import { API_ENDPOINTS } from '@/utils/constants'
import type { Traveler, TravelerCreateRequest, TravelerListResponse } from '@/types'

export const travelersService = {
  async createTraveler(tripId: string, data: TravelerCreateRequest): Promise<Traveler> {
    const response = await apiClient.post<Traveler>(API_ENDPOINTS.TRIPS.TRAVELERS(tripId), data)
    return response.data
  },

  async listTravelers(tripId: string): Promise<TravelerListResponse> {
    const response = await apiClient.get<TravelerListResponse>(
      API_ENDPOINTS.TRIPS.TRAVELERS(tripId)
    )
    return response.data
  },
}
