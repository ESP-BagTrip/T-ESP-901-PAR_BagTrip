export const validateEmail = (email: string): boolean => {
  if (email.length > 254) return false
  const parts = email.split('@')
  if (parts.length !== 2) return false
  const [local, domain] = parts
  return local.length > 0 && domain.length > 0 && domain.includes('.')
}

export const validatePassword = (
  password: string
): {
  isValid: boolean
  errors: string[]
} => {
  const errors: string[] = []

  if (password.length < 8) {
    errors.push('Le mot de passe doit contenir au moins 8 caractères')
  }

  if (!/[A-Z]/.test(password)) {
    errors.push('Le mot de passe doit contenir au moins une majuscule')
  }

  if (!/[a-z]/.test(password)) {
    errors.push('Le mot de passe doit contenir au moins une minuscule')
  }

  if (!/\d/.test(password)) {
    errors.push('Le mot de passe doit contenir au moins un chiffre')
  }

  if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
    errors.push('Le mot de passe doit contenir au moins un caractère spécial')
  }

  return {
    isValid: errors.length === 0,
    errors,
  }
}

export const validateRequired = (value: string | null | undefined): boolean => {
  return value !== null && value !== undefined && value.trim().length > 0
}

export const validateMinLength = (value: string, minLength: number): boolean => {
  return value.length >= minLength
}

export const validateMaxLength = (value: string, maxLength: number): boolean => {
  return value.length <= maxLength
}
