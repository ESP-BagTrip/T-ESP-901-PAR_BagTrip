import { http } from '../../config/http';
import { env } from '../../config/env';
import { logger } from '../../utils/logger';
import { fetchToken } from './amadeus.auth';
import { HotelBookingRequest, HotelBookingResponse } from './amadeus.types';

/**
 * Hotel Booking: POST /v2/booking/hotel-orders
 * Creates a hotel booking with guest and payment information.
 */
export async function createHotelBooking(
  booking: HotelBookingRequest
): Promise<HotelBookingResponse> {
  logger.debug('Starting hotel booking creation', { booking });
  const token = await fetchToken();

  const url = `${env.AMADEUS_BASE_URL}/v2/booking/hotel-orders`;

  try {
    logger.info('Making Amadeus hotel booking request', { url });
    const res = await http.post(url, booking, {
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      timeout: 30000, // 30 seconds for booking creation
    });

    logger.debug('Amadeus hotel booking response', {
      status: res.status,
      statusText: res.statusText,
    });

    const response: HotelBookingResponse = {
      data: res.data?.data ?? [],
      meta: res.data?.meta,
    };

    logger.info('Hotel booking completed successfully', {
      bookingId: response.data?.[0]?.id,
    });
    return response;
  } catch (error: any) {
    logger.error('Amadeus hotel booking failed', {
      message: error.message,
      code: error.code,
      response: error.response?.data,
      status: error.response?.status,
    });
    const err: any = new Error('Amadeus hotel booking failed');
    err.detail = error.response?.data || error.message;
    err.status = error.response?.status || (error.code === 'ECONNABORTED' ? 504 : 502);
    throw err;
  }
}
