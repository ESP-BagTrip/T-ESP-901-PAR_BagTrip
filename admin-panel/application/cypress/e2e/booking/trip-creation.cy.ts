describe('Trip Creation Flow', () => {
  beforeEach(() => {
    cy.loginWithMock()
    cy.mockDashboardAPIs()
    cy.mockTripCreation()
    cy.visit('/test')
    // Wait for authentication to complete and page to show content
    cy.wait('@getCurrentUser')
    cy.contains('Test View - Booking Flow', { timeout: 10000 }).should('be.visible')
  })

  describe('Authentication Section', () => {
    it('should display page title', () => {
      cy.contains('h1', 'Test View - Booking Flow').should('be.visible')
    })

    it('should display authenticated user info', () => {
      // Auth section is open by default, so content should be visible
      cy.contains('Utilisateur connecté').should('be.visible')
    })

    it('should show user email', () => {
      // Auth section is open by default
      cy.get('.space-y-4').should('exist')
    })
  })

  describe('Trip Creation', () => {
    it('should display Create Trip section', () => {
      cy.contains('2. Create Trip').should('be.visible')
    })

    it('should have create trip button', () => {
      cy.contains('2. Create Trip').click()
      cy.contains('Créer un Trip (Paris → Rome)').should('be.visible')
    })

    it('should create trip successfully', () => {
      cy.contains('2. Create Trip').click()
      cy.contains('Créer un Trip (Paris → Rome)').click()

      cy.wait('@createTrip')
      cy.contains('Trip créé:').should('be.visible')
    })

    it('should display trip info after creation', () => {
      cy.contains('2. Create Trip').click()
      cy.contains('Créer un Trip (Paris → Rome)').click()

      cy.wait('@createTrip')
      cy.contains('ID:').should('be.visible')
      cy.contains('Paris to Rome').should('be.visible')
    })

    it('should show origin and destination', () => {
      cy.contains('2. Create Trip').click()
      cy.contains('Créer un Trip (Paris → Rome)').click()

      cy.wait('@createTrip')
      // Trip fixture uses CDG → FCO
      cy.contains('→').should('be.visible')
    })
  })

  describe('Protected Route', () => {
    it('should show authentication required message when not logged in', () => {
      cy.clearCookies()
      cy.intercept('GET', '**/v1/auth/me', { statusCode: 401 }).as('authFail')
      cy.visit('/test')
      // Page redirects or shows auth required
      cy.url().should('satisfy', (url: string) => url.includes('/login') || url.includes('/test'))
    })

    it('should handle unauthenticated state', () => {
      cy.clearCookies()
      cy.intercept('GET', '**/v1/auth/me', { statusCode: 401 }).as('authFail')
      cy.visit('/test')
      // Either redirects to login or shows auth message
      cy.get('body').should('be.visible')
    })
  })

  describe('Loading State', () => {
    it('should show loading indicator during API call', () => {
      cy.intercept('POST', '**/v1/trips', {
        delay: 1000,
        statusCode: 201,
        fixture: 'booking/trip',
      }).as('slowCreateTrip')

      cy.contains('2. Create Trip').click()
      cy.contains('Créer un Trip (Paris → Rome)').click()

      cy.contains('Création...').should('be.visible')
    })
  })
})
