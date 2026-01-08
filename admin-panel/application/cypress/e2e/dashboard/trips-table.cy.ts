describe('Trips Table', () => {
  beforeEach(() => {
    cy.visitDashboard()
    cy.contains('Trips').click()
    cy.wait('@getTrips')
  })

  describe('Data Display', () => {
    it('should display trips table', () => {
      cy.get('table').should('be.visible')
    })

    it('should show table headers', () => {
      cy.get('th').contains('ID').should('be.visible')
      // Check that table has at least 5 header columns
      cy.get('th').should('have.length.at.least', 5)
    })

    it('should display trip ID (truncated)', () => {
      cy.get('tbody tr').first().find('td').first().should('contain', '...')
    })

    it('should display user email', () => {
      cy.get('tbody').should('contain', 'user1@example.com')
    })

    it('should display trip title', () => {
      cy.get('tbody').should('contain', 'Paris to Rome')
    })

    it('should display origin IATA code', () => {
      cy.get('tbody').should('contain', 'CDG')
    })

    it('should display destination IATA code', () => {
      cy.get('tbody').should('contain', 'FCO')
    })
  })

  describe('Status Badges', () => {
    it('should show badge for planned status', () => {
      cy.get('tbody').contains('planned').should('be.visible')
    })

    it('should show badge for draft status', () => {
      cy.get('tbody').contains('draft').should('be.visible')
    })

    it('should show badge for booked status', () => {
      cy.get('tbody').contains('booked').should('be.visible')
    })

    it('should show badge for cancelled status', () => {
      cy.get('tbody').contains('cancelled').should('be.visible')
    })
  })

  describe('Pagination', () => {
    it('should display pagination controls', () => {
      cy.contains('Page').should('be.visible')
    })

    it('should show total count', () => {
      cy.contains('sur 15 résultats').should('be.visible')
    })

    it('should show page info', () => {
      cy.contains('Page 1 sur 2').should('be.visible')
    })
  })

  describe('Empty State', () => {
    it('should show empty state when no trips', () => {
      cy.loginWithMock()
      cy.mockUsersAPI()
      cy.mockTripsAPI(true)
      cy.mockTravelersAPI()
      cy.mockHotelBookingsAPI()
      cy.mockFlightBookingsAPI()

      cy.visit('/dashboard')
      cy.contains('Trips').click()

      cy.contains('Aucune donnée disponible').should('be.visible')
    })
  })

  describe('Tab Count', () => {
    it('should show trip count in tab', () => {
      cy.contains('Trips').parent().should('contain', '15')
    })
  })
})
