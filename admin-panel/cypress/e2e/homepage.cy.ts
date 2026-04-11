describe('Homepage', () => {
  beforeEach(() => {
    cy.visit('/')
  })

  describe('Navigation', () => {
    it('should display the navigation bar correctly', () => {
      cy.get('[data-cy="logo"]').should('be.visible').and('contain', 'BagTrip')
      cy.get('[data-cy="login-btn"]').should('be.visible').and('contain', 'Connexion')
    })

    it('should navigate to login page', () => {
      cy.get('[data-cy="login-btn"]').click()
      cy.url().should('include', '/login')
    })
  })

  describe('Hero Section', () => {
    it('should display hero content', () => {
      cy.get('[data-cy="hero-title"]').should('be.visible').and('contain', 'BagTrip Administration')

      cy.get('[data-cy="hero-subtitle"]')
        .should('be.visible')
        .and('contain', "Plateforme d'administration complète")
    })

    it('should have working CTA button', () => {
      cy.get('[data-cy="cta-login"]')
        .should('be.visible')
        .and('contain', "Accéder à l'administration")

      // Test click on login CTA
      cy.get('[data-cy="cta-login"]').click()
      cy.url().should('include', '/login')
    })
  })

  describe('Stats Section', () => {
    it('should display statistics correctly', () => {
      cy.get('[data-cy="stats-title"]')
        .should('be.visible')
        .and('contain', 'Performances en temps réel')

      // Check that all 4 stats are displayed
      cy.get('[data-cy^="stat-"]').should('have.length', 4)

      // Verify specific stats content
      cy.get('[data-cy="stat-0"]').within(() => {
        cy.contains('12,543').should('be.visible')
        cy.contains('Utilisateurs actifs').should('be.visible')
        cy.contains('+12%').should('be.visible')
      })

      cy.get('[data-cy="stat-1"]').within(() => {
        cy.contains('8,247').should('be.visible')
        cy.contains('Voyages organisés').should('be.visible')
      })
    })
  })

  describe('Features Section', () => {
    it('should display features title', () => {
      cy.get('[data-cy="features-title"]')
        .should('be.visible')
        .and('contain', "Interface d'administration complète")
    })

    it('should switch between tabs', () => {
      // Features tab should be active by default
      cy.get('[data-cy="tab-features"]').should('have.class', 'bg-white')
      cy.get('[data-cy="features-grid"]').should('be.visible')

      // Switch to tech tab
      cy.get('[data-cy="tab-tech"]').click()
      cy.get('[data-cy="tab-tech"]').should('have.class', 'bg-white')
      cy.get('[data-cy="tech-stack"]').should('be.visible')
      cy.get('[data-cy="features-grid"]').should('not.exist')

      // Switch back to features tab
      cy.get('[data-cy="tab-features"]').click()
      cy.get('[data-cy="features-grid"]').should('be.visible')
      cy.get('[data-cy="tech-stack"]').should('not.exist')
    })

    it('should display all feature cards', () => {
      cy.get('[data-cy="features-grid"]').within(() => {
        cy.get('[data-cy^="feature-"]').should('have.length', 6)

        // Check first feature
        cy.get('[data-cy="feature-0"]').within(() => {
          cy.contains('👥').should('be.visible')
          cy.contains('Gestion Utilisateurs').should('be.visible')
          cy.contains('CRUD utilisateurs').should('be.visible')
        })

        // Check another feature
        cy.get('[data-cy="feature-3"]').within(() => {
          cy.contains('📊').should('be.visible')
          cy.contains('Analytics & BI').should('be.visible')
        })
      })
    })

    it('should display tech stack information', () => {
      cy.get('[data-cy="tab-tech"]').click()

      cy.get('[data-cy="tech-stack"]').within(() => {
        cy.contains('Frontend').should('be.visible')
        cy.contains('Backend & Infra').should('be.visible')
        cy.contains('Next.js 15').should('be.visible')
        cy.contains('TypeScript').should('be.visible')
        cy.contains('PostgreSQL').should('be.visible')
      })
    })
  })

  describe('CTA Section', () => {
    it('should display call-to-action section', () => {
      cy.get('[data-cy="cta-title"]')
        .should('be.visible')
        .and('contain', 'Prêt à découvrir BagTrip Admin')

      cy.get('[data-cy="final-cta-login"]').should('be.visible')
    })

    it('should navigate from final CTA', () => {
      cy.get('[data-cy="final-cta-login"]').click()
      cy.url().should('include', '/login')
    })
  })

  describe('Footer', () => {
    it('should display footer content', () => {
      cy.get('[data-cy="footer-links-title"]').should('contain', 'Liens utiles')

      // Check footer links
      cy.get('footer').within(() => {
        cy.contains('BagTrip').should('be.visible')
        cy.contains('Connexion').should('be.visible')
        cy.contains('admin@bagtrip.com').should('be.visible')
      })
    })
  })

  describe('Responsive Design', () => {
    it('should be responsive on mobile', () => {
      cy.viewport('iphone-x')

      // Check that elements are still visible
      cy.get('[data-cy="logo"]').should('be.visible')
      cy.get('[data-cy="hero-title"]').should('be.visible')
      cy.get('[data-cy="stats-title"]').should('be.visible')

      // Stats should stack on mobile
      cy.get('[data-cy^="stat-"]').should('have.length', 4)
    })

    it('should be responsive on tablet', () => {
      cy.viewport('ipad-2')

      cy.get('[data-cy="hero-title"]').should('be.visible')
      cy.get('[data-cy="features-grid"]').should('be.visible')
    })
  })

  describe('Accessibility', () => {
    it('should have proper heading hierarchy', () => {
      // Check H1 exists and is unique
      cy.get('h1').should('have.length', 1)
      cy.get('h1').should('contain', 'BagTrip Administration')

      // Check H2 headings
      cy.get('h2').should('exist')

      // Check H3 headings
      cy.get('h3').should('exist')
    })

    it('should have accessible links', () => {
      // All links should have meaningful text
      cy.get('a').each($link => {
        cy.wrap($link).should('not.be.empty')
      })
    })
  })

  describe('Performance', () => {
    it('should load quickly', () => {
      const start = Date.now()
      cy.visit('/').then(() => {
        const loadTime = Date.now() - start
        expect(loadTime).to.be.lessThan(8000) // Should load in less than 3 seconds
      })
    })
  })

  describe('SEO Elements', () => {
    it('should have proper meta information', () => {
      cy.get('head title').should('contain', 'BagTrip Admin')
    })
  })
})
