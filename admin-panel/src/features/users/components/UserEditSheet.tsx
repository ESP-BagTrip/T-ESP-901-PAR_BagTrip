'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from '@/components/ui/sheet'
import { useUpdateUser } from '@/features/users/mutations'
import type { AdminUserDetail } from '@/types/admin'

const schema = z.object({
  email: z.string().email().optional(),
  full_name: z.string().optional(),
  phone: z.string().optional(),
  plan: z.enum(['FREE', 'PREMIUM', 'ADMIN']).optional(),
})

type FormValues = z.infer<typeof schema>

interface UserEditSheetProps {
  user: AdminUserDetail | null
  open: boolean
  onClose: () => void
}

export function UserEditSheet({ user, open, onClose }: UserEditSheetProps) {
  const mutation = useUpdateUser(user?.id ?? '')

  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    values: user
      ? {
          email: user.email,
          full_name: user.full_name ?? '',
          phone: user.phone ?? '',
          plan: user.plan as 'FREE' | 'PREMIUM' | 'ADMIN',
        }
      : undefined,
  })

  const onSubmit = (data: FormValues) => {
    const updates: Record<string, unknown> = {}
    if (data.email && data.email !== user?.email) updates.email = data.email
    if (data.full_name !== (user?.full_name ?? '')) updates.full_name = data.full_name || null
    if (data.phone !== (user?.phone ?? '')) updates.phone = data.phone || null
    if (data.plan && data.plan !== user?.plan) updates.plan = data.plan

    if (Object.keys(updates).length === 0) {
      onClose()
      return
    }

    mutation.mutate(updates, { onSuccess: () => onClose() })
  }

  return (
    <Sheet open={open} onOpenChange={next => !next && onClose()}>
      <SheetContent className="sm:max-w-md">
        <SheetHeader>
          <SheetTitle>Modifier l&apos;utilisateur</SheetTitle>
          <SheetDescription>{user?.email}</SheetDescription>
        </SheetHeader>

        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4 py-4">
          <div className="space-y-1.5">
            <Label htmlFor="email">Email</Label>
            <Input id="email" {...form.register('email')} />
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="full_name">Nom complet</Label>
            <Input id="full_name" {...form.register('full_name')} />
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="phone">Téléphone</Label>
            <Input id="phone" {...form.register('phone')} />
          </div>

          <div className="space-y-1.5">
            <Label>Plan</Label>
            <Select
              value={form.watch('plan')}
              onValueChange={v => form.setValue('plan', v as 'FREE' | 'PREMIUM' | 'ADMIN')}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="FREE">FREE</SelectItem>
                <SelectItem value="PREMIUM">PREMIUM</SelectItem>
                <SelectItem value="ADMIN">ADMIN</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <SheetFooter>
            <Button type="button" variant="outline" onClick={onClose}>
              Annuler
            </Button>
            <Button type="submit" disabled={mutation.isPending}>
              {mutation.isPending ? 'Enregistrement…' : 'Enregistrer'}
            </Button>
          </SheetFooter>
        </form>
      </SheetContent>
    </Sheet>
  )
}
