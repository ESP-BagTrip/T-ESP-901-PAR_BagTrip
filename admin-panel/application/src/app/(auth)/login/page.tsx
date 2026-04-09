'use client'

import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Eye, EyeOff } from 'lucide-react'
import { useAuth } from '@/hooks'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { loginSchema, registerSchema } from '@/lib/validations/auth'
import type { LoginCredentials, RegisterCredentials } from '@/types'

export default function LoginPage() {
  const {
    login,
    register: registerUser,
    isLoggingIn,
    isRegistering,
    loginError,
    registerError,
  } = useAuth()
  const [showPassword, setShowPassword] = useState(false)
  const [isRegisterMode, setIsRegisterMode] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginCredentials & RegisterCredentials>({
    resolver: zodResolver(isRegisterMode ? registerSchema : loginSchema),
  })

  const onSubmit = (data: LoginCredentials & RegisterCredentials) => {
    if (isRegisterMode) {
      registerUser({
        email: data.email,
        password: data.password,
        fullName: data.fullName,
        phone: data.phone,
      })
    } else {
      login({
        email: data.email,
        password: data.password,
      })
    }
  }

  const error = loginError || registerError

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">BagTrip Admin</h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            {isRegisterMode ? 'Créer un nouveau compte' : 'Connectez-vous à votre compte'}
          </p>
        </div>
        <form className="mt-8 space-y-6" onSubmit={handleSubmit(onSubmit)}>
          <div className="space-y-4">
            <div>
              <label htmlFor="email" className="sr-only">
                Adresse email
              </label>
              <Input {...register('email')} type="email" placeholder="Adresse email" />
              {errors.email && <p className="mt-1 text-sm text-red-600">{errors.email.message}</p>}
            </div>
            {isRegisterMode && (
              <>
                <div>
                  <label htmlFor="fullName" className="sr-only">
                    Nom complet
                  </label>
                  <Input
                    {...register('fullName')}
                    type="text"
                    placeholder="Nom complet (optionnel)"
                  />
                </div>
                <div>
                  <label htmlFor="phone" className="sr-only">
                    Téléphone
                  </label>
                  <Input {...register('phone')} type="tel" placeholder="Téléphone (optionnel)" />
                </div>
              </>
            )}
            <div>
              <label htmlFor="password" className="sr-only">
                Mot de passe
              </label>
              <div className="relative">
                <Input
                  {...register('password')}
                  type={showPassword ? 'text' : 'password'}
                  placeholder="Mot de passe"
                  className="pr-10"
                />
                <button
                  type="button"
                  className="absolute inset-y-0 right-0 pr-3 flex items-center"
                  onClick={() => setShowPassword(!showPassword)}
                >
                  {showPassword ? (
                    <Eye className="h-5 w-5 text-gray-400" />
                  ) : (
                    <EyeOff className="h-5 w-5 text-gray-400" />
                  )}
                </button>
              </div>
              {errors.password && (
                <p className="mt-1 text-sm text-red-600">{errors.password.message}</p>
              )}
            </div>
          </div>

          {error && (
            <div className="rounded-md bg-red-50 p-4">
              <div className="text-sm text-red-700">
                {error instanceof Error ? error.message : 'Une erreur est survenue'}
              </div>
            </div>
          )}

          <Button type="submit" className="w-full" disabled={isLoggingIn || isRegistering}>
            {isLoggingIn || isRegistering ? (
              <div className="flex items-center">
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                {isRegistering ? 'Inscription...' : 'Connexion...'}
              </div>
            ) : isRegisterMode ? (
              "S'inscrire"
            ) : (
              'Se connecter'
            )}
          </Button>

          <div className="text-center">
            <button
              type="button"
              onClick={() => setIsRegisterMode(!isRegisterMode)}
              className="text-sm text-blue-600 hover:text-blue-500"
            >
              {isRegisterMode
                ? 'Déjà un compte ? Se connecter'
                : "Pas encore de compte ? S'inscrire"}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
