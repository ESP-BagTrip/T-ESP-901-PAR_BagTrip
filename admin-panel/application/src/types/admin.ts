export interface AdminTrip {
  id: string
  user_id: string
  user_email: string
  title: string | null
  origin_iata: string | null
  destination_iata: string | null
  start_date: string | null
  end_date: string | null
  status: string | null
  created_at: string
  updated_at: string
}

export interface AdminTraveler {
  id: string
  trip_id: string
  trip_title: string | null
  user_email: string
  amadeus_traveler_ref: string | null
  traveler_type: string
  first_name: string
  last_name: string
  date_of_birth: string | null
  gender: string | null
  created_at: string
  updated_at: string
}

export interface AdminHotelBooking {
  id: string
  trip_id: string
  trip_title: string | null
  user_email: string
  hotel_offer_id: string
  hotel_id: string | null
  booking_intent_id: string | null
  amadeus_booking_id: string | null
  status: string | null
  created_at: string
  updated_at: string
}

export interface AdminFlightBooking {
  id: string
  trip_id: string
  trip_title: string | null
  user_email: string
  flight_offer_id: string
  booking_intent_id: string | null
  amadeus_flight_order_id: string | null
  status: string | null
  booking_reference: string | null
  created_at: string
  updated_at: string
}

export interface AdminListResponse<T> {
  items: T[]
  total: number
  page: number
  limit: number
  total_pages: number
}
