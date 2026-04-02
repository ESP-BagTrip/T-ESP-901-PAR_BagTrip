import { describe, it, expect } from 'vitest'
import { loginSchema, registerSchema } from '@/lib/validations/auth'

describe('loginSchema', () => {
  it('should validate a correct login', () => {
    const result = loginSchema.safeParse({ email: 'user@example.com', password: 'password123' })
    expect(result.success).toBe(true)
  })

  it('should reject missing email', () => {
    const result = loginSchema.safeParse({ email: '', password: 'password123' })
    expect(result.success).toBe(false)
    if (!result.success) {
      expect(result.error.issues[0].message).toBe("L'email est requis")
    }
  })

  it('should reject invalid email format', () => {
    const result = loginSchema.safeParse({ email: 'not-an-email', password: 'password123' })
    expect(result.success).toBe(false)
    if (!result.success) {
      expect(result.error.issues[0].message).toBe("Format d'email invalide")
    }
  })

  it('should reject missing password', () => {
    const result = loginSchema.safeParse({ email: 'user@example.com', password: '' })
    expect(result.success).toBe(false)
    if (!result.success) {
      expect(result.error.issues[0].message).toBe('Le mot de passe est requis')
    }
  })

  it('should reject short password', () => {
    const result = loginSchema.safeParse({ email: 'user@example.com', password: '12345' })
    expect(result.success).toBe(false)
    if (!result.success) {
      expect(result.error.issues[0].message).toBe(
        'Le mot de passe doit contenir au moins 6 caractères'
      )
    }
  })
})

describe('registerSchema', () => {
  it('should validate with all fields', () => {
    const result = registerSchema.safeParse({
      email: 'user@example.com',
      password: 'password123',
      fullName: 'John Doe',
      phone: '+33612345678',
    })
    expect(result.success).toBe(true)
  })

  it('should validate without optional fields', () => {
    const result = registerSchema.safeParse({
      email: 'user@example.com',
      password: 'password123',
    })
    expect(result.success).toBe(true)
  })

  it('should still enforce email and password from loginSchema', () => {
    const result = registerSchema.safeParse({ email: '', password: '' })
    expect(result.success).toBe(false)
  })
})
