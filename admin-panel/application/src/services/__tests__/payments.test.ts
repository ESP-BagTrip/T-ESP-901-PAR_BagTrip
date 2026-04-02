import { describe, it, expect, vi, beforeEach } from 'vitest'
import { paymentsService } from '@/services/payments'
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

describe('paymentsService', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should call POST /v1/booking-intents/:id/payment/authorize on authorizePayment', async () => {
    const paymentData = { card_number: '4111111111111111' }
    const mockResponse = { status: 'authorized' }
    vi.mocked(apiClient.post).mockResolvedValue({ data: mockResponse })

    const result = await paymentsService.authorizePayment('intent-1', paymentData as never)

    expect(apiClient.post).toHaveBeenCalledWith(
      '/v1/booking-intents/intent-1/payment/authorize',
      paymentData
    )
    expect(result).toEqual(mockResponse)
  })

  it('should call POST /v1/booking-intents/:id/payment/capture on capturePayment', async () => {
    const mockResponse = { status: 'captured' }
    vi.mocked(apiClient.post).mockResolvedValue({ data: mockResponse })

    const result = await paymentsService.capturePayment('intent-1')

    expect(apiClient.post).toHaveBeenCalledWith(
      '/v1/booking-intents/intent-1/payment/capture'
    )
    expect(result).toEqual(mockResponse)
  })

  it('should call POST /v1/booking-intents/:id/payment/cancel on cancelPayment', async () => {
    const mockResponse = { bookingIntent: { id: 'intent-1', status: 'cancelled' } }
    vi.mocked(apiClient.post).mockResolvedValue({ data: mockResponse })

    const result = await paymentsService.cancelPayment('intent-1')

    expect(apiClient.post).toHaveBeenCalledWith(
      '/v1/booking-intents/intent-1/payment/cancel'
    )
    expect(result).toEqual(mockResponse)
  })

  it('should call POST /v1/booking-intents/:id/payment/confirm-test on confirmPaymentTest', async () => {
    const mockResponse = { status: 'confirmed' }
    vi.mocked(apiClient.post).mockResolvedValue({ data: mockResponse })

    const result = await paymentsService.confirmPaymentTest('intent-1')

    expect(apiClient.post).toHaveBeenCalledWith(
      '/v1/booking-intents/intent-1/payment/confirm-test'
    )
    expect(result).toEqual(mockResponse)
  })
})
