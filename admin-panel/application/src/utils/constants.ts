export const USER_ROLES = {
  SUPER_ADMIN: 'super_admin',
  ADMIN: 'admin',
  USER: 'user',
} as const

export const API_ENDPOINTS = {
  AUTH: {
    REGISTER: '/v1/auth/register',
    LOGIN: '/v1/auth/login',
    ME: '/v1/auth/me',
    LOGOUT: '/v1/auth/logout',
  },
  TRIPS: {
    BASE: '/v1/trips',
    BY_ID: (tripId: string) => `/v1/trips/${tripId}`,
    TRAVELERS: (tripId: string) => `/v1/trips/${tripId}/travelers`,
    FLIGHT_SEARCHES: (tripId: string) => `/v1/trips/${tripId}/flights/searches`,
    BOOKING_INTENTS: (tripId: string) => `/v1/trips/${tripId}/booking-intents`,
  },
  BOOKING_INTENTS: {
    BY_ID: (intentId: string) => `/v1/booking-intents/${intentId}`,
    BOOK: (intentId: string) => `/v1/booking-intents/${intentId}/book`,
    PAYMENT_AUTHORIZE: (intentId: string) => `/v1/booking-intents/${intentId}/payment/authorize`,
    PAYMENT_CONFIRM_TEST: (intentId: string) =>
      `/v1/booking-intents/${intentId}/payment/confirm-test`,
    PAYMENT_CAPTURE: (intentId: string) => `/v1/booking-intents/${intentId}/payment/capture`,
    PAYMENT_CANCEL: (intentId: string) => `/v1/booking-intents/${intentId}/payment/cancel`,
  },
  DASHBOARD: {
    METRICS: '/admin/dashboard/metrics',
    ACTIVITY: '/admin/dashboard/activity',
  },
  ADMIN: {
    TRIPS: '/admin/trips',
    TRAVELERS: '/admin/travelers',
    FLIGHT_BOOKINGS: '/admin/flight-bookings',
    TRAVELER_PROFILES: '/admin/traveler-profiles',
    BOOKING_INTENTS: '/admin/booking-intents',
    FLIGHT_SEARCHES: '/admin/flight-searches',
    ACCOMMODATIONS: '/admin/accommodations',
    BAGGAGE_ITEMS: '/admin/baggage-items',
    ACTIVITIES: '/admin/activities',
    BUDGET_ITEMS: '/admin/budget-items',
    TRIP_SHARES: '/admin/trip-shares',
    FEEDBACKS: '/admin/feedbacks',
    NOTIFICATIONS: '/admin/notifications',
  },
  USERS: '/admin/users',
  FEEDBACKS: '/admin/feedbacks',
} as const

export const PAGINATION_DEFAULTS = {
  PAGE: 1,
  LIMIT: 10,
} as const

export const DATE_FORMATS = {
  DISPLAY: 'dd/MM/yyyy',
  DISPLAY_WITH_TIME: 'dd/MM/yyyy HH:mm',
  API: 'yyyy-MM-dd',
} as const
