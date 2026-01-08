// ***********************************************
// Custom Cypress Commands for BagTrip Admin Panel
// ***********************************************

// ========== Authentication Commands ==========

/**
 * Login with mocked API response
 */
Cypress.Commands.add('loginWithMock', () => {
  cy.fixture('auth/login-success').then((response) => {
    cy.setCookie('auth-token', response.token)

    cy.intercept('GET', '**/v1/auth/me', {
      statusCode: 200,
      body: response.user,
    }).as('getCurrentUser')
  })
})

/**
 * Original API login command (for integration tests)
 */
Cypress.Commands.add('loginAsAdmin', () => {
  const apiUrl = Cypress.env('API_URL') || 'http://localhost:3000'
  cy.request({
    method: 'POST',
    url: `${apiUrl}/v1/auth/login`,
    body: {
      email: 'admin@bagtrip.com',
      password: 'admin123',
    },
  }).then((response) => {
    cy.setCookie('auth-token', response.body.token)
  })
})

/**
 * Visit dashboard with auth
 */
Cypress.Commands.add('visitDashboard', () => {
  cy.loginWithMock()
  cy.mockDashboardAPIs()
  cy.visit('/dashboard')
})

// ========== API Mocking Commands ==========

/**
 * Mock login API endpoint
 */
Cypress.Commands.add('mockLoginAPI', (success = true) => {
  const fixture = success ? 'auth/login-success' : 'auth/login-error'
  const statusCode = success ? 200 : 401

  cy.fixture(fixture).then((response) => {
    cy.intercept('POST', '**/v1/auth/login', {
      statusCode,
      body: response,
    }).as('loginRequest')
  })
})

/**
 * Mock register API endpoint
 */
Cypress.Commands.add('mockRegisterAPI', (success = true) => {
  const fixture = success ? 'auth/register-success' : 'auth/login-error'
  const statusCode = success ? 201 : 400

  cy.fixture(fixture).then((response) => {
    cy.intercept('POST', '**/v1/auth/register', {
      statusCode,
      body: response,
    }).as('registerRequest')
  })
})

/**
 * Mock current user API
 */
Cypress.Commands.add('mockCurrentUserAPI', () => {
  cy.fixture('auth/current-user').then((user) => {
    cy.intercept('GET', '**/v1/auth/me', {
      statusCode: 200,
      body: user,
    }).as('getCurrentUser')
  })
})

/**
 * Mock Users API
 */
Cypress.Commands.add('mockUsersAPI', (empty = false) => {
  const fixture = empty ? 'empty-list' : 'admin/users-list'

  cy.fixture(fixture).then((response) => {
    cy.intercept('GET', '**/admin/users*', {
      statusCode: 200,
      body: response,
    }).as('getUsers')
  })
})

/**
 * Mock Trips API
 */
Cypress.Commands.add('mockTripsAPI', (empty = false) => {
  const fixture = empty ? 'empty-list' : 'admin/trips-list'

  cy.fixture(fixture).then((response) => {
    cy.intercept('GET', '**/admin/trips*', {
      statusCode: 200,
      body: response,
    }).as('getTrips')
  })
})

/**
 * Mock Travelers API
 */
Cypress.Commands.add('mockTravelersAPI', (empty = false) => {
  const fixture = empty ? 'empty-list' : 'admin/travelers-list'

  cy.fixture(fixture).then((response) => {
    cy.intercept('GET', '**/admin/travelers*', {
      statusCode: 200,
      body: response,
    }).as('getTravelers')
  })
})

/**
 * Mock Hotel Bookings API
 */
Cypress.Commands.add('mockHotelBookingsAPI', (empty = false) => {
  const fixture = empty ? 'empty-list' : 'admin/hotel-bookings-list'

  cy.fixture(fixture).then((response) => {
    cy.intercept('GET', '**/admin/hotel-bookings*', {
      statusCode: 200,
      body: response,
    }).as('getHotelBookings')
  })
})

/**
 * Mock Flight Bookings API
 */
Cypress.Commands.add('mockFlightBookingsAPI', (empty = false) => {
  const fixture = empty ? 'empty-list' : 'admin/flight-bookings-list'

  cy.fixture(fixture).then((response) => {
    cy.intercept('GET', '**/admin/flight-bookings*', {
      statusCode: 200,
      body: response,
    }).as('getFlightBookings')
  })
})

/**
 * Mock all dashboard APIs
 */
Cypress.Commands.add('mockDashboardAPIs', () => {
  cy.mockUsersAPI()
  cy.mockTripsAPI()
  cy.mockTravelersAPI()
  cy.mockHotelBookingsAPI()
  cy.mockFlightBookingsAPI()
})

// ========== Booking Flow Commands ==========

/**
 * Mock trip creation
 */
Cypress.Commands.add('mockTripCreation', () => {
  cy.fixture('booking/trip').then((trip) => {
    cy.intercept('POST', '**/v1/trips', {
      statusCode: 201,
      body: trip,
    }).as('createTrip')
  })
})

/**
 * Mock traveler creation
 */
Cypress.Commands.add('mockTravelerCreation', () => {
  cy.fixture('booking/traveler').then((traveler) => {
    cy.intercept('POST', '**/v1/trips/*/travelers', {
      statusCode: 201,
      body: traveler,
    }).as('createTraveler')
  })
})

/**
 * Mock flight search
 */
Cypress.Commands.add('mockFlightSearch', () => {
  cy.fixture('booking/flight-search-results').then((results) => {
    cy.intercept('POST', '**/v1/trips/*/flights/searches', {
      statusCode: 200,
      body: results,
    }).as('searchFlights')
  })
})

/**
 * Mock hotel search
 */
Cypress.Commands.add('mockHotelSearch', () => {
  cy.fixture('booking/hotel-search-results').then((results) => {
    cy.intercept('POST', '**/v1/trips/*/hotels/searches', {
      statusCode: 200,
      body: results,
    }).as('searchHotels')
  })
})

/**
 * Mock booking intent creation
 */
Cypress.Commands.add('mockBookingIntentCreation', (type: 'flight' | 'hotel' = 'flight') => {
  cy.fixture('booking/booking-intent').then((intent) => {
    const response = { ...intent, type }
    cy.intercept('POST', '**/v1/trips/*/booking-intents', {
      statusCode: 201,
      body: response,
    }).as('createBookingIntent')
  })
})

/**
 * Mock payment authorization
 */
Cypress.Commands.add('mockPaymentAuthorize', () => {
  cy.fixture('booking/payment-authorize').then((payment) => {
    cy.intercept('POST', '**/v1/booking-intents/*/payment/authorize', {
      statusCode: 200,
      body: payment,
    }).as('authorizePayment')
  })
})

/**
 * Mock payment confirmation (test)
 */
Cypress.Commands.add('mockPaymentConfirmTest', () => {
  cy.intercept('POST', '**/v1/booking-intents/*/payment/confirm-test', {
    statusCode: 200,
    body: { success: true },
  }).as('confirmPaymentTest')
})

/**
 * Mock booking intent status polling
 */
Cypress.Commands.add('mockBookingIntentStatus', (status = 'AUTHORIZED') => {
  cy.fixture('booking/booking-intent').then((intent) => {
    cy.intercept('GET', '**/v1/booking-intents/*', {
      statusCode: 200,
      body: { ...intent, status },
    }).as('getBookingIntent')
  })
})

/**
 * Mock full booking flow
 */
Cypress.Commands.add('mockFullBookingFlow', () => {
  cy.mockTripCreation()
  cy.mockTravelerCreation()
  cy.mockFlightSearch()
  cy.mockHotelSearch()
  cy.mockBookingIntentCreation()
  cy.mockPaymentAuthorize()
  cy.mockPaymentConfirmTest()
})

export {}
