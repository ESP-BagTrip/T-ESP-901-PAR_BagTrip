describe('Users section — pagination & mutation', () => {
  beforeEach(() => {
    cy.login()
  })

  it('deep-links to a specific page via ?page=N', () => {
    cy.visit('/app/users?page=2')
    cy.url().should('include', 'page=2')
    cy.contains(/Page\s*2/).should('be.visible')
  })

  it('updates the URL when paginating', () => {
    cy.visit('/app/users')
    cy.get('button[aria-label="Page suivante"]').click()
    cy.url().should('include', 'page=2')
    cy.get('button[aria-label="Page précédente"]').click()
    cy.url().should('not.include', 'page=')
  })

  it('renders the users table with expected headers', () => {
    cy.visit('/app/users')
    cy.contains('th', /Email/i).should('be.visible')
    cy.contains('th', /Plan/i).should('be.visible')
  })
})
