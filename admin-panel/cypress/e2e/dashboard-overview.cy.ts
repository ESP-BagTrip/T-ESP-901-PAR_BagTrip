describe('Overview page', () => {
  beforeEach(() => {
    cy.login()
    cy.visit('/app')
  })

  it('shows the 4 KPI cards with labels', () => {
    cy.contains('UTILISATEURS').should('be.visible')
    cy.contains('VOYAGES').should('be.visible')
    cy.contains('REVENUS').should('be.visible')
    cy.contains('NOTE MOYENNE').should('be.visible')
  })

  it('drills down from a KPI card to its section', () => {
    cy.contains('a', 'UTILISATEURS').click()
    cy.url().should('include', '/app/users')
  })

  it('persists the date range to the URL when switching presets', () => {
    cy.contains('button', /jours|mois/).click()
    cy.contains('button', '7 derniers jours').click()
    cy.url().should('include', 'range=7d')
  })

  it('renders the growth, breakdown and activity sections', () => {
    cy.contains('Inscriptions utilisateurs').should('be.visible')
    cy.contains('Revenus capturés').should('be.visible')
    cy.contains('Statuts des voyages').should('be.visible')
    cy.contains('Distribution des notes').should('be.visible')
    cy.contains('Activité récente').should('be.visible')
  })
})
