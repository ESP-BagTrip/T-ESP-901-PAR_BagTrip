import { describe, it, expect, vi, beforeEach } from 'vitest'
import { tripsService } from '@/services/trips'
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

describe('tripsService', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should call POST /v1/trips on createTrip', async () => {
    const tripData = { name: 'Paris Trip', destination: 'Paris' }
    const mockTrip = { id: '1', ...tripData }
    vi.mocked(apiClient.post).mockResolvedValue({ data: mockTrip })

    const result = await tripsService.createTrip(tripData as never)

    expect(apiClient.post).toHaveBeenCalledWith('/v1/trips', tripData)
    expect(result).toEqual(mockTrip)
  })

  it('should call GET /v1/trips on listTrips', async () => {
    const mockResponse = { trips: [{ id: '1' }] }
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockResponse })

    const result = await tripsService.listTrips()

    expect(apiClient.get).toHaveBeenCalledWith('/v1/trips')
    expect(result).toEqual(mockResponse)
  })

  it('should call GET /v1/trips/:id on getTrip', async () => {
    const mockTrip = { id: 'trip-1', name: 'Paris' }
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockTrip })

    const result = await tripsService.getTrip('trip-1')

    expect(apiClient.get).toHaveBeenCalledWith('/v1/trips/trip-1')
    expect(result).toEqual(mockTrip)
  })
})
