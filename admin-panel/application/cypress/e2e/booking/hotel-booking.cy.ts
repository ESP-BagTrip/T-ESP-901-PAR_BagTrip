describe('Hotel Booking Flow', () => {
  beforeEach(() => {
    cy.loginWithMock()
    cy.mockDashboardAPIs()
    cy.mockTripCreation()
    cy.mockHotelSearch()
    cy.mockBookingIntentCreation('hotel')
    cy.mockPaymentAuthorize()
    cy.mockPaymentConfirmTest()
    cy.mockBookingIntentStatus('AUTHORIZED')
    cy.visit('/test')

    // Create trip first
    cy.contains('2. Create Trip').click()
    cy.contains('Créer un Trip (Paris → Rome)').click()
    cy.wait('@createTrip')
  })

  describe('Hotel Search Section', () => {
    it('should display Hotel Booking Flow section', () => {
      cy.contains('5. Hotel Booking Flow').should('be.visible')
    })

    it('should have search hotels button', () => {
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Rechercher des hôtels').should('be.visible')
    })

    it('should search hotels successfully', () => {
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Rechercher des hôtels').click()

      cy.wait('@searchHotels')
      cy.contains('Search ID:').should('be.visible')
    })

    it('should display hotel offers', () => {
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Rechercher des hôtels').click()

      cy.wait('@searchHotels')
      cy.contains('Offres trouvées:').should('be.visible')
    })

    it('should show offer prices and currencies', () => {
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Rechercher des hôtels').click()

      cy.wait('@searchHotels')
      cy.contains('EUR').should('be.visible')
    })
  })

  describe('Hotel Offer Selection', () => {
    beforeEach(() => {
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Rechercher des hôtels').click()
      cy.wait('@searchHotels')
    })

    it('should allow selecting hotel offer', () => {
      cy.get('.cursor-pointer').first().click()
      cy.contains('Sélectionné').should('be.visible')
    })

    it('should show selected indicator', () => {
      cy.get('.cursor-pointer').first().click()
      cy.contains('Offre sélectionnée').should('be.visible')
    })
  })

  describe('Hotel Booking Intent', () => {
    beforeEach(() => {
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Rechercher des hôtels').click()
      cy.wait('@searchHotels')
      cy.get('.cursor-pointer').first().click()
    })

    it('should create booking intent for hotel', () => {
      cy.contains('Créer Booking Intent (Hotel)').click()

      cy.wait('@createBookingIntent')
      cy.contains('Status:').should('be.visible')
    })

    it('should display booking intent status', () => {
      cy.contains('Créer Booking Intent (Hotel)').click()

      cy.wait('@createBookingIntent')
      cy.contains('INIT').should('be.visible')
    })
  })

  describe('Hotel Payment Authorization', () => {
    beforeEach(() => {
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Rechercher des hôtels').click()
      cy.wait('@searchHotels')
      cy.get('.cursor-pointer').first().click()
      cy.contains('Créer Booking Intent (Hotel)').click()
      cy.wait('@createBookingIntent')
    })

    it('should authorize hotel payment', () => {
      cy.contains('Autoriser le paiement').click()

      cy.wait('@authorizePayment')
      cy.contains('Payment Intent ID:').should('be.visible')
    })

    it('should have confirm payment button for hotel', () => {
      cy.contains('Autoriser le paiement').click()

      cy.wait('@authorizePayment')
      cy.contains('Confirmer le paiement (Test Card)').should('be.visible')
    })
  })

  describe('Hotel POC Mode', () => {
    beforeEach(() => {
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Rechercher des hôtels').click()
      cy.wait('@searchHotels')
      cy.get('.cursor-pointer').first().click()
      cy.contains('Créer Booking Intent (Hotel)').click()
      cy.wait('@createBookingIntent')
      cy.contains('Autoriser le paiement').click()
      cy.wait('@authorizePayment')
    })

    it('should show POC mode message', () => {
      cy.contains('POC Mode').should('be.visible')
    })

    it('should have optional book hotel button', () => {
      cy.contains("Réserver l'hôtel (Optionnel POC)").should('be.visible')
    })

    it('should have capture payment button', () => {
      cy.contains('Capturer le paiement').should('be.visible')
    })
  })

  describe('Booking Intent Disabled States', () => {
    it('should disable booking intent button without selected offer', () => {
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Rechercher des hôtels').click()
      cy.wait('@searchHotels')

      cy.contains('Créer Booking Intent (Hotel)').should('be.disabled')
    })
  })
})

describe('Hotel Search Without Trip', () => {
  beforeEach(() => {
    cy.loginWithMock()
    cy.mockDashboardAPIs()
    cy.visit('/test')
  })

  it('should disable search button without trip', () => {
    cy.contains('5. Hotel Booking Flow').click()
    cy.contains('Rechercher des hôtels').should('be.disabled')
  })
})
