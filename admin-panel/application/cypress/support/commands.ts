// ***********************************************
// This example commands.ts shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************

// Custom command to login as admin
Cypress.Commands.add('loginAsAdmin', () => {
  cy.request({
    method: 'POST',
    url: `${Cypress.env('API_URL') || 'http://localhost:3001/api'}/admin/auth/login`,
    body: {
      email: 'admin@bagtrip.com',
      password: 'admin123',
    },
  }).then((response) => {
    window.localStorage.setItem('admin_token', response.body.token)
  })
})

// Custom command to visit dashboard (requires login)
Cypress.Commands.add('visitDashboard', () => {
  cy.loginAsAdmin()
  cy.visit('/dashboard')
})

// Example of overwriting existing command
// Cypress.Commands.overwrite('visit', (originalFn, url, options) => { ... })