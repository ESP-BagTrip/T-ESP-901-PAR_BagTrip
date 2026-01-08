// ***********************************************************
// This example support/e2e.ts is processed and
// loaded automatically before your test files.
//
// This is a great place to put global configuration and
// behavior that modifies Cypress.
//
// You can change the location of this file or turn off
// automatically serving support files with the
// 'supportFile' configuration option.
//
// You can read more here:
// https://on.cypress.io/configuration
// ***********************************************************

// Import commands.js using ES2015 syntax:
import './commands'

// Import code coverage support
import '@cypress/code-coverage/support'

// ========== Type Declarations ==========

declare global {
  namespace Cypress {
    interface Chainable {
      // Authentication commands
      loginAsAdmin(): Chainable<void>
      loginWithMock(): Chainable<void>
      visitDashboard(): Chainable<void>

      // Auth API Mocks
      mockLoginAPI(success?: boolean): Chainable<void>
      mockRegisterAPI(success?: boolean): Chainable<void>
      mockCurrentUserAPI(): Chainable<void>

      // Admin API Mocks
      mockUsersAPI(empty?: boolean): Chainable<void>
      mockTripsAPI(empty?: boolean): Chainable<void>
      mockTravelersAPI(empty?: boolean): Chainable<void>
      mockHotelBookingsAPI(empty?: boolean): Chainable<void>
      mockFlightBookingsAPI(empty?: boolean): Chainable<void>
      mockDashboardAPIs(): Chainable<void>

      // Booking Flow Mocks
      mockTripCreation(): Chainable<void>
      mockTravelerCreation(): Chainable<void>
      mockFlightSearch(): Chainable<void>
      mockHotelSearch(): Chainable<void>
      mockBookingIntentCreation(type?: 'flight' | 'hotel'): Chainable<void>
      mockPaymentAuthorize(): Chainable<void>
      mockPaymentConfirmTest(): Chainable<void>
      mockBookingIntentStatus(status?: string): Chainable<void>
      mockFullBookingFlow(): Chainable<void>
    }
  }
}
