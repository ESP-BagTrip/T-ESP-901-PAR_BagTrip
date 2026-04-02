import { describe, it, expect, vi, beforeEach } from 'vitest'
import { bookingIntentsService } from '@/services/booking-intents'
import { apiClient } from '@/lib/axios'

vi.mock('@/lib/axios', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}))

describe('bookingIntentsService', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should call POST /v1/trips/:tripId/booking-intents on createBookingIntent', async () => {
    const intentData = { type: 'flight', offer_id: 'offer-1' }
    const mockIntent = { id: 'intent-1', ...intentData }
    vi.mocked(apiClient.post).mockResolvedValue({ data: mockIntent })

    const result = await bookingIntentsService.createBookingIntent('trip-1', intentData as never)

    expect(apiClient.post).toHaveBeenCalledWith('/v1/trips/trip-1/booking-intents', intentData)
    expect(result).toEqual(mockIntent)
  })

  it('should call GET /v1/booking-intents/:id on getBookingIntent', async () => {
    const mockIntent = { id: 'intent-1', status: 'pending' }
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockIntent })

    const result = await bookingIntentsService.getBookingIntent('intent-1')

    expect(apiClient.get).toHaveBeenCalledWith('/v1/booking-intents/intent-1')
    expect(result).toEqual(mockIntent)
  })

  it('should call POST /v1/booking-intents/:id/book on bookFlight', async () => {
    const bookData = { travelers: [{ id: 'trav-1' }] }
    const mockResponse = { booking: { id: 'booking-1' } }
    vi.mocked(apiClient.post).mockResolvedValue({ data: mockResponse })

    const result = await bookingIntentsService.bookFlight('intent-1', bookData as never)

    expect(apiClient.post).toHaveBeenCalledWith('/v1/booking-intents/intent-1/book', bookData)
    expect(result).toEqual(mockResponse)
  })

  it('should call POST /v1/booking-intents/:id/book on bookHotel', async () => {
    const bookData = { guests: [{ name: 'John' }] }
    const mockResponse = { booking: { id: 'booking-2' } }
    vi.mocked(apiClient.post).mockResolvedValue({ data: mockResponse })

    const result = await bookingIntentsService.bookHotel('intent-2', bookData as never)

    expect(apiClient.post).toHaveBeenCalledWith('/v1/booking-intents/intent-2/book', bookData)
    expect(result).toEqual(mockResponse)
  })
})
