import { z } from 'zod'

export const loginSchema = z.object({
  email: z.string().min(1, "L'email est requis").email("Format d'email invalide"),
  password: z
    .string()
    .min(1, 'Le mot de passe est requis')
    .min(6, 'Le mot de passe doit contenir au moins 6 caractères'),
})

export const registerSchema = loginSchema.extend({
  fullName: z.string().optional(),
  phone: z.string().optional(),
})

export type LoginFormValues = z.infer<typeof loginSchema>
export type RegisterFormValues = z.infer<typeof registerSchema>
