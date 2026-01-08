describe('Dashboard Navigation', () => {
  beforeEach(() => {
    cy.visitDashboard()
  })

  describe('Header', () => {
    it('should display BagTrip Admin title', () => {
      cy.get('nav').contains('BagTrip Admin').should('be.visible')
    })

    it('should show logged in user email', () => {
      cy.contains('Bonjour, admin@bagtrip.com').should('be.visible')
    })

    it('should have logout button', () => {
      cy.get('button').contains('Déconnexion').should('be.visible')
    })

    it('should have red logout button', () => {
      cy.get('button')
        .contains('Déconnexion')
        .should('have.class', 'bg-red-600')
    })
  })

  describe('Page Title', () => {
    it('should display Tableau de bord heading', () => {
      cy.get('h2').contains('Tableau de bord').should('be.visible')
    })
  })

  describe('Tabs Navigation', () => {
    it('should display all 5 tabs', () => {
      cy.contains('Utilisateurs').should('be.visible')
      cy.contains('Trips').should('be.visible')
      cy.contains('Voyageurs').should('be.visible')
      cy.contains('Réservations Hôtels').should('be.visible')
      cy.contains('Réservations Vols').should('be.visible')
    })

    it('should show Users tab as default active', () => {
      cy.contains('Utilisateurs')
        .should('have.class', 'border-blue-500')
        .and('have.class', 'text-blue-600')
    })

    it('should show tab counts from API', () => {
      cy.wait('@getUsers')
      cy.contains('Utilisateurs').parent().find('span').should('contain', '25')
    })

    it('should switch to Trips tab', () => {
      cy.contains('Trips').click()
      cy.contains('Trips')
        .should('have.class', 'border-blue-500')
        .and('have.class', 'text-blue-600')
    })

    it('should switch to Voyageurs tab', () => {
      cy.contains('Voyageurs').click()
      cy.contains('Voyageurs')
        .should('have.class', 'border-blue-500')
        .and('have.class', 'text-blue-600')
    })

    it('should switch to Reservations Hotels tab', () => {
      cy.contains('Réservations Hôtels').click()
      cy.contains('Réservations Hôtels')
        .should('have.class', 'border-blue-500')
        .and('have.class', 'text-blue-600')
    })

    it('should switch to Reservations Vols tab', () => {
      cy.contains('Réservations Vols').click()
      cy.contains('Réservations Vols')
        .should('have.class', 'border-blue-500')
        .and('have.class', 'text-blue-600')
    })
  })

  describe('Logout Flow', () => {
    it('should logout and redirect to login', () => {
      cy.get('button').contains('Déconnexion').click()
      cy.url().should('include', '/login')
    })

    it('should clear auth-token cookie on logout', () => {
      cy.get('button').contains('Déconnexion').click()
      cy.getCookie('auth-token').should('not.exist')
    })
  })

  describe('Protected Route', () => {
    it('should redirect to login without auth', () => {
      cy.clearCookies()
      cy.visit('/dashboard')
      cy.url().should('include', '/login')
    })
  })

  describe('Loading State', () => {
    it('should show loading spinner while fetching user', () => {
      cy.intercept('GET', '**/v1/auth/me', {
        delay: 1000,
        statusCode: 200,
        fixture: 'auth/current-user',
      }).as('slowUser')

      cy.loginWithMock()
      cy.mockDashboardAPIs()
      cy.visit('/dashboard')

      cy.get('.animate-spin').should('be.visible')
    })
  })
})
