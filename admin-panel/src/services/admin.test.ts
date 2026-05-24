import { describe, it, expect, vi, beforeEach } from 'vitest'
import { apiClient } from '@/lib/axios'
import { adminService } from './admin'

vi.mock('@/lib/axios', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}))

const mockGet = vi.mocked(apiClient.get)
const mockPost = vi.mocked(apiClient.post)
const mockPatch = vi.mocked(apiClient.patch)
const mockDelete = vi.mocked(apiClient.delete)

beforeEach(() => {
  vi.clearAllMocks()
})

const mockListResponse = { items: [{ id: '1' }], total: 1, page: 1, limit: 10 }
const params = { page: 1, limit: 10 }

describe('adminService', () => {
  // ──────────────────────── List Methods ────────────────────────

  describe.each([
    ['getAllTrips', '/admin/trips'],
    ['getAllTravelers', '/admin/travelers'],
    ['getAllFlightBookings', '/admin/flight-bookings'],
    ['getAllTravelerProfiles', '/admin/traveler-profiles'],
    ['getAllBookingIntents', '/admin/booking-intents'],
    ['getAllFlightSearches', '/admin/flight-searches'],
    ['getAllAccommodations', '/admin/accommodations'],
    ['getAllBaggageItems', '/admin/baggage-items'],
    ['getAllActivities', '/admin/activities'],
    ['getAllBudgetItems', '/admin/budget-items'],
    ['getAllTripShares', '/admin/trip-shares'],
    ['getAllNotifications', '/admin/notifications'],
  ])('%s', (method, url) => {
    it(`should GET ${url} with params and return response.data`, async () => {
      mockGet.mockResolvedValue({ data: mockListResponse })

      const result = await (adminService as Record<string, CallableFunction>)[method](params)

      expect(mockGet).toHaveBeenCalledWith(url, { params })
      expect(result).toEqual(mockListResponse)
    })

    it(`should call without params`, async () => {
      mockGet.mockResolvedValue({ data: mockListResponse })

      await (adminService as Record<string, CallableFunction>)[method]()

      expect(mockGet).toHaveBeenCalledWith(url, { params: undefined })
    })
  })

  // ──────────────────────── User Management ────────────────────────

  describe('updateUserPlan', () => {
    it('should PATCH /admin/users/{userId}/plan', async () => {
      mockPatch.mockResolvedValue({ data: {} })

      await adminService.updateUserPlan('u1', 'premium')

      expect(mockPatch).toHaveBeenCalledWith('/admin/users/u1/plan', { plan: 'premium' })
    })
  })

  describe('getUserDetail', () => {
    it('should GET /admin/users/{userId} and return response.data', async () => {
      const mockUser = { id: 'u1', email: 'test@test.com' }
      mockGet.mockResolvedValue({ data: mockUser })

      const result = await adminService.getUserDetail('u1')

      expect(mockGet).toHaveBeenCalledWith('/admin/users/u1')
      expect(result).toEqual(mockUser)
    })
  })

  describe('updateUser', () => {
    it('should PATCH /admin/users/{userId} with data', async () => {
      mockPatch.mockResolvedValue({ data: {} })
      const data = { first_name: 'John' }

      await adminService.updateUser('u1', data)

      expect(mockPatch).toHaveBeenCalledWith('/admin/users/u1', data)
    })
  })

  describe('resetAiQuota', () => {
    it('should PATCH /admin/users/{userId}/ai-quota/reset', async () => {
      mockPatch.mockResolvedValue({ data: {} })

      await adminService.resetAiQuota('u1')

      expect(mockPatch).toHaveBeenCalledWith('/admin/users/u1/ai-quota/reset')
    })
  })

  describe('banUser', () => {
    it('should POST /admin/users/{userId}/ban with reason', async () => {
      mockPost.mockResolvedValue({ data: {} })

      await adminService.banUser('u1', 'spam')

      expect(mockPost).toHaveBeenCalledWith('/admin/users/u1/ban', { reason: 'spam' })
    })

    it('should default reason to empty string', async () => {
      mockPost.mockResolvedValue({ data: {} })

      await adminService.banUser('u1')

      expect(mockPost).toHaveBeenCalledWith('/admin/users/u1/ban', { reason: '' })
    })
  })

  describe('unbanUser', () => {
    it('should POST /admin/users/{userId}/unban', async () => {
      mockPost.mockResolvedValue({ data: {} })

      await adminService.unbanUser('u1')

      expect(mockPost).toHaveBeenCalledWith('/admin/users/u1/unban')
    })
  })

  describe('deleteUser', () => {
    it('should DELETE /admin/users/{userId}', async () => {
      mockDelete.mockResolvedValue({ data: {} })

      await adminService.deleteUser('u1')

      expect(mockDelete).toHaveBeenCalledWith('/admin/users/u1')
    })
  })

  describe('bulkChangePlan', () => {
    it('should POST /admin/users/bulk/plan and return response.data', async () => {
      mockPost.mockResolvedValue({ data: { count: 3 } })

      const result = await adminService.bulkChangePlan(['u1', 'u2', 'u3'], 'premium')

      expect(mockPost).toHaveBeenCalledWith('/admin/users/bulk/plan', {
        user_ids: ['u1', 'u2', 'u3'],
        plan: 'premium',
      })
      expect(result).toEqual({ count: 3 })
    })
  })

  describe('bulkBan', () => {
    it('should POST /admin/users/bulk/ban and return response.data', async () => {
      mockPost.mockResolvedValue({ data: { count: 2 } })

      const result = await adminService.bulkBan(['u1', 'u2'], 'violation')

      expect(mockPost).toHaveBeenCalledWith('/admin/users/bulk/ban', {
        user_ids: ['u1', 'u2'],
        reason: 'violation',
      })
      expect(result).toEqual({ count: 2 })
    })

    it('should default reason to empty string', async () => {
      mockPost.mockResolvedValue({ data: { count: 1 } })

      await adminService.bulkBan(['u1'])

      expect(mockPost).toHaveBeenCalledWith('/admin/users/bulk/ban', {
        user_ids: ['u1'],
        reason: '',
      })
    })
  })

  describe('sendNotification', () => {
    it('should POST /admin/notifications/send and return response.data', async () => {
      const payload = { user_ids: ['u1'], title: 'Hello', body: 'World' }
      mockPost.mockResolvedValue({ data: { message: 'sent', count: 1 } })

      const result = await adminService.sendNotification(payload)

      expect(mockPost).toHaveBeenCalledWith('/admin/notifications/send', payload)
      expect(result).toEqual({ message: 'sent', count: 1 })
    })
  })

  // ──────────────────────── Booking Management ────────────────────────

  describe('getBookingIntentDetail', () => {
    it('should GET /admin/booking-intents/{intentId}/detail and return response.data', async () => {
      const mockDetail = { id: 'bi1', status: 'pending' }
      mockGet.mockResolvedValue({ data: mockDetail })

      const result = await adminService.getBookingIntentDetail('bi1')

      expect(mockGet).toHaveBeenCalledWith('/admin/booking-intents/bi1/detail')
      expect(result).toEqual(mockDetail)
    })
  })

  describe('forceBookingStatus', () => {
    it('should PATCH /admin/booking-intents/{intentId}/status', async () => {
      mockPatch.mockResolvedValue({ data: {} })

      await adminService.forceBookingStatus('bi1', 'confirmed')

      expect(mockPatch).toHaveBeenCalledWith('/admin/booking-intents/bi1/status', {
        status: 'confirmed',
      })
    })
  })

  describe('cancelBooking', () => {
    it('should POST /admin/booking-intents/{intentId}/cancel', async () => {
      mockPost.mockResolvedValue({ data: {} })

      await adminService.cancelBooking('bi1')

      expect(mockPost).toHaveBeenCalledWith('/admin/booking-intents/bi1/cancel')
    })
  })

  describe('markBookingRefunded', () => {
    it('should POST /admin/booking-intents/{intentId}/refund', async () => {
      mockPost.mockResolvedValue({ data: {} })

      await adminService.markBookingRefunded('bi1')

      expect(mockPost).toHaveBeenCalledWith('/admin/booking-intents/bi1/refund')
    })
  })

  describe('deleteFeedback', () => {
    it('should DELETE /admin/feedbacks/{feedbackId}', async () => {
      mockDelete.mockResolvedValue({ data: {} })

      await adminService.deleteFeedback('f1')

      expect(mockDelete).toHaveBeenCalledWith('/admin/feedbacks/f1')
    })
  })

  // ──────────────────────── Audit Log ────────────────────────

  describe('getAuditLogs', () => {
    it('should GET /admin/audit-logs with params and return response.data', async () => {
      const mockLogs = { items: [{ id: 'log1' }], total: 1 }
      mockGet.mockResolvedValue({ data: mockLogs })
      const auditParams = { page: 1, action: 'login' }

      const result = await adminService.getAuditLogs(auditParams)

      expect(mockGet).toHaveBeenCalledWith('/admin/audit-logs', { params: auditParams })
      expect(result).toEqual(mockLogs)
    })

    it('should call without params', async () => {
      mockGet.mockResolvedValue({ data: { items: [] } })

      await adminService.getAuditLogs()

      expect(mockGet).toHaveBeenCalledWith('/admin/audit-logs', { params: undefined })
    })
  })

  // ──────────────────────── Trip Management ────────────────────────

  describe('getTripDetail', () => {
    it('should GET /admin/trips/{tripId} and return response.data', async () => {
      const mockTrip = { id: 't1', name: 'Paris' }
      mockGet.mockResolvedValue({ data: mockTrip })

      const result = await adminService.getTripDetail('t1')

      expect(mockGet).toHaveBeenCalledWith('/admin/trips/t1')
      expect(result).toEqual(mockTrip)
    })
  })

  describe('updateTrip', () => {
    it('should PATCH /admin/trips/{tripId} with data', async () => {
      mockPatch.mockResolvedValue({ data: {} })
      const data = { name: 'Updated Trip' }

      await adminService.updateTrip('t1', data)

      expect(mockPatch).toHaveBeenCalledWith('/admin/trips/t1', data)
    })
  })

  describe('deleteTrip', () => {
    it('should DELETE /admin/trips/{tripId}', async () => {
      mockDelete.mockResolvedValue({ data: {} })

      await adminService.deleteTrip('t1')

      expect(mockDelete).toHaveBeenCalledWith('/admin/trips/t1')
    })
  })

  describe('archiveTrip', () => {
    it('should PATCH /admin/trips/{tripId}/archive', async () => {
      mockPatch.mockResolvedValue({ data: {} })

      await adminService.archiveTrip('t1')

      expect(mockPatch).toHaveBeenCalledWith('/admin/trips/t1/archive')
    })
  })

  // ──────────────────────── Sub-entity CRUD ────────────────────────

  describe('createActivity', () => {
    it('should POST /admin/trips/{tripId}/activities and return response.data', async () => {
      const data = { name: 'Museum visit' }
      const mockActivity = { id: 'a1', ...data }
      mockPost.mockResolvedValue({ data: mockActivity })

      const result = await adminService.createActivity('t1', data)

      expect(mockPost).toHaveBeenCalledWith('/admin/trips/t1/activities', data)
      expect(result).toEqual(mockActivity)
    })
  })

  describe('updateActivity', () => {
    it('should PATCH /admin/trips/{tripId}/activities/{activityId}', async () => {
      mockPatch.mockResolvedValue({ data: {} })
      const data = { name: 'Updated activity' }

      await adminService.updateActivity('t1', 'a1', data)

      expect(mockPatch).toHaveBeenCalledWith('/admin/trips/t1/activities/a1', data)
    })
  })

  describe('deleteActivity', () => {
    it('should DELETE /admin/trips/{tripId}/activities/{activityId}', async () => {
      mockDelete.mockResolvedValue({ data: {} })

      await adminService.deleteActivity('t1', 'a1')

      expect(mockDelete).toHaveBeenCalledWith('/admin/trips/t1/activities/a1')
    })
  })

  describe('createAccommodation', () => {
    it('should POST /admin/trips/{tripId}/accommodations and return response.data', async () => {
      const data = { name: 'Hotel XYZ' }
      const mockAccommodation = { id: 'acc1', ...data }
      mockPost.mockResolvedValue({ data: mockAccommodation })

      const result = await adminService.createAccommodation('t1', data)

      expect(mockPost).toHaveBeenCalledWith('/admin/trips/t1/accommodations', data)
      expect(result).toEqual(mockAccommodation)
    })
  })

  describe('updateAccommodation', () => {
    it('should PATCH /admin/trips/{tripId}/accommodations/{accId}', async () => {
      mockPatch.mockResolvedValue({ data: {} })
      const data = { name: 'Updated hotel' }

      await adminService.updateAccommodation('t1', 'acc1', data)

      expect(mockPatch).toHaveBeenCalledWith('/admin/trips/t1/accommodations/acc1', data)
    })
  })

  describe('deleteAccommodation', () => {
    it('should DELETE /admin/trips/{tripId}/accommodations/{accId}', async () => {
      mockDelete.mockResolvedValue({ data: {} })

      await adminService.deleteAccommodation('t1', 'acc1')

      expect(mockDelete).toHaveBeenCalledWith('/admin/trips/t1/accommodations/acc1')
    })
  })

  describe('deleteBudgetItem', () => {
    it('should DELETE /admin/trips/{tripId}/budget-items/{itemId}', async () => {
      mockDelete.mockResolvedValue({ data: {} })

      await adminService.deleteBudgetItem('t1', 'b1')

      expect(mockDelete).toHaveBeenCalledWith('/admin/trips/t1/budget-items/b1')
    })
  })

  describe('deleteBaggageItem', () => {
    it('should DELETE /admin/trips/{tripId}/baggage/{itemId}', async () => {
      mockDelete.mockResolvedValue({ data: {} })

      await adminService.deleteBaggageItem('t1', 'bag1')

      expect(mockDelete).toHaveBeenCalledWith('/admin/trips/t1/baggage/bag1')
    })
  })

  describe('deleteShare', () => {
    it('should DELETE /admin/trips/{tripId}/shares/{shareId}', async () => {
      mockDelete.mockResolvedValue({ data: {} })

      await adminService.deleteShare('t1', 's1')

      expect(mockDelete).toHaveBeenCalledWith('/admin/trips/t1/shares/s1')
    })
  })
})
