describe('Register Form', () => {
  beforeEach(() => {
    cy.visit('/login')
    cy.contains("Pas encore de compte ? S'inscrire").click()
  })

  describe('UI Elements', () => {
    it('should display registration mode subtitle', () => {
      cy.contains('Créer un nouveau compte').should('be.visible')
    })

    it('should display fullName input (optional)', () => {
      cy.get('input[placeholder="Nom complet (optionnel)"]').should('be.visible')
    })

    it('should display phone input (optional)', () => {
      cy.get('input[placeholder="Téléphone (optionnel)"]').should('be.visible')
    })

    it('should have register submit button', () => {
      cy.get('button[type="submit"]').contains("S'inscrire").should('be.visible')
    })

    it('should have link to switch to login mode', () => {
      cy.contains('Déjà un compte ? Se connecter').should('be.visible')
    })
  })

  describe('Form Validation', () => {
    it('should validate email format', () => {
      // Use a format that triggers browser validation for type="email"
      cy.get('input[placeholder="Adresse email"]').type('invalid@')
      cy.get('input[placeholder="Mot de passe"]').type('password123')
      cy.get('button[type="submit"]').click()
      // Browser shows native validation for type="email"
      cy.get('input[placeholder="Adresse email"]').then(($input) => {
        expect(($input[0] as HTMLInputElement).validity.valid).to.be.false
      })
    })

    it('should validate password minimum length', () => {
      cy.get('input[placeholder="Adresse email"]').type('test@example.com')
      cy.get('input[placeholder="Mot de passe"]').type('12345')
      cy.get('button[type="submit"]').click()
      cy.contains('Le mot de passe doit contenir au moins 6 caractères').should('be.visible')
    })

    it('should require email field', () => {
      cy.get('input[placeholder="Mot de passe"]').type('password123')
      cy.get('button[type="submit"]').click()
      cy.contains("L'email est requis").should('be.visible')
    })

    it('should require password field', () => {
      cy.get('input[placeholder="Adresse email"]').type('test@example.com')
      cy.get('button[type="submit"]').click()
      cy.contains('Le mot de passe est requis').should('be.visible')
    })
  })

  describe('Successful Registration Flow', () => {
    beforeEach(() => {
      cy.mockRegisterAPI(true)
      cy.mockCurrentUserAPI()
      cy.mockDashboardAPIs()
    })

    it('should successfully register with required fields only', () => {
      cy.get('input[placeholder="Adresse email"]').type('newuser@bagtrip.com')
      cy.get('input[placeholder="Mot de passe"]').type('password123')
      cy.get('button[type="submit"]').click()

      cy.wait('@registerRequest')
      cy.url().should('include', '/dashboard')
    })

    it('should successfully register with all fields', () => {
      cy.get('input[placeholder="Adresse email"]').type('newuser@bagtrip.com')
      cy.get('input[placeholder="Nom complet (optionnel)"]').type('John Doe')
      cy.get('input[placeholder="Téléphone (optionnel)"]').type('+33612345678')
      cy.get('input[placeholder="Mot de passe"]').type('password123')
      cy.get('button[type="submit"]').click()

      cy.wait('@registerRequest')
      cy.url().should('include', '/dashboard')
    })

    it('should redirect to dashboard after registration', () => {
      cy.get('input[placeholder="Adresse email"]').type('newuser@bagtrip.com')
      cy.get('input[placeholder="Mot de passe"]').type('password123')
      cy.get('button[type="submit"]').click()

      cy.url().should('include', '/dashboard')
    })

    it('should set auth-token cookie after registration', () => {
      cy.get('input[placeholder="Adresse email"]').type('newuser@bagtrip.com')
      cy.get('input[placeholder="Mot de passe"]').type('password123')
      cy.get('button[type="submit"]').click()

      cy.wait('@registerRequest')
      cy.getCookie('auth-token').should('exist')
    })
  })

  describe('Failed Registration Flow', () => {
    beforeEach(() => {
      cy.mockRegisterAPI(false)
    })

    it('should show error for existing email', () => {
      cy.get('input[placeholder="Adresse email"]').type('existing@bagtrip.com')
      cy.get('input[placeholder="Mot de passe"]').type('password123')
      cy.get('button[type="submit"]').click()

      cy.wait('@registerRequest')
      cy.get('.bg-red-50').should('be.visible')
    })
  })

  describe('Loading State', () => {
    it('should show loading state while registering', () => {
      cy.intercept('POST', '**/v1/auth/register', {
        delay: 1000,
        statusCode: 201,
        fixture: 'auth/register-success',
      }).as('slowRegister')

      cy.get('input[placeholder="Adresse email"]').type('newuser@bagtrip.com')
      cy.get('input[placeholder="Mot de passe"]').type('password123')
      cy.get('button[type="submit"]').click()

      cy.contains('Inscription...').should('be.visible')
      cy.get('button[type="submit"]').should('be.disabled')
    })
  })
})
