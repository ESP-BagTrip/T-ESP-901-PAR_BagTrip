'use client'

import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { useAuth } from '@/hooks'
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
  } = useForm<LoginCredentials & RegisterCredentials>()

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
          <div className="rounded-md shadow-sm -space-y-px">
            <div>
              <label htmlFor="email" className="sr-only">
                Adresse email
              </label>
              <input
                {...register('email', {
                  required: "L'email est requis",
                  pattern: {
                    value: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
                    message: "Format d'email invalide",
                  },
                })}
                type="email"
                className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
                placeholder="Adresse email"
              />
              {errors.email && <p className="mt-1 text-sm text-red-600">{errors.email.message}</p>}
            </div>
            {isRegisterMode && (
              <>
                <div>
                  <label htmlFor="fullName" className="sr-only">
                    Nom complet
                  </label>
                  <input
                    {...register('fullName')}
                    type="text"
                    className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
                    placeholder="Nom complet (optionnel)"
                  />
                </div>
                <div>
                  <label htmlFor="phone" className="sr-only">
                    Téléphone
                  </label>
                  <input
                    {...register('phone')}
                    type="tel"
                    className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
                    placeholder="Téléphone (optionnel)"
                  />
                </div>
              </>
            )}
            <div>
              <label htmlFor="password" className="sr-only">
                Mot de passe
              </label>
              <div className="relative">
                <input
                  {...register('password', {
                    required: 'Le mot de passe est requis',
                    minLength: {
                      value: 6,
                      message: 'Le mot de passe doit contenir au moins 6 caractères',
                    },
                  })}
                  type={showPassword ? 'text' : 'password'}
                  className="appearance-none rounded-none relative block w-full px-3 py-2 pr-10 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
                  placeholder="Mot de passe"
                />
                <button
                  type="button"
                  className="absolute inset-y-0 right-0 pr-3 flex items-center"
                  onClick={() => setShowPassword(!showPassword)}
                >
                  {showPassword ? (
                    <svg
                      className="h-5 w-5 text-gray-400"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                      />
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                      />
                    </svg>
                  ) : (
                    <svg
                      className="h-5 w-5 text-gray-400"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L21 21"
                      />
                    </svg>
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

          <div>
            <button
              type="submit"
              disabled={isLoggingIn || isRegistering}
              className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
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
            </button>
          </div>

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
