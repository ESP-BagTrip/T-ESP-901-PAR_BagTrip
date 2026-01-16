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

    // Wait for authentication to complete and page to show content
    cy.wait('@getCurrentUser')
    cy.contains('Test View - Booking Flow', { timeout: 10000 }).should('be.visible')

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
      cy.contains('Offres trouvées:').should('be.visible')
    })

    it('should allow selecting hotel offer', () => {
      cy.get('.cursor-pointer').first().click()
      // After selecting, the offer shows "✓ Sélectionné"
      cy.contains('✓ Sélectionné').should('be.visible')
    })

    it('should show selected indicator', () => {
      cy.get('.cursor-pointer').first().click()
      // The summary shows "• Offre sélectionnée" next to "Offres trouvées:"
      cy.contains('• Offre sélectionnée').should('be.visible')
    })
  })

  describe('Hotel Booking Intent', () => {
    beforeEach(() => {
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Rechercher des hôtels').click()
      cy.wait('@searchHotels')
      cy.contains('Offres trouvées:').should('be.visible')
      cy.get('.cursor-pointer').first().click()
      cy.contains('✓ Sélectionné').should('be.visible')
    })

    it('should create booking intent for hotel', () => {
      cy.contains('Créer Booking Intent (Hotel)').should('not.be.disabled').click()

      cy.wait('@createBookingIntent')
      // Re-open the hotel section after booking intent creation
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Status:', { timeout: 10000 }).should('be.visible')
    })

    it('should display booking intent status', () => {
      cy.contains('Créer Booking Intent (Hotel)').should('not.be.disabled').click()

      cy.wait('@createBookingIntent')
      // Re-open the hotel section
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('INIT', { timeout: 10000 }).should('be.visible')
    })
  })

  describe('Hotel Payment Authorization', () => {
    beforeEach(() => {
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Rechercher des hôtels').click()
      cy.wait('@searchHotels')
      cy.contains('Offres trouvées:').should('be.visible')
      cy.get('.cursor-pointer').first().click()
      cy.contains('✓ Sélectionné').should('be.visible')
      cy.contains('Créer Booking Intent (Hotel)').should('not.be.disabled').click()
      cy.wait('@createBookingIntent')
      // Re-open the hotel section after booking intent creation
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Status:', { timeout: 10000 }).should('be.visible')
    })

    it('should authorize hotel payment', () => {
      cy.contains('Autoriser le paiement').should('be.visible').click()

      cy.wait('@authorizePayment')
      // Re-open hotel section after payment authorization
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Payment Intent ID:', { timeout: 10000 }).should('be.visible')
    })

    it('should have confirm payment button for hotel', () => {
      cy.contains('Autoriser le paiement').should('be.visible').click()

      cy.wait('@authorizePayment')
      // Re-open hotel section
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Confirmer le paiement (Test Card)', { timeout: 10000 }).should('be.visible')
    })
  })

  describe('Hotel POC Mode', () => {
    beforeEach(() => {
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Rechercher des hôtels').click()
      cy.wait('@searchHotels')
      cy.contains('Offres trouvées:').should('be.visible')
      cy.get('.cursor-pointer').first().click()
      cy.contains('✓ Sélectionné').should('be.visible')
      cy.contains('Créer Booking Intent (Hotel)').should('not.be.disabled').click()
      cy.wait('@createBookingIntent')
      // Re-open the hotel section after booking intent creation
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Status:', { timeout: 10000 }).should('be.visible')
      cy.contains('Autoriser le paiement').should('be.visible').click()
      cy.wait('@authorizePayment')
      // Re-open hotel section after payment authorization
      cy.contains('5. Hotel Booking Flow').click()
      cy.contains('Payment Intent ID:', { timeout: 10000 }).should('be.visible')
    })

    it('should show POC mode message', () => {
      cy.contains('POC Mode:').should('be.visible')
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
    cy.wait('@getCurrentUser')
    cy.contains('Test View - Booking Flow', { timeout: 10000 }).should('be.visible')
  })

  it('should disable search button without trip', () => {
    cy.contains('5. Hotel Booking Flow').click()
    cy.contains('Rechercher des hôtels').should('be.disabled')
  })
})
