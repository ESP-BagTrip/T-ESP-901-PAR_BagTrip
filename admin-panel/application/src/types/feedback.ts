export interface Feedback {
  id: string
  userId: string
  user?: {
    firstName: string
    lastName: string
    email: string
  }
  content: string
  rating: number
  category: 'general' | 'bug'
  status: 'pending' | 'resolved'
  createdAt: string
  updatedAt: string
  resolvedAt?: string
  resolvedBy?: string
}

export interface FeedbackFilters {
  category?: 'general' | 'bug'
  status?: 'pending' | 'resolved'
  rating?: number
  dateFrom?: string
  dateTo?: string
}
