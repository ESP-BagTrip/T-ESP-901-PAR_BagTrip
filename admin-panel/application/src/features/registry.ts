import { lazy, type ComponentType } from 'react'

export interface TabConfig {
  id: string
  name: string
  component: React.LazyExoticComponent<ComponentType<{ isActive: boolean }>>
}

export const TAB_REGISTRY: TabConfig[] = [
  {
    id: 'users',
    name: 'Utilisateurs',
    component: lazy(() => import('./users/components/UsersTab')),
  },
  {
    id: 'trips',
    name: 'Trips',
    component: lazy(() => import('./trips/components/TripsTab')),
  },
  {
    id: 'profiles',
    name: 'Profils Voyageurs',
    component: lazy(() => import('./profiles/components/ProfilesTab')),
  },
  {
    id: 'travelers',
    name: 'Voyageurs',
    component: lazy(() => import('./travelers/components/TravelersTab')),
  },
  {
    id: 'bookingIntents',
    name: 'Booking Intents',
    component: lazy(() => import('./booking-intents/components/BookingIntentsTab')),
  },
  {
    id: 'flights',
    name: 'Rés. Vols',
    component: lazy(() => import('./flights/components/FlightsTab')),
  },
  {
    id: 'flightSearches',
    name: 'Rech. Vols',
    component: lazy(() => import('./flight-searches/components/FlightSearchesTab')),
  },
  {
    id: 'accommodations',
    name: 'Hébergements',
    component: lazy(() => import('./accommodations/components/AccommodationsTab')),
  },
  {
    id: 'baggageItems',
    name: 'Bagages',
    component: lazy(() => import('./baggage-items/components/BaggageItemsTab')),
  },
  {
    id: 'activities',
    name: 'Activités',
    component: lazy(() => import('./activities/components/ActivitiesTab')),
  },
  {
    id: 'budgetItems',
    name: 'Budget Items',
    component: lazy(() => import('./budget-items/components/BudgetItemsTab')),
  },
  {
    id: 'tripShares',
    name: 'Partages',
    component: lazy(() => import('./trip-shares/components/TripSharesTab')),
  },
  {
    id: 'feedbacks',
    name: 'Feedbacks',
    component: lazy(() => import('./feedbacks/components/FeedbacksTab')),
  },
  {
    id: 'notifications',
    name: 'Notifications',
    component: lazy(() => import('./notifications/components/NotificationsTab')),
  },
]
