import { apiClient } from '@/lib/axios'
import { API_ENDPOINTS } from '@/utils/constants'
import type { HotelSearchResponse, HotelSearchCreateRequest, HotelOfferDetail } from '@/types'

export const hotelsService = {
  async searchHotels(tripId: string, data: HotelSearchCreateRequest): Promise<HotelSearchResponse> {
    const response = await apiClient.post<HotelSearchResponse>(
      API_ENDPOINTS.TRIPS.HOTEL_SEARCHES(tripId),
      data
    )
    return response.data
  },

  async getHotelOffer(tripId: string, offerId: string): Promise<HotelOfferDetail> {
    const response = await apiClient.get<HotelOfferDetail>(
      `/v1/trips/${tripId}/hotels/offers/${offerId}`
    )
    return response.data
  },
}
