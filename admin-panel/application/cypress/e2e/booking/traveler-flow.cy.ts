describe('Traveler Management', () => {
  beforeEach(() => {
    cy.loginWithMock()
    cy.mockDashboardAPIs()
    cy.mockTripCreation()
    cy.mockTravelerCreation()
    cy.visit('/test')

    // Wait for authentication to complete and page to show content
    cy.wait('@getCurrentUser')
    cy.contains('Test View - Booking Flow', { timeout: 10000 }).should('be.visible')

    // First create a trip
    cy.contains('2. Create Trip').click()
    cy.contains('Créer un Trip (Paris → Rome)').click()
    cy.wait('@createTrip')
  })

  describe('Add Traveler Section', () => {
    it('should display Add Traveler section', () => {
      cy.contains('3. Add Traveler').should('be.visible')
    })

    it('should have add traveler button', () => {
      cy.contains('3. Add Traveler').click()
      cy.contains('Ajouter un Traveler').should('be.visible')
    })
  })

  describe('Traveler Creation', () => {
    it('should add traveler successfully', () => {
      cy.contains('3. Add Traveler').click()
      cy.contains('Ajouter un Traveler').click()

      cy.wait('@createTraveler')
      cy.contains('Traveler créé:').should('be.visible')
    })

    it('should display traveler info', () => {
      cy.contains('3. Add Traveler').click()
      cy.contains('Ajouter un Traveler').click()

      cy.wait('@createTraveler')
      cy.contains('ID:').should('be.visible')
    })

    it('should show traveler name', () => {
      cy.contains('3. Add Traveler').click()
      cy.contains('Ajouter un Traveler').click()

      cy.wait('@createTraveler')
      cy.contains('John Doe').should('be.visible')
    })
  })

  describe('Traveler Button State', () => {
    it('should enable button after trip creation', () => {
      cy.contains('3. Add Traveler').click()
      cy.contains('Ajouter un Traveler').should('not.be.disabled')
    })
  })
})

describe('Traveler Without Trip', () => {
  beforeEach(() => {
    cy.loginWithMock()
    cy.mockDashboardAPIs()
    cy.visit('/test')
    cy.wait('@getCurrentUser')
    cy.contains('Test View - Booking Flow', { timeout: 10000 }).should('be.visible')
  })

  it('should disable add traveler button without trip', () => {
    cy.contains('3. Add Traveler').click()
    cy.contains('Ajouter un Traveler').should('be.disabled')
  })
})
