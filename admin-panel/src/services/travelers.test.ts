import { describe, it, expect, vi, beforeEach } from 'vitest'
import { apiClient } from '@/lib/axios'
import { travelersService } from './travelers'

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

describe('travelersService', () => {
  describe('createTraveler', () => {
    it('should POST /v1/trips/{tripId}/travelers with data and return response.data', async () => {
      const data = { first_name: 'John', last_name: 'Doe' }
      const mockTraveler = { id: 'tr1', ...data }
      mockPost.mockResolvedValue({ data: mockTraveler })

      const result = await travelersService.createTraveler('t1', data as never)

      expect(mockPost).toHaveBeenCalledWith('/v1/trips/t1/travelers', data)
      expect(result).toEqual(mockTraveler)
    })
  })

  describe('listTravelers', () => {
    it('should GET /v1/trips/{tripId}/travelers and return response.data', async () => {
      const mockList = { travelers: [{ id: 'tr1' }] }
      mockGet.mockResolvedValue({ data: mockList })

      const result = await travelersService.listTravelers('t1')

      expect(mockGet).toHaveBeenCalledWith('/v1/trips/t1/travelers')
      expect(result).toEqual(mockList)
    })
  })
})
