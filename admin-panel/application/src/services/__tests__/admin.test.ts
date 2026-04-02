import { describe, it, expect, vi, beforeEach } from 'vitest'
import { adminService } from '@/services/admin'
import { apiClient } from '@/lib/axios'

vi.mock('@/lib/axios', () => ({
  apiClient: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}))

const mockListResponse = { items: [], total: 0, page: 1, limit: 10 }
const mockParams = { page: 1, limit: 10 }

describe('adminService', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should call GET /admin/trips on getAllTrips', async () => {
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockListResponse })
    const result = await adminService.getAllTrips(mockParams)
    expect(apiClient.get).toHaveBeenCalledWith('/admin/trips', { params: mockParams })
    expect(result).toEqual(mockListResponse)
  })

  it('should call GET /admin/travelers on getAllTravelers', async () => {
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockListResponse })
    const result = await adminService.getAllTravelers(mockParams)
    expect(apiClient.get).toHaveBeenCalledWith('/admin/travelers', { params: mockParams })
    expect(result).toEqual(mockListResponse)
  })

  it('should call GET /admin/flight-bookings on getAllFlightBookings', async () => {
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockListResponse })
    const result = await adminService.getAllFlightBookings(mockParams)
    expect(apiClient.get).toHaveBeenCalledWith('/admin/flight-bookings', { params: mockParams })
    expect(result).toEqual(mockListResponse)
  })

  it('should call GET /admin/traveler-profiles on getAllTravelerProfiles', async () => {
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockListResponse })
    const result = await adminService.getAllTravelerProfiles(mockParams)
    expect(apiClient.get).toHaveBeenCalledWith('/admin/traveler-profiles', { params: mockParams })
    expect(result).toEqual(mockListResponse)
  })

  it('should call GET /admin/booking-intents on getAllBookingIntents', async () => {
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockListResponse })
    const result = await adminService.getAllBookingIntents(mockParams)
    expect(apiClient.get).toHaveBeenCalledWith('/admin/booking-intents', { params: mockParams })
    expect(result).toEqual(mockListResponse)
  })

  it('should call GET /admin/flight-searches on getAllFlightSearches', async () => {
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockListResponse })
    const result = await adminService.getAllFlightSearches(mockParams)
    expect(apiClient.get).toHaveBeenCalledWith('/admin/flight-searches', { params: mockParams })
    expect(result).toEqual(mockListResponse)
  })

  it('should call GET /admin/accommodations on getAllAccommodations', async () => {
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockListResponse })
    const result = await adminService.getAllAccommodations(mockParams)
    expect(apiClient.get).toHaveBeenCalledWith('/admin/accommodations', { params: mockParams })
    expect(result).toEqual(mockListResponse)
  })

  it('should call GET /admin/baggage-items on getAllBaggageItems', async () => {
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockListResponse })
    const result = await adminService.getAllBaggageItems(mockParams)
    expect(apiClient.get).toHaveBeenCalledWith('/admin/baggage-items', { params: mockParams })
    expect(result).toEqual(mockListResponse)
  })

  it('should call GET /admin/activities on getAllActivities', async () => {
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockListResponse })
    const result = await adminService.getAllActivities(mockParams)
    expect(apiClient.get).toHaveBeenCalledWith('/admin/activities', { params: mockParams })
    expect(result).toEqual(mockListResponse)
  })

  it('should call GET /admin/budget-items on getAllBudgetItems', async () => {
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockListResponse })
    const result = await adminService.getAllBudgetItems(mockParams)
    expect(apiClient.get).toHaveBeenCalledWith('/admin/budget-items', { params: mockParams })
    expect(result).toEqual(mockListResponse)
  })

  it('should call GET /admin/trip-shares on getAllTripShares', async () => {
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockListResponse })
    const result = await adminService.getAllTripShares(mockParams)
    expect(apiClient.get).toHaveBeenCalledWith('/admin/trip-shares', { params: mockParams })
    expect(result).toEqual(mockListResponse)
  })

  it('should call GET /admin/notifications on getAllNotifications', async () => {
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockListResponse })
    const result = await adminService.getAllNotifications(mockParams)
    expect(apiClient.get).toHaveBeenCalledWith('/admin/notifications', { params: mockParams })
    expect(result).toEqual(mockListResponse)
  })

  it('should call PATCH /admin/users/:id/plan on updateUserPlan', async () => {
    vi.mocked(apiClient.patch).mockResolvedValue({ data: {} })
    await adminService.updateUserPlan('user-1', 'premium')
    expect(apiClient.patch).toHaveBeenCalledWith('/admin/users/user-1/plan', { plan: 'premium' })
  })

  it('should call POST /admin/notifications/send on sendNotification', async () => {
    const payload = {
      user_ids: ['user-1', 'user-2'],
      title: 'Test',
      body: 'Hello',
      type: 'info',
    }
    const mockResponse = { message: 'Sent', count: 2 }
    vi.mocked(apiClient.post).mockResolvedValue({ data: mockResponse })
    const result = await adminService.sendNotification(payload)
    expect(apiClient.post).toHaveBeenCalledWith('/admin/notifications/send', payload)
    expect(result).toEqual(mockResponse)
  })

  it('should call getAllTrips without params', async () => {
    vi.mocked(apiClient.get).mockResolvedValue({ data: mockListResponse })
    const result = await adminService.getAllTrips()
    expect(apiClient.get).toHaveBeenCalledWith('/admin/trips', { params: undefined })
    expect(result).toEqual(mockListResponse)
  })
})
