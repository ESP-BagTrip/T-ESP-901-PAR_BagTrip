import { describe, it, expect } from 'vitest'
import { USER_ROLES, API_ENDPOINTS, PAGINATION_DEFAULTS, DATE_FORMATS } from '@/utils/constants'

describe('USER_ROLES', () => {
  it('should have SUPER_ADMIN role', () => {
    expect(USER_ROLES.SUPER_ADMIN).toBe('super_admin')
  })

  it('should have ADMIN role', () => {
    expect(USER_ROLES.ADMIN).toBe('admin')
  })

  it('should have USER role', () => {
    expect(USER_ROLES.USER).toBe('user')
  })
})

describe('API_ENDPOINTS', () => {
  it('should have auth endpoints', () => {
    expect(API_ENDPOINTS.AUTH.REGISTER).toBe('/v1/auth/register')
    expect(API_ENDPOINTS.AUTH.LOGIN).toBe('/v1/auth/login')
    expect(API_ENDPOINTS.AUTH.ME).toBe('/v1/auth/me')
    expect(API_ENDPOINTS.AUTH.LOGOUT).toBe('/v1/auth/logout')
  })

  it('should have TRIPS.BY_ID as a function returning correct path', () => {
    expect(API_ENDPOINTS.TRIPS.BY_ID('abc-123')).toBe('/v1/trips/abc-123')
  })

  it('should have BOOKING_INTENTS.BY_ID as a function returning correct path', () => {
    expect(API_ENDPOINTS.BOOKING_INTENTS.BY_ID('intent-1')).toBe('/v1/booking-intents/intent-1')
  })

  it('should have admin endpoints', () => {
    expect(API_ENDPOINTS.ADMIN.TRIPS).toBe('/admin/trips')
    expect(API_ENDPOINTS.ADMIN.TRAVELERS).toBe('/admin/travelers')
    expect(API_ENDPOINTS.ADMIN.NOTIFICATIONS_SEND).toBe('/admin/notifications/send')
  })
})

describe('PAGINATION_DEFAULTS', () => {
  it('should have PAGE = 1', () => {
    expect(PAGINATION_DEFAULTS.PAGE).toBe(1)
  })

  it('should have LIMIT = 10', () => {
    expect(PAGINATION_DEFAULTS.LIMIT).toBe(10)
  })
})

describe('DATE_FORMATS', () => {
  it('should have DISPLAY format', () => {
    expect(DATE_FORMATS.DISPLAY).toBe('dd/MM/yyyy')
  })

  it('should have DISPLAY_WITH_TIME format', () => {
    expect(DATE_FORMATS.DISPLAY_WITH_TIME).toBe('dd/MM/yyyy HH:mm')
  })

  it('should have API format', () => {
    expect(DATE_FORMATS.API).toBe('yyyy-MM-dd')
  })
})
