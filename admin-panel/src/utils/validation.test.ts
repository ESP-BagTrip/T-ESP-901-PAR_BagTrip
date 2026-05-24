import { describe, it, expect } from 'vitest'
import {
  validateEmail,
  validatePassword,
  validateRequired,
  validateMinLength,
  validateMaxLength,
} from './validation'

describe('validateEmail', () => {
  it('accepts a valid email', () => {
    expect(validateEmail('user@example.com')).toBe(true)
  })

  it('accepts email with subdomain', () => {
    expect(validateEmail('user@mail.example.com')).toBe(true)
  })

  it('rejects email longer than 254 characters', () => {
    const longLocal = 'a'.repeat(250)
    expect(validateEmail(`${longLocal}@example.com`)).toBe(false)
  })

  it('rejects email without @', () => {
    expect(validateEmail('userexample.com')).toBe(false)
  })

  it('rejects email with multiple @', () => {
    expect(validateEmail('user@foo@example.com')).toBe(false)
  })

  it('rejects email with empty local part', () => {
    expect(validateEmail('@example.com')).toBe(false)
  })

  it('rejects email with empty domain', () => {
    expect(validateEmail('user@')).toBe(false)
  })

  it('rejects email without dot in domain', () => {
    expect(validateEmail('user@localhost')).toBe(false)
  })

  it('accepts email with plus addressing', () => {
    expect(validateEmail('user+tag@example.com')).toBe(true)
  })

  it('accepts email with dots in local part', () => {
    expect(validateEmail('first.last@example.com')).toBe(true)
  })
})

describe('validatePassword', () => {
  it('accepts a valid password', () => {
    const result = validatePassword('Abcdef1!')
    expect(result.isValid).toBe(true)
    expect(result.errors).toHaveLength(0)
  })

  it('rejects a short password', () => {
    const result = validatePassword('Ab1!')
    expect(result.isValid).toBe(false)
    expect(result.errors).toContain('Le mot de passe doit contenir au moins 8 caractères')
  })

  it('rejects password without uppercase', () => {
    const result = validatePassword('abcdefg1!')
    expect(result.isValid).toBe(false)
    expect(result.errors).toContain('Le mot de passe doit contenir au moins une majuscule')
  })

  it('rejects password without lowercase', () => {
    const result = validatePassword('ABCDEFG1!')
    expect(result.isValid).toBe(false)
    expect(result.errors).toContain('Le mot de passe doit contenir au moins une minuscule')
  })

  it('rejects password without digit', () => {
    const result = validatePassword('Abcdefgh!')
    expect(result.isValid).toBe(false)
    expect(result.errors).toContain('Le mot de passe doit contenir au moins un chiffre')
  })

  it('rejects password without special character', () => {
    const result = validatePassword('Abcdefg1')
    expect(result.isValid).toBe(false)
    expect(result.errors).toContain('Le mot de passe doit contenir au moins un caractère spécial')
  })

  it('returns multiple errors for a terrible password', () => {
    const result = validatePassword('abc')
    expect(result.isValid).toBe(false)
    expect(result.errors.length).toBeGreaterThanOrEqual(3)
  })

  it('returns all 5 errors for empty string', () => {
    const result = validatePassword('')
    expect(result.isValid).toBe(false)
    expect(result.errors).toHaveLength(5)
  })

  it('accepts various special characters', () => {
    expect(validatePassword('Abcdefg1@').isValid).toBe(true)
    expect(validatePassword('Abcdefg1#').isValid).toBe(true)
    expect(validatePassword('Abcdefg1$').isValid).toBe(true)
    expect(validatePassword('Abcdefg1.').isValid).toBe(true)
    expect(validatePassword('Abcdefg1,').isValid).toBe(true)
  })
})

describe('validateRequired', () => {
  it('returns true for a non-empty string', () => {
    expect(validateRequired('hello')).toBe(true)
  })

  it('returns false for null', () => {
    expect(validateRequired(null)).toBe(false)
  })

  it('returns false for undefined', () => {
    expect(validateRequired(undefined)).toBe(false)
  })

  it('returns false for empty string', () => {
    expect(validateRequired('')).toBe(false)
  })

  it('returns false for whitespace-only string', () => {
    expect(validateRequired('   ')).toBe(false)
  })

  it('returns true for string with leading/trailing spaces', () => {
    expect(validateRequired('  hello  ')).toBe(true)
  })
})

describe('validateMinLength', () => {
  it('returns true when length equals minimum', () => {
    expect(validateMinLength('abc', 3)).toBe(true)
  })

  it('returns true when length exceeds minimum', () => {
    expect(validateMinLength('abcdef', 3)).toBe(true)
  })

  it('returns false when length is below minimum', () => {
    expect(validateMinLength('ab', 3)).toBe(false)
  })

  it('returns true for empty string with min 0', () => {
    expect(validateMinLength('', 0)).toBe(true)
  })
})

describe('validateMaxLength', () => {
  it('returns true when length equals maximum', () => {
    expect(validateMaxLength('abc', 3)).toBe(true)
  })

  it('returns true when length is below maximum', () => {
    expect(validateMaxLength('ab', 3)).toBe(true)
  })

  it('returns false when length exceeds maximum', () => {
    expect(validateMaxLength('abcd', 3)).toBe(false)
  })

  it('returns true for empty string with max 0', () => {
    expect(validateMaxLength('', 0)).toBe(true)
  })
})
