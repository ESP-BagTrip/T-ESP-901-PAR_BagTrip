export interface Feedback {
  id: string
  trip_id: string
  trip_title: string | null
  user_id: string
  user_email: string
  overall_rating: number
  highlights: string | null
  lowlights: string | null
  would_recommend: boolean
  created_at: string
}
