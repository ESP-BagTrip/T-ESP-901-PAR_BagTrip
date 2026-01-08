describe('Flight Booking Flow', () => {
  beforeEach(() => {
    cy.loginWithMock()
    cy.mockDashboardAPIs()
    cy.mockTripCreation()
    cy.mockTravelerCreation()
    cy.mockFlightSearch()
    cy.mockBookingIntentCreation('flight')
    cy.mockPaymentAuthorize()
    cy.mockPaymentConfirmTest()
    cy.mockBookingIntentStatus('AUTHORIZED')
    cy.visit('/test')

    // Create trip first
    cy.contains('2. Create Trip').click()
    cy.contains('Créer un Trip (Paris → Rome)').click()
    cy.wait('@createTrip')

    // Create traveler
    cy.contains('3. Add Traveler').click()
    cy.contains('Ajouter un Traveler').click()
    cy.wait('@createTraveler')
  })

  describe('Flight Search Section', () => {
    it('should display Flight Booking Flow section', () => {
      cy.contains('4. Flight Booking Flow').should('be.visible')
    })

    it('should have search flights button', () => {
      cy.contains('4. Flight Booking Flow').click()
      cy.contains('Rechercher des vols').should('be.visible')
    })

    it('should search flights successfully', () => {
      cy.contains('4. Flight Booking Flow').click()
      cy.contains('Rechercher des vols').click()

      cy.wait('@searchFlights')
      cy.contains('Search ID:').should('be.visible')
    })

    it('should display search results', () => {
      cy.contains('4. Flight Booking Flow').click()
      cy.contains('Rechercher des vols').click()

      cy.wait('@searchFlights')
      cy.contains('Offres trouvées:').should('be.visible')
    })

    it('should show offer prices', () => {
      cy.contains('4. Flight Booking Flow').click()
      cy.contains('Rechercher des vols').click()

      cy.wait('@searchFlights')
      cy.contains('EUR').should('be.visible')
    })
  })

  describe('Offer Selection', () => {
    beforeEach(() => {
      cy.contains('4. Flight Booking Flow').click()
      cy.contains('Rechercher des vols').click()
      cy.wait('@searchFlights')
    })

    it('should allow selecting an offer', () => {
      cy.get('.cursor-pointer').first().click()
      cy.contains('Sélectionné').should('be.visible')
    })

    it('should show selected indicator', () => {
      cy.get('.cursor-pointer').first().click()
      cy.contains('Offre sélectionnée').should('be.visible')
    })

    it('should toggle offer visibility', () => {
      cy.contains('Masquer').click()
      cy.get('.cursor-pointer').should('not.exist')

      cy.contains('Afficher').click()
      cy.get('.cursor-pointer').should('exist')
    })
  })

  describe('Booking Intent Creation', () => {
    beforeEach(() => {
      cy.contains('4. Flight Booking Flow').click()
      cy.contains('Rechercher des vols').click()
      cy.wait('@searchFlights')
      cy.get('.cursor-pointer').first().click()
    })

    it('should create booking intent for flight', () => {
      cy.contains('Créer Booking Intent (Flight)').click()

      cy.wait('@createBookingIntent')
      cy.contains('Status:').should('be.visible')
    })

    it('should display booking intent status', () => {
      cy.contains('Créer Booking Intent (Flight)').click()

      cy.wait('@createBookingIntent')
      cy.contains('INIT').should('be.visible')
    })
  })

  describe('Payment Authorization', () => {
    beforeEach(() => {
      cy.contains('4. Flight Booking Flow').click()
      cy.contains('Rechercher des vols').click()
      cy.wait('@searchFlights')
      cy.get('.cursor-pointer').first().click()
      cy.contains('Créer Booking Intent (Flight)').click()
      cy.wait('@createBookingIntent')
    })

    it('should authorize payment', () => {
      cy.contains('Autoriser le paiement').click()

      cy.wait('@authorizePayment')
      cy.contains('Payment Intent ID:').should('be.visible')
    })

    it('should display payment intent info', () => {
      cy.contains('Autoriser le paiement').click()

      cy.wait('@authorizePayment')
      cy.contains('pi_test_').should('be.visible')
    })

    it('should have confirm payment button', () => {
      cy.contains('Autoriser le paiement').click()

      cy.wait('@authorizePayment')
      cy.contains('Confirmer le paiement (Test Card)').should('be.visible')
    })
  })

  describe('Payment Confirmation', () => {
    beforeEach(() => {
      cy.contains('4. Flight Booking Flow').click()
      cy.contains('Rechercher des vols').click()
      cy.wait('@searchFlights')
      cy.get('.cursor-pointer').first().click()
      cy.contains('Créer Booking Intent (Flight)').click()
      cy.wait('@createBookingIntent')
      cy.contains('Autoriser le paiement').click()
      cy.wait('@authorizePayment')
    })

    it('should confirm test payment', () => {
      cy.contains('Confirmer le paiement (Test Card)').click()

      cy.wait('@confirmPaymentTest')
      cy.wait('@getBookingIntent')
    })

    it('should show authorized status', () => {
      cy.contains('Confirmer le paiement (Test Card)').click()

      cy.wait('@confirmPaymentTest')
      cy.wait('@getBookingIntent')
      cy.contains('Paiement autorisé').should('be.visible')
    })
  })

  describe('Flight Booking', () => {
    beforeEach(() => {
      // Mock authorized status from the start
      cy.intercept('GET', '**/v1/booking-intents/*', {
        statusCode: 200,
        body: {
          id: 'booking-intent-001-uuid-4a5b-8c9d',
          trip_id: 'created-trip-001-uuid-4a5b-8c9d',
          type: 'flight',
          status: 'AUTHORIZED',
          amount: '245.50',
          currency: 'EUR',
        },
      }).as('getAuthorizedBookingIntent')

      cy.contains('4. Flight Booking Flow').click()
      cy.contains('Rechercher des vols').click()
      cy.wait('@searchFlights')
      cy.get('.cursor-pointer').first().click()
      cy.contains('Créer Booking Intent (Flight)').click()
      cy.wait('@createBookingIntent')
      cy.contains('Autoriser le paiement').click()
      cy.wait('@authorizePayment')
      cy.contains('Confirmer le paiement (Test Card)').click()
      cy.wait('@confirmPaymentTest')
    })

    it('should show book flight button', () => {
      cy.contains('Réserver le vol').should('be.visible')
    })
  })

  describe('Booking Intent Disabled States', () => {
    it('should disable booking intent button without selected offer', () => {
      cy.contains('4. Flight Booking Flow').click()
      cy.contains('Rechercher des vols').click()
      cy.wait('@searchFlights')

      cy.contains('Créer Booking Intent (Flight)').should('be.disabled')
    })
  })
})

describe('Flight Search Without Trip', () => {
  beforeEach(() => {
    cy.loginWithMock()
    cy.mockDashboardAPIs()
    cy.visit('/test')
  })

  it('should disable search button without trip', () => {
    cy.contains('4. Flight Booking Flow').click()
    cy.contains('Rechercher des vols').should('be.disabled')
  })
})
