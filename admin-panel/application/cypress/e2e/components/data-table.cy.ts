describe('DataTable Component', () => {
  beforeEach(() => {
    cy.visitDashboard()
    cy.wait('@getUsers')
  })

  describe('Loading State', () => {
    it('should display loading spinner when loading', () => {
      cy.loginWithMock()

      cy.intercept('GET', '**/admin/users*', {
        delay: 2000,
        statusCode: 200,
        fixture: 'admin/users-list',
      }).as('slowUsers')

      cy.mockTripsAPI()
      cy.mockTravelersAPI()
      cy.mockHotelBookingsAPI()
      cy.mockFlightBookingsAPI()

      cy.visit('/dashboard')

      cy.get('.animate-spin').should('be.visible')
    })

    it('should show loading message', () => {
      cy.loginWithMock()

      cy.intercept('GET', '**/admin/users*', {
        delay: 2000,
        statusCode: 200,
        fixture: 'admin/users-list',
      }).as('slowUsers')

      cy.mockTripsAPI()
      cy.mockTravelersAPI()
      cy.mockHotelBookingsAPI()
      cy.mockFlightBookingsAPI()

      cy.visit('/dashboard')

      cy.contains('Chargement des données...').should('be.visible')
    })
  })

  describe('Empty State', () => {
    it('should display empty message when no data', () => {
      cy.loginWithMock()
      cy.mockUsersAPI(true)
      cy.mockTripsAPI()
      cy.mockTravelersAPI()
      cy.mockHotelBookingsAPI()
      cy.mockFlightBookingsAPI()

      cy.visit('/dashboard')

      cy.contains('Aucune donnée disponible').should('be.visible')
    })

    it('should show empty state in table body', () => {
      cy.loginWithMock()
      cy.mockUsersAPI(true)
      cy.mockTripsAPI()
      cy.mockTravelersAPI()
      cy.mockHotelBookingsAPI()
      cy.mockFlightBookingsAPI()

      cy.visit('/dashboard')

      cy.get('tbody').contains('Aucune donnée disponible').should('be.visible')
    })
  })

  describe('Data Rendering', () => {
    it('should render table element', () => {
      cy.get('table').should('be.visible')
    })

    it('should render table headers', () => {
      cy.get('thead').should('be.visible')
      cy.get('th').should('have.length.at.least', 1)
    })

    it('should render table rows', () => {
      cy.get('tbody tr').should('have.length.at.least', 1)
    })

    it('should render table cells', () => {
      cy.get('tbody td').should('have.length.at.least', 1)
    })

    it('should apply hover effect class on rows', () => {
      cy.get('tbody tr').first().should('have.class', 'hover:bg-gray-50')
    })
  })

  describe('Sorting', () => {
    it('should show sortable column indicator', () => {
      cy.get('th').first().should('contain', '↕')
    })

    it('should show cursor pointer on sortable headers', () => {
      cy.get('th').first().should('have.class', 'cursor-pointer')
    })

    it('should sort ascending on first click', () => {
      cy.get('th').contains('Email').click()
      cy.get('th').contains('Email').parent().should('contain', '↑')
    })

    it('should sort descending on second click', () => {
      cy.get('th').contains('Email').click()
      cy.get('th').contains('Email').click()
      cy.get('th').contains('Email').parent().should('contain', '↓')
    })

    it('should show sort direction indicator', () => {
      cy.get('th').contains('Email').click()
      cy.get('th').contains('Email').parent().find('span').should('contain', '↑')
    })

    it('should reset to default indicator on third click', () => {
      cy.get('th').contains('Email').click()
      cy.get('th').contains('Email').click()
      cy.get('th').contains('Email').click()
      cy.get('th').contains('Email').parent().should('contain', '↕')
    })
  })

  describe('Pagination', () => {
    it('should show page info', () => {
      cy.contains('Page 1 sur').should('be.visible')
    })

    it('should show results count', () => {
      cy.contains('résultats').should('be.visible')
    })

    it('should show display range', () => {
      cy.contains('Affichage de').should('be.visible')
    })

    it('should have previous button', () => {
      cy.get('nav[aria-label="Pagination"] button').first().should('exist')
    })

    it('should have next button', () => {
      cy.get('nav[aria-label="Pagination"] button').last().should('exist')
    })

    it('should disable previous on first page', () => {
      cy.get('nav[aria-label="Pagination"] button').first().should('be.disabled')
    })

    it('should enable next when more pages', () => {
      cy.get('nav[aria-label="Pagination"] button').last().should('not.be.disabled')
    })

    it('should navigate to next page', () => {
      // Mock page 2 response with correct format
      cy.intercept('GET', '**/admin/users*page=2*', {
        statusCode: 200,
        body: {
          items: [{ id: 'user-page2', email: 'page2@test.com', created_at: '2024-01-01T00:00:00Z', updated_at: null }],
          total: 25,
          page: 2,
          limit: 10,
          total_pages: 3,
        },
      }).as('getUsersPage2')

      cy.get('nav[aria-label="Pagination"] button').last().click()
      cy.wait('@getUsersPage2')
      cy.contains('Page 2').should('be.visible')
    })

    it('should navigate back to previous page', () => {
      // Mock page 2 response with correct format
      cy.intercept('GET', '**/admin/users*page=2*', {
        statusCode: 200,
        body: {
          items: [{ id: 'user-page2', email: 'page2@test.com', created_at: '2024-01-01T00:00:00Z', updated_at: null }],
          total: 25,
          page: 2,
          limit: 10,
          total_pages: 3,
        },
      }).as('getUsersPage2')

      cy.get('nav[aria-label="Pagination"] button').last().click()
      cy.wait('@getUsersPage2')
      cy.contains('Page 2').should('be.visible')

      // Now go back to page 1
      cy.get('nav[aria-label="Pagination"] button').first().click()
      cy.wait('@getUsers')
      cy.contains('Page 1').should('be.visible')
    })
  })

  describe('Responsive Design', () => {
    it('should show mobile pagination on small screens', () => {
      cy.viewport('iphone-6')
      cy.visitDashboard()
      cy.wait('@getUsers')

      cy.contains('Précédent').should('be.visible')
      cy.contains('Suivant').should('be.visible')
    })

    it('should show desktop pagination on large screens', () => {
      cy.viewport(1280, 720)

      cy.get('nav[aria-label="Pagination"]').should('be.visible')
    })

    it('should hide desktop pagination on mobile', () => {
      cy.viewport('iphone-6')
      cy.visitDashboard()
      cy.wait('@getUsers')

      cy.get('.sm\\:hidden').should('be.visible')
    })
  })

  describe('Table Styling', () => {
    it('should have white background on table', () => {
      cy.get('.bg-white').should('exist')
    })

    it('should have rounded corners', () => {
      cy.get('.rounded-lg').should('exist')
    })

    it('should have shadow', () => {
      cy.get('.shadow').should('exist')
    })

    it('should have gray header background', () => {
      cy.get('thead').should('have.class', 'bg-gray-50')
    })
  })
})
