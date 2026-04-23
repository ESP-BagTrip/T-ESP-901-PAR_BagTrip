import { render, screen } from '@testing-library/react'

// Must be 'development' for the page to render (otherwise calls notFound)
// In vitest, NODE_ENV is already 'test' — mock notFound to do nothing instead

vi.mock('next/navigation', () => ({
  notFound: vi.fn(),
}))
vi.mock('@/hooks', () => ({
  useAuth: vi.fn(() => ({
    user: { id: 'user-1', email: 'admin@test.com' },
    isAuthenticated: true,
  })),
}))
vi.mock('@/services', () => ({
  bookingIntentsService: {
    createBookingIntent: vi.fn(),
    getBookingIntent: vi.fn(),
    bookFlight: vi.fn(),
  },
  flightsService: { searchFlights: vi.fn() },
  paymentsService: {
    authorizePayment: vi.fn(),
    confirmPaymentTest: vi.fn(),
    capturePayment: vi.fn(),
  },
  travelersService: { createTraveler: vi.fn() },
  tripsService: { createTrip: vi.fn() },
}))
vi.mock('@stripe/stripe-js', () => ({
  loadStripe: vi.fn(() => Promise.resolve(null)),
}))

import DevBookingFlowPage from './page'

describe('DevBookingFlowPage', () => {
  it('renders without crashing', () => {
    render(<DevBookingFlowPage />)
    expect(screen.getByText('Test View - Booking Flow')).toBeInTheDocument()
  })

  it('renders section titles', () => {
    render(<DevBookingFlowPage />)
    expect(screen.getByText('1. Authentication')).toBeInTheDocument()
    expect(screen.getByText('2. Create Trip')).toBeInTheDocument()
    expect(screen.getByText('3. Add Traveler')).toBeInTheDocument()
    expect(screen.getByText('4. Flight Booking Flow')).toBeInTheDocument()
  })

  it('shows authenticated user email', () => {
    render(<DevBookingFlowPage />)
    expect(screen.getByText('admin@test.com')).toBeInTheDocument()
  })
})
