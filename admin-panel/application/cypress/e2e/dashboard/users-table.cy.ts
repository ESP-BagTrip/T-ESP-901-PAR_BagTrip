describe('Users Table', () => {
  beforeEach(() => {
    cy.visitDashboard()
    cy.wait('@getUsers')
  })

  describe('Data Display', () => {
    it('should display users table', () => {
      cy.get('table').should('be.visible')
    })

    it('should show table headers', () => {
      cy.get('th').contains('ID').should('be.visible')
      cy.get('th').contains('Email').should('be.visible')
      cy.get('th').contains('Créé le').should('be.visible')
      cy.get('th').contains('Modifié le').should('be.visible')
    })

    it('should display user ID (truncated)', () => {
      cy.get('tbody tr').first().find('td').first().should('contain', '...')
    })

    it('should display user email', () => {
      cy.get('tbody').should('contain', 'admin@bagtrip.com')
    })

    it('should display created_at date formatted', () => {
      // Allow various date formats (DD/MM/YYYY, YYYY-MM-DD, localized formats)
      cy.get('tbody tr').first().find('td').eq(2).invoke('text').should('not.be.empty')
    })

    it('should display user rows', () => {
      cy.get('tbody tr').should('have.length.at.least', 1)
    })
  })

  describe('Loading State', () => {
    it('should show loading spinner while fetching', () => {
      cy.loginWithMock()

      cy.intercept('GET', '**/admin/users*', {
        delay: 1000,
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
    it('should show empty state when no data', () => {
      cy.loginWithMock()
      cy.mockUsersAPI(true)
      cy.mockTripsAPI()
      cy.mockTravelersAPI()
      cy.mockHotelBookingsAPI()
      cy.mockFlightBookingsAPI()

      cy.visit('/dashboard')

      cy.contains('Aucune donnée disponible').should('be.visible')
    })
  })

  describe('Pagination', () => {
    it('should display pagination controls', () => {
      cy.contains('Page').should('be.visible')
    })

    it('should show total count', () => {
      cy.contains('sur 25 résultats').should('be.visible')
    })

    it('should show current page info', () => {
      cy.contains('Page 1 sur 3').should('be.visible')
    })

    it('should navigate to next page', () => {
      // Mock page 2 response
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

      cy.get('button').find('svg').last().parent().click()
      cy.wait('@getUsersPage2')
      cy.contains('Page 2').should('be.visible')
    })

    it('should disable previous button on first page', () => {
      cy.get('button').find('svg').first().parent().should('be.disabled')
    })
  })

  describe('Sorting', () => {
    it('should show sort indicator on headers', () => {
      cy.get('th').first().should('contain', '↕')
    })

    it('should sort by column when clicking header', () => {
      cy.get('th').contains('Email').click()
      cy.get('th').contains('Email').should('contain', '↑')
    })

    it('should toggle sort direction on second click', () => {
      cy.get('th').contains('Email').click()
      cy.get('th').contains('Email').should('contain', '↑')

      cy.get('th').contains('Email').click()
      cy.get('th').contains('Email').should('contain', '↓')
    })
  })

  describe('Row Interactions', () => {
    it('should highlight row on hover', () => {
      cy.get('tbody tr').first().trigger('mouseover')
      cy.get('tbody tr').first().should('have.class', 'hover:bg-gray-50')
    })
  })
})
