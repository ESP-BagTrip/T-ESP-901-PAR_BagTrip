import { describe, it, expect, vi, beforeEach } from 'vitest'
import { apiClient } from '@/lib/axios'
import { tripsService } from './trips'

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

describe('tripsService', () => {
  describe('createTrip', () => {
    it('should POST /v1/trips with data and return response.data', async () => {
      const data = { name: 'Paris Trip', destination: 'Paris' }
      const mockTrip = { id: 't1', ...data }
      mockPost.mockResolvedValue({ data: mockTrip })

      const result = await tripsService.createTrip(data as never)

      expect(mockPost).toHaveBeenCalledWith('/v1/trips', data)
      expect(result).toEqual(mockTrip)
    })
  })

  describe('listTrips', () => {
    it('should GET /v1/trips and return response.data', async () => {
      const mockList = { trips: [{ id: 't1' }] }
      mockGet.mockResolvedValue({ data: mockList })

      const result = await tripsService.listTrips()

      expect(mockGet).toHaveBeenCalledWith('/v1/trips')
      expect(result).toEqual(mockList)
    })
  })

  describe('getTrip', () => {
    it('should GET /v1/trips/{tripId} and return response.data', async () => {
      const mockTrip = { id: 't1', name: 'Paris Trip' }
      mockGet.mockResolvedValue({ data: mockTrip })

      const result = await tripsService.getTrip('t1')

      expect(mockGet).toHaveBeenCalledWith('/v1/trips/t1')
      expect(result).toEqual(mockTrip)
    })
  })
})
