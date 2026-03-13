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
  budget_total: number | null
  origin: string | null
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

export interface AdminTravelerProfile {
  id: string
  user_id: string
  user_email: string
  travel_types: string[] | null
  travel_style: string | null
  budget: string | null
  companions: string | null
  is_completed: boolean
  created_at: string
  updated_at: string
}

export interface AdminBookingIntent {
  id: string
  user_id: string
  user_email: string
  trip_id: string
  trip_title: string | null
  type: string
  status: string
  amount: number
  currency: string
  stripe_payment_intent_id: string | null
  created_at: string
  updated_at: string
}

export interface AdminFlightSearch {
  id: string
  trip_id: string
  trip_title: string | null
  origin_iata: string
  destination_iata: string
  departure_date: string
  return_date: string | null
  adults: number
  children: number | null
  travel_class: string | null
  created_at: string
}

export interface AdminListResponse<T> {
  items: T[]
  total: number
  page: number
  limit: number
  total_pages: number
}
