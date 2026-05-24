import { apiClient } from '@/lib/axios'
import { API_ENDPOINTS } from '@/utils/constants'
import type {
  PaymentAuthorizeRequest,
  PaymentAuthorizeResponse,
  PaymentCaptureResponse,
} from '@/types'

export const paymentsService = {
  async authorizePayment(
    intentId: string,
    data: PaymentAuthorizeRequest
  ): Promise<PaymentAuthorizeResponse> {
    const response = await apiClient.post<PaymentAuthorizeResponse>(
      API_ENDPOINTS.BOOKING_INTENTS.PAYMENT_AUTHORIZE(intentId),
      data
    )
    return response.data
  },

  async capturePayment(intentId: string): Promise<PaymentCaptureResponse> {
    const response = await apiClient.post<PaymentCaptureResponse>(
      API_ENDPOINTS.BOOKING_INTENTS.PAYMENT_CAPTURE(intentId)
    )
    return response.data
  },

  async cancelPayment(intentId: string): Promise<{ bookingIntent: Record<string, unknown> }> {
    const response = await apiClient.post<{ bookingIntent: Record<string, unknown> }>(
      API_ENDPOINTS.BOOKING_INTENTS.PAYMENT_CANCEL(intentId)
    )
    return response.data
  },

  async confirmPaymentTest(intentId: string): Promise<PaymentAuthorizeResponse> {
    const response = await apiClient.post<PaymentAuthorizeResponse>(
      API_ENDPOINTS.BOOKING_INTENTS.PAYMENT_CONFIRM_TEST(intentId)
    )
    return response.data
  },
}
