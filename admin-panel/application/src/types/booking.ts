export interface Trip {
  id: string
  title: string | null
  originIata: string | null
  destinationIata: string | null
  startDate: string | null
  endDate: string | null
  status: string | null
  createdAt: string
  updatedAt: string
}

export interface TripCreateRequest {
  title?: string
  originIata?: string
  destinationIata?: string
  startDate?: string
  endDate?: string
}

export interface TripListResponse {
  items: Trip[]
}

export interface TripDetailResponse {
  trip: Trip
  flightOrder: Record<string, unknown> | null
  hotelBooking: Record<string, unknown> | null
}

export interface Traveler {
  id: string
  amadeusTravelerRef: string | null
  travelerType: string
  firstName: string
  lastName: string
  dateOfBirth: string | null
  gender: string | null
  documents: Array<Record<string, unknown>> | null
  contacts: Record<string, unknown> | null
  createdAt: string
  updatedAt: string
}

export interface TravelerCreateRequest {
  amadeusTravelerRef?: string
  travelerType: string
  firstName: string
  lastName: string
  dateOfBirth?: string
  gender?: string
  documents?: Array<Record<string, unknown>>
  contacts?: Record<string, unknown>
}

export interface TravelerListResponse {
  items: Traveler[]
}

export interface FlightOfferSummary {
  id: string
  grandTotal: number | null
  currency: string | null
  summary: Record<string, unknown> | null
}

export interface FlightSearchResponse {
  searchId: string
  offers: FlightOfferSummary[]
}

export interface FlightOfferDetail {
  id: string
  amadeusOfferId: string | null
  grandTotal: number | null
  baseTotal: number | null
  currency: string | null
  offer: Record<string, unknown>
}

export interface FlightSearchCreateRequest {
  originIata: string
  destinationIata: string
  departureDate: string
  returnDate?: string
  adults: number
  children?: number
  infants?: number
  travelClass?: string
  currency?: string
  nonStop?: boolean
}

export interface HotelOfferSummary {
  id: string
  hotelId: string | null
  offerId: string | null
  totalPrice: number | null
  currency: string | null
}

export interface HotelSearchResponse {
  searchId: string
  offers: HotelOfferSummary[]
}

export interface HotelOfferDetail {
  id: string
  hotelId: string | null
  offerId: string | null
  chainCode: string | null
  roomType: string | null
  currency: string | null
  totalPrice: number | null
  offer: Record<string, unknown>
}

export interface HotelSearchCreateRequest {
  cityCode?: string
  latitude?: number
  longitude?: number
  checkIn: string
  checkOut: string
  adults: number
  roomQty: number
  currency?: string
}

export interface BookingIntent {
  id: string
  type: string
  status: string
  amount: number
  currency: string
  selectedOfferId: string | null
}

export interface BookingIntentCreateRequest {
  type: 'flight' | 'hotel'
  flightOfferId?: string
  hotelOfferId?: string
}

export interface BookingIntentBookRequestFlight {
  travelerIds: string[]
  contacts: Array<Record<string, unknown>>
}

export interface BookingIntentBookRequestHotel {
  guests: Array<Record<string, unknown>>
  roomAssociations?: Array<Record<string, unknown>>
}

export interface BookingIntentBookResponse {
  bookingIntent: Record<string, unknown>
  amadeus: Record<string, unknown>
}

export interface PaymentAuthorizeRequest {
  returnUrl?: string
}

export interface PaymentAuthorizeResponse {
  stripePaymentIntentId: string
  clientSecret: string
  status: string
}

export interface PaymentCaptureResponse {
  bookingIntent: Record<string, unknown>
  stripe: Record<string, unknown>
}
