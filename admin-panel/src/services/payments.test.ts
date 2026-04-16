import { describe, it, expect, vi, beforeEach } from 'vitest'
import { apiClient } from '@/lib/axios'
import { paymentsService } from './payments'

vi.mock('@/lib/axios', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}))

const mockPost = vi.mocked(apiClient.post)

beforeEach(() => {
  vi.clearAllMocks()
})

describe('paymentsService', () => {
  describe('authorizePayment', () => {
    it('should POST /v1/booking-intents/{intentId}/payment/authorize with data and return response.data', async () => {
      const data = { card_token: 'tok_123' }
      const mockResponse = { id: 'pay1', status: 'authorized', client_secret: 'cs_123' }
      mockPost.mockResolvedValue({ data: mockResponse })

      const result = await paymentsService.authorizePayment('bi1', data as never)

      expect(mockPost).toHaveBeenCalledWith('/v1/booking-intents/bi1/payment/authorize', data)
      expect(result).toEqual(mockResponse)
    })
  })

  describe('capturePayment', () => {
    it('should POST /v1/booking-intents/{intentId}/payment/capture and return response.data', async () => {
      const mockResponse = { id: 'pay1', status: 'captured' }
      mockPost.mockResolvedValue({ data: mockResponse })

      const result = await paymentsService.capturePayment('bi1')

      expect(mockPost).toHaveBeenCalledWith('/v1/booking-intents/bi1/payment/capture')
      expect(result).toEqual(mockResponse)
    })
  })

  describe('cancelPayment', () => {
    it('should POST /v1/booking-intents/{intentId}/payment/cancel and return response.data', async () => {
      const mockResponse = { bookingIntent: { id: 'bi1', status: 'cancelled' } }
      mockPost.mockResolvedValue({ data: mockResponse })

      const result = await paymentsService.cancelPayment('bi1')

      expect(mockPost).toHaveBeenCalledWith('/v1/booking-intents/bi1/payment/cancel')
      expect(result).toEqual(mockResponse)
    })
  })

  describe('confirmPaymentTest', () => {
    it('should POST /v1/booking-intents/{intentId}/payment/confirm-test and return response.data', async () => {
      const mockResponse = { id: 'pay1', status: 'confirmed' }
      mockPost.mockResolvedValue({ data: mockResponse })

      const result = await paymentsService.confirmPaymentTest('bi1')

      expect(mockPost).toHaveBeenCalledWith('/v1/booking-intents/bi1/payment/confirm-test')
      expect(result).toEqual(mockResponse)
    })
  })
})
