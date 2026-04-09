'use client'

import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Eye, EyeOff } from 'lucide-react'
import { NotAdminError, useAuth } from '@/hooks'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { loginSchema } from '@/lib/validations/auth'
import type { LoginCredentials } from '@/types'

export default function LoginPage() {
  const { login, isLoggingIn, loginError } = useAuth()
  const [showPassword, setShowPassword] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginCredentials>({
    resolver: zodResolver(loginSchema),
  })

  const onSubmit = (data: LoginCredentials) => {
    login({
      email: data.email,
      password: data.password,
    })
  }

  const errorMessage = loginError
    ? loginError instanceof NotAdminError
      ? loginError.message
      : loginError instanceof Error
        ? loginError.message
        : 'Une erreur est survenue'
    : null

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">BagTrip Admin</h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Connectez-vous avec votre compte administrateur
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

          {errorMessage && (
            <div className="rounded-md bg-red-50 p-4">
              <div className="text-sm text-red-700">{errorMessage}</div>
            </div>
          )}

          <Button type="submit" className="w-full" disabled={isLoggingIn}>
            {isLoggingIn ? (
              <div className="flex items-center">
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                Connexion...
              </div>
            ) : (
              'Se connecter'
            )}
          </Button>
        </form>
      </div>
    </div>
  )
}
