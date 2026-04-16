import { describe, it, expect } from 'vitest'
import { loginSchema } from './auth'

describe('loginSchema', () => {
  describe('email field', () => {
    it('accepts a valid email', () => {
      const result = loginSchema.safeParse({ email: 'user@example.com', password: 'secret123' })
      expect(result.success).toBe(true)
    })

    it('rejects empty email', () => {
      const result = loginSchema.safeParse({ email: '', password: 'secret123' })
      expect(result.success).toBe(false)
      if (!result.success) {
        const emailErrors = result.error.issues.filter(i => i.path.includes('email'))
        expect(emailErrors.length).toBeGreaterThan(0)
        expect(emailErrors[0].message).toBe("L'email est requis")
      }
    })

    it('rejects invalid email format', () => {
      const result = loginSchema.safeParse({ email: 'not-an-email', password: 'secret123' })
      expect(result.success).toBe(false)
      if (!result.success) {
        const emailErrors = result.error.issues.filter(i => i.path.includes('email'))
        expect(emailErrors.some(e => e.message === "Format d'email invalide")).toBe(true)
      }
    })

    it('rejects missing email field', () => {
      const result = loginSchema.safeParse({ password: 'secret123' })
      expect(result.success).toBe(false)
    })
  })

  describe('password field', () => {
    it('accepts a valid password of 6+ characters', () => {
      const result = loginSchema.safeParse({ email: 'user@example.com', password: 'abcdef' })
      expect(result.success).toBe(true)
    })

    it('rejects empty password', () => {
      const result = loginSchema.safeParse({ email: 'user@example.com', password: '' })
      expect(result.success).toBe(false)
      if (!result.success) {
        const pwErrors = result.error.issues.filter(i => i.path.includes('password'))
        expect(pwErrors.length).toBeGreaterThan(0)
        expect(pwErrors[0].message).toBe('Le mot de passe est requis')
      }
    })

    it('rejects password shorter than 6 characters', () => {
      const result = loginSchema.safeParse({ email: 'user@example.com', password: 'abc' })
      expect(result.success).toBe(false)
      if (!result.success) {
        const pwErrors = result.error.issues.filter(i => i.path.includes('password'))
        expect(
          pwErrors.some(e => e.message === 'Le mot de passe doit contenir au moins 6 caractères')
        ).toBe(true)
      }
    })

    it('rejects missing password field', () => {
      const result = loginSchema.safeParse({ email: 'user@example.com' })
      expect(result.success).toBe(false)
    })

    it('accepts password of exactly 6 characters', () => {
      const result = loginSchema.safeParse({ email: 'user@example.com', password: '123456' })
      expect(result.success).toBe(true)
    })
  })

  describe('combined validation', () => {
    it('rejects when both fields are empty', () => {
      const result = loginSchema.safeParse({ email: '', password: '' })
      expect(result.success).toBe(false)
      if (!result.success) {
        expect(result.error.issues.length).toBeGreaterThanOrEqual(2)
      }
    })

    it('parses and returns typed data on success', () => {
      const result = loginSchema.safeParse({ email: 'a@b.com', password: 'mypassword' })
      expect(result.success).toBe(true)
      if (result.success) {
        expect(result.data).toEqual({ email: 'a@b.com', password: 'mypassword' })
      }
    })
  })
})
