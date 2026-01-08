describe('Login Page', () => {
  beforeEach(() => {
    cy.visit('/login')
  })

  describe('UI Elements', () => {
    it('should display BagTrip Admin title', () => {
      cy.contains('h2', 'BagTrip Admin').should('be.visible')
    })

    it('should display login mode subtitle by default', () => {
      cy.contains('Connectez-vous à votre compte').should('be.visible')
    })

    it('should have email input field', () => {
      cy.get('input[placeholder="Adresse email"]').should('be.visible')
    })

    it('should have password input field', () => {
      cy.get('input[placeholder="Mot de passe"]').should('be.visible')
    })

    it('should have submit button with login text', () => {
      cy.get('button[type="submit"]').contains('Se connecter').should('be.visible')
    })

    it('should have password visibility toggle button', () => {
      cy.get('input[placeholder="Mot de passe"]').parent().find('button').should('exist')
    })

    it('should have link to switch to register mode', () => {
      cy.contains("Pas encore de compte ? S'inscrire").should('be.visible')
    })
  })

  describe('Password Visibility Toggle', () => {
    it('should show password as hidden by default', () => {
      cy.get('input[placeholder="Mot de passe"]').should('have.attr', 'type', 'password')
    })

    it('should toggle password visibility when clicking toggle button', () => {
      const passwordInput = cy.get('input[placeholder="Mot de passe"]')
      passwordInput.should('have.attr', 'type', 'password')

      cy.get('input[placeholder="Mot de passe"]').parent().find('button').click()
      cy.get('input[placeholder="Mot de passe"]').should('have.attr', 'type', 'text')

      cy.get('input[placeholder="Mot de passe"]').parent().find('button').click()
      cy.get('input[placeholder="Mot de passe"]').should('have.attr', 'type', 'password')
    })
  })

  describe('Form Validation', () => {
    it('should show error for empty email when submitting', () => {
      cy.get('input[placeholder="Mot de passe"]').type('password123')
      cy.get('button[type="submit"]').click()
      cy.contains("L'email est requis").should('be.visible')
    })

    it('should show error for invalid email format', () => {
      // Use a format that passes browser validation but fails regex
      cy.get('input[placeholder="Adresse email"]').type('invalid@')
      cy.get('input[placeholder="Mot de passe"]').type('password123')
      cy.get('button[type="submit"]').click()
      // Browser shows native validation for type="email"
      cy.get('input[placeholder="Adresse email"]').then(($input) => {
        expect(($input[0] as HTMLInputElement).validity.valid).to.be.false
      })
    })

    it('should show error for empty password when submitting', () => {
      cy.get('input[placeholder="Adresse email"]').type('test@example.com')
      cy.get('button[type="submit"]').click()
      cy.contains('Le mot de passe est requis').should('be.visible')
    })

    it('should show error for password less than 6 characters', () => {
      cy.get('input[placeholder="Adresse email"]').type('test@example.com')
      cy.get('input[placeholder="Mot de passe"]').type('12345')
      cy.get('button[type="submit"]').click()
      cy.contains('Le mot de passe doit contenir au moins 6 caractères').should('be.visible')
    })
  })

  describe('Successful Login Flow', () => {
    beforeEach(() => {
      cy.mockLoginAPI(true)
      cy.mockCurrentUserAPI()
      cy.mockDashboardAPIs()
    })

    it('should successfully login with valid credentials', () => {
      cy.get('input[placeholder="Adresse email"]').type('admin@bagtrip.com')
      cy.get('input[placeholder="Mot de passe"]').type('admin123')
      cy.get('button[type="submit"]').click()

      cy.wait('@loginRequest')
      cy.url().should('include', '/dashboard')
    })

    it('should redirect to dashboard after successful login', () => {
      cy.get('input[placeholder="Adresse email"]').type('admin@bagtrip.com')
      cy.get('input[placeholder="Mot de passe"]').type('admin123')
      cy.get('button[type="submit"]').click()

      cy.url().should('include', '/dashboard')
    })

    it('should set auth-token cookie after login', () => {
      cy.get('input[placeholder="Adresse email"]').type('admin@bagtrip.com')
      cy.get('input[placeholder="Mot de passe"]').type('admin123')
      cy.get('button[type="submit"]').click()

      cy.wait('@loginRequest')
      cy.getCookie('auth-token').should('exist')
    })
  })

  describe('Failed Login Flow', () => {
    beforeEach(() => {
      cy.mockLoginAPI(false)
    })

    it('should show error message for invalid credentials', () => {
      cy.get('input[placeholder="Adresse email"]').type('wrong@example.com')
      cy.get('input[placeholder="Mot de passe"]').type('wrongpassword')
      cy.get('button[type="submit"]').click()

      cy.wait('@loginRequest')
      // Error is displayed with text-red-700 class in a bg-red-50 container
      cy.get('.text-red-700').should('be.visible')
    })
  })

  describe('Loading State', () => {
    it('should show loading state while logging in', () => {
      cy.intercept('POST', '**/v1/auth/login', {
        delay: 1000,
        statusCode: 200,
        fixture: 'auth/login-success',
      }).as('slowLogin')

      cy.get('input[placeholder="Adresse email"]').type('admin@bagtrip.com')
      cy.get('input[placeholder="Mot de passe"]').type('admin123')
      cy.get('button[type="submit"]').click()

      cy.contains('Connexion...').should('be.visible')
      cy.get('button[type="submit"]').should('be.disabled')
    })
  })

  describe('Mode Switching', () => {
    it('should switch to register mode when clicking link', () => {
      cy.contains("Pas encore de compte ? S'inscrire").click()
      cy.contains('Créer un nouveau compte').should('be.visible')
      cy.get('button[type="submit"]').contains("S'inscrire").should('be.visible')
    })

    it('should show additional fields in register mode', () => {
      cy.contains("Pas encore de compte ? S'inscrire").click()
      cy.get('input[placeholder="Nom complet (optionnel)"]').should('be.visible')
      cy.get('input[placeholder="Téléphone (optionnel)"]').should('be.visible')
    })

    it('should switch back to login mode', () => {
      cy.contains("Pas encore de compte ? S'inscrire").click()
      cy.contains('Déjà un compte ? Se connecter').click()
      cy.contains('Connectez-vous à votre compte').should('be.visible')
    })
  })

  describe('Protected Route Redirect', () => {
    it('should allow visiting login page even when authenticated', () => {
      // App doesn't automatically redirect authenticated users from login page
      cy.loginWithMock()
      cy.mockDashboardAPIs()
      cy.visit('/login')
      // Login page should still be accessible
      cy.contains('BagTrip Admin').should('be.visible')
    })
  })
})
