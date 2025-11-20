import { amadeusClient } from '../../integrations/amadeus/amadeus.client';
import { CreateHotelBookingParams, HotelBookingResult } from './booking.types';
import { AppError } from '../../utils/errors';
import {
  HotelBookingRequest,
  HotelBookingResponse,
} from '../../integrations/amadeus/amadeus.types';

/**
 * Create a hotel booking.
 */
export async function createHotelBooking(
  params: CreateHotelBookingParams
): Promise<HotelBookingResult> {
  // Validate guests
  if (!params.guests || params.guests.length === 0) {
    throw new AppError('INVALID_REQUEST', 400, 'At least one guest is required');
  }

  for (const guest of params.guests) {
    if (!guest.title || !guest.firstName || !guest.lastName || !guest.phone || !guest.email) {
      throw new AppError(
        'INVALID_REQUEST',
        400,
        'Each guest must have title, firstName, lastName, phone, and email'
      );
    }
  }

  // Validate room associations
  if (!params.roomAssociations || params.roomAssociations.length === 0) {
    throw new AppError('INVALID_REQUEST', 400, 'At least one room association is required');
  }

  for (const roomAssoc of params.roomAssociations) {
    if (!roomAssoc.hotelOfferId) {
      throw new AppError('INVALID_REQUEST', 400, 'hotelOfferId is required in room associations');
    }
    if (!roomAssoc.guestReferences || roomAssoc.guestReferences.length === 0) {
      throw new AppError(
        'INVALID_REQUEST',
        400,
        'At least one guest reference is required in room associations'
      );
    }
  }

  // Validate payment
  if (!params.payment) {
    throw new AppError('INVALID_REQUEST', 400, 'Payment information is required');
  }

  if (
    !params.payment.vendorCode ||
    !params.payment.cardNumber ||
    !params.payment.expiryDate ||
    !params.payment.holderName
  ) {
    throw new AppError(
      'INVALID_REQUEST',
      400,
      'Payment must include vendorCode, cardNumber, expiryDate, and holderName'
    );
  }

  // Build the Amadeus booking request
  const bookingRequest: HotelBookingRequest = {
    data: {
      type: 'hotel-order',
      guests: params.guests.map((guest) => ({
        tid: guest.tid,
        title: guest.title,
        firstName: guest.firstName,
        lastName: guest.lastName,
        phone: guest.phone,
        email: guest.email,
      })),
      roomAssociations: params.roomAssociations.map((roomAssoc) => ({
        guestReferences: roomAssoc.guestReferences.map((ref) => ({ guestReference: ref })),
        hotelOfferId: roomAssoc.hotelOfferId,
      })),
      payment: {
        method: 'CREDIT_CARD',
        paymentCard: {
          paymentCardInfo: {
            vendorCode: params.payment.vendorCode,
            cardNumber: params.payment.cardNumber,
            expiryDate: params.payment.expiryDate,
            holderName: params.payment.holderName,
          },
        },
      },
    },
  };

  // Add travel agent email if provided
  if (params.travelAgentEmail) {
    bookingRequest.data.travelAgent = {
      contact: {
        email: params.travelAgentEmail,
      },
    };
  }

  const result = (await amadeusClient.createHotelBooking(bookingRequest)) as HotelBookingResponse;
  return result;
}
