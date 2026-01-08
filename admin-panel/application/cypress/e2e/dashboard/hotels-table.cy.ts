describe('Hotel Bookings Table', () => {
  beforeEach(() => {
    cy.visitDashboard()
    cy.contains('Réservations Hôtels').click()
    cy.wait('@getHotelBookings')
  })

  describe('Data Display', () => {
    it('should display hotel bookings table', () => {
      cy.get('table').should('be.visible')
    })

    it('should show table headers', () => {
      cy.get('th').contains('ID').should('be.visible')
      cy.get('th').contains('Trip').should('be.visible')
      cy.get('th').contains('Utilisateur').should('be.visible')
      cy.get('th').contains('Statut').should('be.visible')
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
  })

  describe('Booking Status', () => {
    it('should show CONFIRMED status', () => {
      cy.get('tbody').contains('CONFIRMED').should('be.visible')
    })

    it('should show PENDING status', () => {
      cy.get('tbody').contains('PENDING').should('be.visible')
    })
  })

  describe('Pagination', () => {
    it('should display pagination info', () => {
      cy.contains('sur 5 résultats').should('be.visible')
    })
  })

  describe('Empty State', () => {
    it('should show empty state when no hotel bookings', () => {
      cy.loginWithMock()
      cy.mockUsersAPI()
      cy.mockTripsAPI()
      cy.mockTravelersAPI()
      cy.mockHotelBookingsAPI(true)
      cy.mockFlightBookingsAPI()

      cy.visit('/dashboard')
      cy.contains('Réservations Hôtels').click()

      cy.contains('Aucune donnée disponible').should('be.visible')
    })
  })

  describe('Tab Count', () => {
    it('should show hotel bookings count in tab', () => {
      cy.contains('Réservations Hôtels').parent().should('contain', '5')
    })
  })
})
