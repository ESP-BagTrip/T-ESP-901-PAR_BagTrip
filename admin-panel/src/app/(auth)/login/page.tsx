'use client'

import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Eye, EyeOff, Loader2 } from 'lucide-react'

import { NotAdminError, useAuth } from '@/hooks'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Alert, AlertDescription } from '@/components/ui/alert'
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
    login({ email: data.email, password: data.password })
  }

  const errorMessage = loginError
    ? loginError instanceof NotAdminError
      ? loginError.message
      : loginError instanceof Error
        ? loginError.message
        : 'Une erreur est survenue'
    : null

  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4 py-12 sm:px-6 lg:px-8">
      <div className="w-full max-w-sm space-y-8">
        <header className="space-y-2 text-center">
          <h1 className="text-2xl font-semibold tracking-tight text-foreground">
            BagTrip{' '}
            <span className="font-mono text-xs uppercase tracking-wider text-muted-foreground">
              Admin
            </span>
          </h1>
          <p className="text-sm text-muted-foreground">
            Connectez-vous avec votre compte administrateur.
          </p>
        </header>

        <form className="space-y-4" onSubmit={handleSubmit(onSubmit)} noValidate>
          <div className="space-y-1.5">
            <Label htmlFor="email">Email</Label>
            <Input
              id="email"
              {...register('email')}
              type="email"
              placeholder="you@bagtrip.app"
              autoComplete="email"
              aria-invalid={!!errors.email}
            />
            {errors.email && <p className="text-xs text-destructive">{errors.email.message}</p>}
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="password">Mot de passe</Label>
            <div className="relative">
              <Input
                id="password"
                {...register('password')}
                type={showPassword ? 'text' : 'password'}
                placeholder="••••••••"
                autoComplete="current-password"
                aria-invalid={!!errors.password}
                className="pr-10"
              />
              <button
                type="button"
                aria-label={showPassword ? 'Masquer le mot de passe' : 'Afficher le mot de passe'}
                onClick={() => setShowPassword(!showPassword)}
                className="absolute inset-y-0 right-0 flex items-center pr-3 text-muted-foreground hover:text-foreground focus-visible:outline-none focus-visible:text-foreground"
              >
                {showPassword ? <Eye className="size-4" /> : <EyeOff className="size-4" />}
              </button>
            </div>
            {errors.password && (
              <p className="text-xs text-destructive">{errors.password.message}</p>
            )}
          </div>

          {errorMessage && (
            <Alert variant="destructive">
              <AlertDescription>{errorMessage}</AlertDescription>
            </Alert>
          )}

          <Button type="submit" className="w-full" disabled={isLoggingIn}>
            {isLoggingIn ? (
              <>
                <Loader2 className="size-4 animate-spin" />
                Connexion…
              </>
            ) : (
              'Se connecter'
            )}
          </Button>
        </form>
      </div>
    </div>
  )
}
