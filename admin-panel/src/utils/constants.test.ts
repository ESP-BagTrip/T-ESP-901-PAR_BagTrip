import { describe, it, expect } from 'vitest'
import { USER_ROLES, API_ENDPOINTS, PAGINATION_DEFAULTS, DATE_FORMATS } from './constants'

describe('USER_ROLES', () => {
  it('contains the three expected roles', () => {
    expect(USER_ROLES).toEqual({
      SUPER_ADMIN: 'super_admin',
      ADMIN: 'admin',
      USER: 'user',
    })
  })

  it('has exactly 3 roles', () => {
    expect(Object.keys(USER_ROLES)).toHaveLength(3)
  })
})

describe('API_ENDPOINTS', () => {
  describe('AUTH', () => {
    it('has correct login endpoint', () => {
      expect(API_ENDPOINTS.AUTH.LOGIN).toBe('/v1/auth/login')
    })

    it('has correct me endpoint', () => {
      expect(API_ENDPOINTS.AUTH.ME).toBe('/v1/auth/me')
    })

    it('has correct logout endpoint', () => {
      expect(API_ENDPOINTS.AUTH.LOGOUT).toBe('/v1/auth/logout')
    })
  })

  describe('TRIPS', () => {
    it('has correct base endpoint', () => {
      expect(API_ENDPOINTS.TRIPS.BASE).toBe('/v1/trips')
    })

    it('generates correct BY_ID endpoint', () => {
      expect(API_ENDPOINTS.TRIPS.BY_ID('abc-123')).toBe('/v1/trips/abc-123')
    })

    it('generates correct TRAVELERS endpoint', () => {
      expect(API_ENDPOINTS.TRIPS.TRAVELERS('trip-1')).toBe('/v1/trips/trip-1/travelers')
    })

    it('generates correct FLIGHT_SEARCHES endpoint', () => {
      expect(API_ENDPOINTS.TRIPS.FLIGHT_SEARCHES('trip-1')).toBe(
        '/v1/trips/trip-1/flights/searches'
      )
    })

    it('generates correct BOOKING_INTENTS endpoint', () => {
      expect(API_ENDPOINTS.TRIPS.BOOKING_INTENTS('trip-1')).toBe('/v1/trips/trip-1/booking-intents')
    })
  })

  describe('BOOKING_INTENTS', () => {
    const intentId = 'intent-42'

    it('generates correct BY_ID endpoint', () => {
      expect(API_ENDPOINTS.BOOKING_INTENTS.BY_ID(intentId)).toBe(`/v1/booking-intents/${intentId}`)
    })

    it('generates correct BOOK endpoint', () => {
      expect(API_ENDPOINTS.BOOKING_INTENTS.BOOK(intentId)).toBe(
        `/v1/booking-intents/${intentId}/book`
      )
    })

    it('generates correct PAYMENT_AUTHORIZE endpoint', () => {
      expect(API_ENDPOINTS.BOOKING_INTENTS.PAYMENT_AUTHORIZE(intentId)).toBe(
        `/v1/booking-intents/${intentId}/payment/authorize`
      )
    })

    it('generates correct PAYMENT_CONFIRM_TEST endpoint', () => {
      expect(API_ENDPOINTS.BOOKING_INTENTS.PAYMENT_CONFIRM_TEST(intentId)).toBe(
        `/v1/booking-intents/${intentId}/payment/confirm-test`
      )
    })

    it('generates correct PAYMENT_CAPTURE endpoint', () => {
      expect(API_ENDPOINTS.BOOKING_INTENTS.PAYMENT_CAPTURE(intentId)).toBe(
        `/v1/booking-intents/${intentId}/payment/capture`
      )
    })

    it('generates correct PAYMENT_CANCEL endpoint', () => {
      expect(API_ENDPOINTS.BOOKING_INTENTS.PAYMENT_CANCEL(intentId)).toBe(
        `/v1/booking-intents/${intentId}/payment/cancel`
      )
    })
  })

  describe('DASHBOARD', () => {
    it('has correct metrics endpoint', () => {
      expect(API_ENDPOINTS.DASHBOARD.METRICS).toBe('/admin/dashboard/metrics')
    })

    it('has correct activity endpoint', () => {
      expect(API_ENDPOINTS.DASHBOARD.ACTIVITY).toBe('/admin/dashboard/activity')
    })
  })

  describe('ADMIN', () => {
    it('has correct trips endpoint', () => {
      expect(API_ENDPOINTS.ADMIN.TRIPS).toBe('/admin/trips')
    })

    it('has correct notifications send endpoint', () => {
      expect(API_ENDPOINTS.ADMIN.NOTIFICATIONS_SEND).toBe('/admin/notifications/send')
    })

    it('has all expected admin endpoints', () => {
      const keys = Object.keys(API_ENDPOINTS.ADMIN)
      expect(keys).toContain('TRIPS')
      expect(keys).toContain('TRAVELERS')
      expect(keys).toContain('FLIGHT_BOOKINGS')
      expect(keys).toContain('TRAVELER_PROFILES')
      expect(keys).toContain('BOOKING_INTENTS')
      expect(keys).toContain('FLIGHT_SEARCHES')
      expect(keys).toContain('ACCOMMODATIONS')
      expect(keys).toContain('BAGGAGE_ITEMS')
      expect(keys).toContain('ACTIVITIES')
      expect(keys).toContain('BUDGET_ITEMS')
      expect(keys).toContain('TRIP_SHARES')
      expect(keys).toContain('FEEDBACKS')
      expect(keys).toContain('NOTIFICATIONS')
      expect(keys).toContain('NOTIFICATIONS_SEND')
    })
  })

  it('has correct USERS endpoint', () => {
    expect(API_ENDPOINTS.USERS).toBe('/admin/users')
  })

  it('has correct FEEDBACKS endpoint', () => {
    expect(API_ENDPOINTS.FEEDBACKS).toBe('/admin/feedbacks')
  })
})

describe('PAGINATION_DEFAULTS', () => {
  it('has correct default page', () => {
    expect(PAGINATION_DEFAULTS.PAGE).toBe(1)
  })

  it('has correct default limit', () => {
    expect(PAGINATION_DEFAULTS.LIMIT).toBe(10)
  })
})

describe('DATE_FORMATS', () => {
  it('has correct display format', () => {
    expect(DATE_FORMATS.DISPLAY).toBe('dd/MM/yyyy')
  })

  it('has correct display with time format', () => {
    expect(DATE_FORMATS.DISPLAY_WITH_TIME).toBe('dd/MM/yyyy HH:mm')
  })

  it('has correct API format', () => {
    expect(DATE_FORMATS.API).toBe('yyyy-MM-dd')
  })
})
