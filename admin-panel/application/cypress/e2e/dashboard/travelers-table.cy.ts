describe('Travelers Table', () => {
  beforeEach(() => {
    cy.visitDashboard()
    cy.contains('Voyageurs').click()
    cy.wait('@getTravelers')
  })

  describe('Data Display', () => {
    it('should display travelers table', () => {
      cy.get('table').should('be.visible')
    })

    it('should show table headers', () => {
      cy.get('th').contains('ID').should('be.visible')
      cy.get('th').contains('Trip').should('be.visible')
      cy.get('th').contains('Prénom').should('be.visible')
      cy.get('th').contains('Nom').should('be.visible')
      cy.get('th').contains('Type').should('be.visible')
    })

    it('should display traveler ID', () => {
      cy.get('tbody tr').first().find('td').first().should('contain', '...')
    })

    it('should display trip title', () => {
      cy.get('tbody').should('contain', 'Paris to Rome')
    })

    it('should display first name', () => {
      cy.get('tbody').should('contain', 'John')
    })

    it('should display last name', () => {
      cy.get('tbody').should('contain', 'Doe')
    })
  })

  describe('Traveler Type Badges', () => {
    it('should show ADULT type badge', () => {
      cy.get('tbody').contains('ADULT').should('be.visible')
    })

    it('should show CHILD type badge', () => {
      cy.get('tbody').contains('CHILD').should('be.visible')
    })

    it('should show INFANT type badge', () => {
      cy.get('tbody').contains('INFANT').should('be.visible')
    })
  })

  describe('Pagination', () => {
    it('should display pagination info', () => {
      cy.contains('sur 10 résultats').should('be.visible')
    })
  })

  describe('Empty State', () => {
    it('should show empty state when no travelers', () => {
      cy.loginWithMock()
      cy.mockUsersAPI()
      cy.mockTripsAPI()
      cy.mockTravelersAPI(true)
      cy.mockHotelBookingsAPI()
      cy.mockFlightBookingsAPI()

      cy.visit('/dashboard')
      cy.contains('Voyageurs').click()

      cy.contains('Aucune donnée disponible').should('be.visible')
    })
  })

  describe('Tab Count', () => {
    it('should show travelers count in tab', () => {
      cy.contains('Voyageurs').parent().should('contain', '10')
    })
  })
})
