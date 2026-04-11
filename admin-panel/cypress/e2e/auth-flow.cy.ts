describe('Auth flow', () => {
  it('redirects unauthenticated /app visits to /login', () => {
    cy.clearCookies()
    cy.visit('/app', { failOnStatusCode: false })
    cy.url().should('include', '/login')
  })

  it('legacy /dashboard URLs redirect (308) to /app', () => {
    cy.request({ url: '/dashboard', followRedirect: false, failOnStatusCode: false }).then(res => {
      expect(res.status).to.eq(308)
      expect(res.redirectedToUrl).to.match(/\/app$/)
    })
  })

  it('logs in via the form and lands on /app', () => {
    cy.login()
    cy.location('pathname').should('eq', '/app')
    cy.contains('Overview').should('be.visible')
  })

  it('logs out and bounces back to /login', () => {
    cy.login()
    cy.visit('/app/settings')
    cy.contains('button', 'Se déconnecter').click()
    cy.url().should('include', '/login')
  })
})
