export interface DashboardMetrics {
  totalUsers: number
  activeUsers: number
  inactiveUsers: number
  totalTrips: number
  totalRevenue: number
  totalFeedbacks: number
  pendingFeedbacks: number
  averageRating: number
}

export interface ChartData {
  name: string
  value: number
  date?: string
}

export interface ActivityLog {
  id: string
  userId: string
  user?: {
    firstName: string
    lastName: string
    email: string
  }
  action: string
  resource: string
  details?: Record<string, unknown>
  timestamp: string
  ipAddress: string
}
