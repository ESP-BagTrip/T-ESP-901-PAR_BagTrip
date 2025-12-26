import { apiClient } from '@/lib/axios'
import { API_ENDPOINTS } from '@/utils/constants'
import type {
  BookingIntent,
  BookingIntentCreateRequest,
  BookingIntentBookRequestFlight,
  BookingIntentBookRequestHotel,
  BookingIntentBookResponse,
} from '@/types'

export const bookingIntentsService = {
  async createBookingIntent(
    tripId: string,
    data: BookingIntentCreateRequest
  ): Promise<BookingIntent> {
    const response = await apiClient.post<BookingIntent>(
      API_ENDPOINTS.TRIPS.BOOKING_INTENTS(tripId),
      data
    )
    return response.data
  },

  async getBookingIntent(intentId: string): Promise<BookingIntent> {
    const response = await apiClient.get<BookingIntent>(
      API_ENDPOINTS.BOOKING_INTENTS.BY_ID(intentId)
    )
    return response.data
  },

  async bookFlight(
    intentId: string,
    data: BookingIntentBookRequestFlight
  ): Promise<BookingIntentBookResponse> {
    const response = await apiClient.post<BookingIntentBookResponse>(
      API_ENDPOINTS.BOOKING_INTENTS.BOOK(intentId),
      data
    )
    return response.data
  },

  async bookHotel(
    intentId: string,
    data: BookingIntentBookRequestHotel
  ): Promise<BookingIntentBookResponse> {
    const response = await apiClient.post<BookingIntentBookResponse>(
      API_ENDPOINTS.BOOKING_INTENTS.BOOK(intentId),
      data
    )
    return response.data
  },
}
