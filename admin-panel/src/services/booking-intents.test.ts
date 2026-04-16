import { describe, it, expect, vi, beforeEach } from 'vitest'
import { apiClient } from '@/lib/axios'
import { bookingIntentsService } from './booking-intents'

vi.mock('@/lib/axios', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}))

const mockGet = vi.mocked(apiClient.get)
const mockPost = vi.mocked(apiClient.post)

beforeEach(() => {
  vi.clearAllMocks()
})

describe('bookingIntentsService', () => {
  describe('createBookingIntent', () => {
    it('should POST /v1/trips/{tripId}/booking-intents with data and return response.data', async () => {
      const data = { offer_id: 'o1', type: 'flight' }
      const mockIntent = { id: 'bi1', status: 'created', ...data }
      mockPost.mockResolvedValue({ data: mockIntent })

      const result = await bookingIntentsService.createBookingIntent('t1', data as never)

      expect(mockPost).toHaveBeenCalledWith('/v1/trips/t1/booking-intents', data)
      expect(result).toEqual(mockIntent)
    })
  })

  describe('getBookingIntent', () => {
    it('should GET /v1/booking-intents/{intentId} and return response.data', async () => {
      const mockIntent = { id: 'bi1', status: 'pending' }
      mockGet.mockResolvedValue({ data: mockIntent })

      const result = await bookingIntentsService.getBookingIntent('bi1')

      expect(mockGet).toHaveBeenCalledWith('/v1/booking-intents/bi1')
      expect(result).toEqual(mockIntent)
    })
  })

  describe('bookFlight', () => {
    it('should POST /v1/booking-intents/{intentId}/book with data and return response.data', async () => {
      const data = { travelers: [{ id: 'tr1' }] }
      const mockResponse = { id: 'bi1', status: 'booked', pnr: 'ABC123' }
      mockPost.mockResolvedValue({ data: mockResponse })

      const result = await bookingIntentsService.bookFlight('bi1', data as never)

      expect(mockPost).toHaveBeenCalledWith('/v1/booking-intents/bi1/book', data)
      expect(result).toEqual(mockResponse)
    })
  })
})
