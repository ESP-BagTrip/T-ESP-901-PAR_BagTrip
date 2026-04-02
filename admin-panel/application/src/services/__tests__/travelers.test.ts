import { describe, it, expect, vi, beforeEach } from 'vitest'
import { travelersService } from '@/services/travelers'
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

describe('travelersService', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should call POST /v1/trips/:tripId/travelers on createTraveler', async () => {
    const travelerData = { first_name: 'John', last_name: 'Doe' }
    const mockTraveler = { id: 'trav-1', ...travelerData }
    vi.mocked(apiClient.post).mockResolvedValue({ data: mockTraveler })

    const result = await travelersService.createTraveler('trip-1', travelerData as never)

    expect(apiClient.post).toHaveBeenCalledWith('/v1/trips/trip-1/travelers', travelerData)
    expect(result).toEqual(mockTraveler)
  })

  it('should call GET /v1/trips/:tripId/travelers on listTravelers', async () => {
    const mockResponse = { travelers: [{ id: 'trav-1' }] }
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockResponse })

    const result = await travelersService.listTravelers('trip-1')

    expect(apiClient.get).toHaveBeenCalledWith('/v1/trips/trip-1/travelers')
    expect(result).toEqual(mockResponse)
  })
})
