import {
  HotelBookingRequest,
  HotelBookingResponse,
} from '../../integrations/amadeus/amadeus.types';

// ============================================================================
// HOTEL BOOKING TYPES
// ============================================================================

export type BookingGuest = {
  tid?: number;
  title: string; // MR, MRS, MS
  firstName: string;
  lastName: string;
  phone: string;
  email: string;
};

export type BookingPayment = {
  method: 'CREDIT_CARD';
  vendorCode: string; // VI, CA, AX
  cardNumber: string;
  expiryDate: string; // YYYY-MM
  holderName: string;
};

export type BookingRoomAssociation = {
  guestReferences: string[]; // Array of guest IDs (as strings)
  hotelOfferId: string;
};

export type CreateHotelBookingParams = {
  guests: BookingGuest[];
  travelAgentEmail?: string;
  roomAssociations: BookingRoomAssociation[];
  payment: BookingPayment;
};

export type HotelBookingResult = HotelBookingResponse;
