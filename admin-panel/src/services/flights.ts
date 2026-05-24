import { apiClient } from '@/lib/axios'
import { API_ENDPOINTS } from '@/utils/constants'
import type { FlightSearchResponse, FlightSearchCreateRequest, FlightOfferDetail } from '@/types'

export const flightsService = {
  async searchFlights(
    tripId: string,
    data: FlightSearchCreateRequest
  ): Promise<FlightSearchResponse> {
    const response = await apiClient.post<FlightSearchResponse>(
      API_ENDPOINTS.TRIPS.FLIGHT_SEARCHES(tripId),
      data
    )
    return response.data
  },

  async getFlightOffer(tripId: string, offerId: string): Promise<FlightOfferDetail> {
    const response = await apiClient.get<FlightOfferDetail>(
      `/v1/trips/${tripId}/flights/offers/${offerId}`
    )
    return response.data
  },

  async priceFlightOffer(tripId: string, offerId: string): Promise<FlightOfferDetail> {
    const response = await apiClient.post<FlightOfferDetail>(
      `/v1/trips/${tripId}/flights/offers/${offerId}/price`
    )
    return response.data
  },
}
