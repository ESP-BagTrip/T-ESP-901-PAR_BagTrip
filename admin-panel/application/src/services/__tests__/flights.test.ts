import { describe, it, expect, vi, beforeEach } from 'vitest'
import { flightsService } from '@/services/flights'
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

describe('flightsService', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should call POST /v1/trips/:tripId/flights/searches on searchFlights', async () => {
    const searchData = { origin: 'CDG', destination: 'JFK', departureDate: '2024-06-01' }
    const mockResponse = { offers: [{ id: 'offer-1' }] }
    vi.mocked(apiClient.post).mockResolvedValue({ data: mockResponse })

    const result = await flightsService.searchFlights('trip-1', searchData as never)

    expect(apiClient.post).toHaveBeenCalledWith('/v1/trips/trip-1/flights/searches', searchData)
    expect(result).toEqual(mockResponse)
  })

  it('should call GET /v1/trips/:tripId/flights/offers/:offerId on getFlightOffer', async () => {
    const mockOffer = { id: 'offer-1', price: 500 }
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockOffer })

    const result = await flightsService.getFlightOffer('trip-1', 'offer-1')

    expect(apiClient.get).toHaveBeenCalledWith('/v1/trips/trip-1/flights/offers/offer-1')
    expect(result).toEqual(mockOffer)
  })

  it('should call POST /v1/trips/:tripId/flights/offers/:offerId/price on priceFlightOffer', async () => {
    const mockOffer = { id: 'offer-1', price: 550 }
    vi.mocked(apiClient.post).mockResolvedValue({ data: mockOffer })

    const result = await flightsService.priceFlightOffer('trip-1', 'offer-1')

    expect(apiClient.post).toHaveBeenCalledWith('/v1/trips/trip-1/flights/offers/offer-1/price')
    expect(result).toEqual(mockOffer)
  })
})
