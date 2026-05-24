// ***********************************************
// Custom commands for BagTrip admin E2E tests.
// ***********************************************

/**
 * UI-based login: fills and submits the /login form, waits for
 * the /app redirect. Uses ADMIN_EMAIL + ADMIN_PASSWORD env vars
 * with dev defaults.
 */
Cypress.Commands.add('login', (email?: string, password?: string) => {
  const adminEmail = email ?? Cypress.env('ADMIN_EMAIL') ?? 'admin@bagtrip.com'
  const adminPassword = password ?? Cypress.env('ADMIN_PASSWORD') ?? 'admin123'

  cy.visit('/login')
  cy.get('input#email').type(adminEmail)
  cy.get('input#password').type(adminPassword)
  cy.contains('button', 'Se connecter').click()
  cy.url().should('include', '/app')
})

/**
 * Visit a protected `/app/*` route, logging in first if necessary.
 */
Cypress.Commands.add('visitApp', (path: string = '/app') => {
  cy.getCookie('access_token').then(cookie => {
    if (!cookie) {
      cy.login()
    }
    cy.visit(path)
  })
})

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Cypress {
    interface Chainable {
      login(email?: string, password?: string): Chainable<void>
      visitApp(path?: string): Chainable<void>
    }
  }
}

export {}
