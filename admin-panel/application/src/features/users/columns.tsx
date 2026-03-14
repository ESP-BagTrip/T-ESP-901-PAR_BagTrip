'use client'

import { useState } from 'react'
import type { ColumnDef } from '@tanstack/react-table'
import type { User } from '@/types'
import { safeFormatDate } from '@/utils/date'
import { adminService } from '@/services'
import { useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'

const PLAN_OPTIONS = ['FREE', 'PREMIUM', 'ADMIN'] as const

const planColors: Record<string, string> = {
  FREE: 'bg-gray-100 text-gray-700',
  PREMIUM: 'bg-amber-100 text-amber-700',
  ADMIN: 'bg-purple-100 text-purple-700',
}

function PlanCell({ userId, currentPlan }: { userId: string; currentPlan: string }) {
  const queryClient = useQueryClient()
  const [updating, setUpdating] = useState(false)

  const handleChange = async (newPlan: string) => {
    if (newPlan === currentPlan) return
    setUpdating(true)
    try {
      await adminService.updateUserPlan(userId, newPlan)
      toast.success(`Plan mis à jour : ${newPlan}`)
      queryClient.invalidateQueries({ queryKey: ['users'] })
    } catch {
      toast.error('Erreur lors de la mise à jour du plan')
    } finally {
      setUpdating(false)
    }
  }

  return (
    <select
      value={currentPlan}
      onChange={(e) => handleChange(e.target.value)}
      disabled={updating}
      className={`px-2 py-0.5 rounded-full text-xs font-medium border-0 cursor-pointer ${planColors[currentPlan] || planColors.FREE} ${updating ? 'opacity-50' : ''}`}
    >
      {PLAN_OPTIONS.map((plan) => (
        <option key={plan} value={plan}>
          {plan}
        </option>
      ))}
    </select>
  )
}

export const usersColumns: ColumnDef<User>[] = [
  {
    accessorKey: 'id',
    header: 'ID',
    cell: ({ row }) => (
      <span className="font-mono text-xs">{(row.getValue('id') as string).slice(0, 8)}...</span>
    ),
  },
  {
    accessorKey: 'email',
    header: 'Email',
    cell: ({ row }) => <span className="text-gray-900">{row.getValue('email')}</span>,
  },
  {
    accessorKey: 'plan',
    header: 'Plan',
    cell: ({ row }) => {
      const plan = (row.getValue('plan') as string) || 'FREE'
      const userId = row.getValue('id') as string
      return <PlanCell userId={userId} currentPlan={plan} />
    },
  },
  {
    accessorKey: 'created_at',
    header: 'Créé le',
    cell: ({ row }) => {
      const date = row.getValue('created_at') as string | null
      return (
        <span className="text-gray-500 text-xs">{safeFormatDate(date, 'dd/MM/yyyy HH:mm')}</span>
      )
    },
  },
  {
    accessorKey: 'updated_at',
    header: 'Modifié le',
    cell: ({ row }) => {
      const date = row.getValue('updated_at') as string | null
      return (
        <span className="text-gray-500 text-xs">{safeFormatDate(date, 'dd/MM/yyyy HH:mm')}</span>
      )
    },
  },
]
