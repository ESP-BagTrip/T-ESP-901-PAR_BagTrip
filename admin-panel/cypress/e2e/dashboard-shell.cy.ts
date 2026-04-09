describe('Dashboard shell', () => {
  beforeEach(() => {
    cy.login()
  })

  it('renders the sidebar with Overview highlighted', () => {
    cy.visit('/app')
    cy.get('aside[aria-label="Navigation principale"]').should('be.visible')
    cy.get('a[aria-current="page"]').should('contain', 'Overview')
  })

  it('navigates between sections via the sidebar', () => {
    cy.visit('/app')
    cy.contains('a', 'Utilisateurs').click()
    cy.url().should('include', '/app/users')
    cy.contains('h1', 'Utilisateurs').should('be.visible')

    cy.contains('a', 'Voyages').click()
    cy.url().should('include', '/app/trips')
    cy.contains('h1', 'Voyages').should('be.visible')
  })

  it('collapses and expands the sidebar', () => {
    cy.visit('/app')
    cy.get('aside[aria-label="Navigation principale"]').should(
      'have.attr',
      'data-collapsed',
      'false'
    )
    cy.get('button[aria-label="Replier la sidebar"]').click()
    cy.get('aside[aria-label="Navigation principale"]').should(
      'have.attr',
      'data-collapsed',
      'true'
    )
  })

  it('opens the command palette via Cmd+K and navigates', () => {
    cy.visit('/app')
    cy.get('body').type('{meta}k')
    cy.get('input[placeholder*="Tapez une commande"]').should('be.visible').type('users')
    cy.contains('[role="option"]', 'Utilisateurs').click()
    cy.url().should('include', '/app/users')
  })

  it('toggles the theme via the dropdown', () => {
    cy.visit('/app')
    cy.get('button[aria-label="Changer le thème"]').click()
    cy.contains('Sombre').click()
    cy.get('html').should('have.class', 'dark')
    cy.get('button[aria-label="Changer le thème"]').click()
    cy.contains('Clair').click()
    cy.get('html').should('not.have.class', 'dark')
  })
})
