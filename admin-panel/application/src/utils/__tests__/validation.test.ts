import { describe, it, expect } from 'vitest'
import {
  validateEmail,
  validatePassword,
  validateRequired,
  validateMinLength,
  validateMaxLength,
} from '../validation'

describe('validation utilities', () => {
  describe('validateEmail', () => {
    it('returns true for valid email', () => {
      expect(validateEmail('test@example.com')).toBe(true)
    })

    it('returns true for email with subdomain', () => {
      expect(validateEmail('user@mail.example.com')).toBe(true)
    })

    it('returns false for email without @', () => {
      expect(validateEmail('testexample.com')).toBe(false)
    })

    it('returns false for email without domain', () => {
      expect(validateEmail('test@')).toBe(false)
    })

    it('returns false for email without local part', () => {
      expect(validateEmail('@example.com')).toBe(false)
    })

    it('returns false for email with spaces', () => {
      expect(validateEmail('test @example.com')).toBe(false)
    })

    it('returns false for empty string', () => {
      expect(validateEmail('')).toBe(false)
    })
  })

  describe('validatePassword', () => {
    it('returns valid for strong password', () => {
      const result = validatePassword('MyP@ssw0rd')
      expect(result.isValid).toBe(true)
      expect(result.errors).toHaveLength(0)
    })

    it('returns error for password shorter than 8 characters', () => {
      const result = validatePassword('Ab1!')
      expect(result.isValid).toBe(false)
      expect(result.errors).toContain('Le mot de passe doit contenir au moins 8 caractères')
    })

    it('returns error for password without uppercase', () => {
      const result = validatePassword('myp@ssw0rd')
      expect(result.isValid).toBe(false)
      expect(result.errors).toContain('Le mot de passe doit contenir au moins une majuscule')
    })

    it('returns error for password without lowercase', () => {
      const result = validatePassword('MYP@SSW0RD')
      expect(result.isValid).toBe(false)
      expect(result.errors).toContain('Le mot de passe doit contenir au moins une minuscule')
    })

    it('returns error for password without digit', () => {
      const result = validatePassword('MyP@ssword')
      expect(result.isValid).toBe(false)
      expect(result.errors).toContain('Le mot de passe doit contenir au moins un chiffre')
    })

    it('returns error for password without special character', () => {
      const result = validatePassword('MyPassw0rd')
      expect(result.isValid).toBe(false)
      expect(result.errors).toContain('Le mot de passe doit contenir au moins un caractère spécial')
    })

    it('returns multiple errors for very weak password', () => {
      const result = validatePassword('abc')
      expect(result.isValid).toBe(false)
      expect(result.errors.length).toBeGreaterThan(1)
    })
  })

  describe('validateRequired', () => {
    it('returns true for non-empty string', () => {
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

    it('returns true for string with leading/trailing spaces but content', () => {
      expect(validateRequired('  hello  ')).toBe(true)
    })
  })

  describe('validateMinLength', () => {
    it('returns true when string meets minimum length', () => {
      expect(validateMinLength('hello', 5)).toBe(true)
    })

    it('returns true when string exceeds minimum length', () => {
      expect(validateMinLength('hello world', 5)).toBe(true)
    })

    it('returns false when string is shorter than minimum', () => {
      expect(validateMinLength('hi', 5)).toBe(false)
    })

    it('returns true for empty string with minLength 0', () => {
      expect(validateMinLength('', 0)).toBe(true)
    })
  })

  describe('validateMaxLength', () => {
    it('returns true when string meets maximum length', () => {
      expect(validateMaxLength('hello', 5)).toBe(true)
    })

    it('returns true when string is shorter than maximum', () => {
      expect(validateMaxLength('hi', 5)).toBe(true)
    })

    it('returns false when string exceeds maximum length', () => {
      expect(validateMaxLength('hello world', 5)).toBe(false)
    })

    it('returns true for empty string', () => {
      expect(validateMaxLength('', 5)).toBe(true)
    })
  })
})
