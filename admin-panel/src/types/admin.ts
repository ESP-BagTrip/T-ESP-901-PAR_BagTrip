export interface AuditLogEntry {
  id: string
  actor_id: string
  actor_email: string
  action: string
  entity_type: string
  entity_id: string
  diff_json: Record<string, { old: unknown; new: unknown }> | null
  metadata: Record<string, unknown> | null
  created_at: string
}

export interface AdminUserDetail {
  id: string
  email: string
  full_name: string | null
  phone: string | null
  plan: string
  plan_expires_at: string | null
  ai_generations_count: number
  ai_generations_reset_at: string | null
  banned_at: string | null
  ban_reason: string | null
  deleted_at: string | null
  trips_count: number
  bookings_count: number
  created_at: string
  updated_at: string | null
}

export interface AdminTripDetail {
  id: string
  user_id: string
  user_email: string
  title: string | null
  origin_iata: string | null
  destination_iata: string | null
  destination_name: string | null
  start_date: string | null
  end_date: string | null
  status: string | null
  budget_total: number | null
  nb_travelers: number | null
  origin: string | null
  archived_at: string | null
  activities_count: number
  accommodations_count: number
  shares_count: number
  created_at: string
  updated_at: string
}

export interface AdminTrip {
  id: string
  user_id: string
  user_email: string
  title: string | null
  origin_iata: string | null
  destination_iata: string | null
  destination_name: string | null
  start_date: string | null
  end_date: string | null
  status: string | null
  budget_total: number | null
  nb_travelers: number | null
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

export interface AdminAccommodation {
  id: string
  trip_id: string
  trip_title: string | null
  user_email: string
  name: string
  address: string | null
  check_in: string | null
  check_out: string | null
  price_per_night: number | null
  currency: string | null
  booking_reference: string | null
  created_at: string
  updated_at: string
}

export interface AdminBaggageItem {
  id: string
  trip_id: string
  trip_title: string | null
  user_email: string
  name: string
  category: string | null
  quantity: number | null
  is_packed: boolean | null
  created_at: string
  updated_at: string
}

export interface AdminActivity {
  id: string
  trip_id: string
  trip_title: string | null
  user_email: string
  title: string
  description: string | null
  date: string
  start_time: string | null
  end_time: string | null
  location: string | null
  category: string
  estimated_cost: number | null
  is_booked: boolean
  created_at: string
  updated_at: string
}

export interface AdminBudgetItem {
  id: string
  trip_id: string
  trip_title: string | null
  user_email: string
  label: string
  amount: number
  category: string
  date: string | null
  is_planned: boolean
  created_at: string
  updated_at: string
}

export interface AdminTripShare {
  id: string
  trip_id: string
  trip_title: string | null
  user_id: string
  user_email: string
  role: string
  invited_at: string
}

export interface AdminNotification {
  id: string
  user_id: string
  user_email: string
  trip_id: string | null
  trip_title: string | null
  type: string
  title: string
  body: string
  is_read: boolean
  sent_at: string | null
  created_at: string
}

export interface AdminListResponse<T> {
  items: T[]
  total: number
  page: number
  limit: number
  total_pages: number
}
