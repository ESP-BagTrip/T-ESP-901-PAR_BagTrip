import { describe, it, expect, vi, beforeEach } from 'vitest'
import { apiClient } from '@/lib/axios'
import { flightsService } from './flights'

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

describe('flightsService', () => {
  describe('searchFlights', () => {
    it('should POST /v1/trips/{tripId}/flights/searches with data and return response.data', async () => {
      const data = { origin: 'CDG', destination: 'JFK', date: '2024-06-01' }
      const mockResponse = { offers: [{ id: 'o1', price: 500 }] }
      mockPost.mockResolvedValue({ data: mockResponse })

      const result = await flightsService.searchFlights('t1', data as never)

      expect(mockPost).toHaveBeenCalledWith('/v1/trips/t1/flights/searches', data)
      expect(result).toEqual(mockResponse)
    })
  })

  describe('getFlightOffer', () => {
    it('should GET /v1/trips/{tripId}/flights/offers/{offerId} and return response.data', async () => {
      const mockOffer = { id: 'o1', price: 500, airline: 'AF' }
      mockGet.mockResolvedValue({ data: mockOffer })

      const result = await flightsService.getFlightOffer('t1', 'o1')

      expect(mockGet).toHaveBeenCalledWith('/v1/trips/t1/flights/offers/o1')
      expect(result).toEqual(mockOffer)
    })
  })

  describe('priceFlightOffer', () => {
    it('should POST /v1/trips/{tripId}/flights/offers/{offerId}/price and return response.data', async () => {
      const mockPriced = { id: 'o1', price: 520, confirmed: true }
      mockPost.mockResolvedValue({ data: mockPriced })

      const result = await flightsService.priceFlightOffer('t1', 'o1')

      expect(mockPost).toHaveBeenCalledWith('/v1/trips/t1/flights/offers/o1/price')
      expect(result).toEqual(mockPriced)
    })
  })
})
