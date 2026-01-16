describe('Flight Bookings Table', () => {
  beforeEach(() => {
    cy.visitDashboard()
    // Wait for dashboard to load and tabs to be visible
    cy.get('table', { timeout: 10000 }).should('be.visible')
    cy.contains('Réservations Vols', { timeout: 10000 }).should('be.visible').click()
    cy.wait('@getFlightBookings')
  })

  describe('Data Display', () => {
    it('should display flight bookings table', () => {
      cy.get('table').should('be.visible')
    })

    it('should show table headers', () => {
      cy.get('th').contains('ID').should('be.visible')
      cy.get('th').contains('Trip').should('be.visible')
      cy.get('th').contains('Utilisateur').should('be.visible')
      cy.get('th').contains('Statut').should('be.visible')
      cy.get('th').contains('Référence').should('be.visible')
    })

    it('should display booking ID (truncated)', () => {
      cy.get('tbody tr').first().find('td').first().should('contain', '...')
    })

    it('should display trip title', () => {
      cy.get('tbody').should('contain', 'Paris to Rome')
    })

    it('should display user email', () => {
      cy.get('tbody').should('contain', 'user1@example.com')
    })

    it('should display booking reference', () => {
      cy.get('tbody').should('contain', 'ABC123')
    })
  })

  describe('Booking Status', () => {
    it('should show TICKETED status', () => {
      cy.get('tbody').contains('TICKETED').should('be.visible')
    })

    it('should show CONFIRMED status', () => {
      cy.get('tbody').contains('CONFIRMED').should('be.visible')
    })

    it('should show PENDING status', () => {
      cy.get('tbody').contains('PENDING').should('be.visible')
    })
  })

  describe('Pagination', () => {
    it('should display pagination info', () => {
      cy.contains('sur 8 résultats').should('be.visible')
    })
  })

  describe('Tab Count', () => {
    it('should show flight bookings count in tab', () => {
      cy.contains('Réservations Vols').parent().should('contain', '8')
    })
  })
})

// Separate describe block for empty state test that needs different setup
describe('Flight Bookings Table - Empty State', () => {
  it('should show empty state when no flight bookings', () => {
    cy.loginWithMock()
    cy.mockUsersAPI()
    cy.mockTripsAPI()
    cy.mockTravelersAPI()
    cy.mockHotelBookingsAPI()
    cy.mockFlightBookingsAPI(true)

    cy.visit('/dashboard')
    cy.get('table', { timeout: 10000 }).should('be.visible')
    cy.contains('Réservations Vols').click()

    cy.contains('Aucune donnée disponible').should('be.visible')
  })
})
