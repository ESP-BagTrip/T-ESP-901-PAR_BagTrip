'use client'

import { useRouter } from 'next/navigation'
import { useState } from 'react'
import { Download, Eye, Pencil, Trash2 } from 'lucide-react'

import { DataTable } from '@/components/DataTable'
import { DataTableToolbar, type FilterConfig } from '@/components/DataTableToolbar'
import { ConfirmDialog } from '@/components/ConfirmDialog'
import { RowActions, type RowAction } from '@/components/RowActions'
import { PageHeader } from '@/components/layout/PageHeader'
import { Button } from '@/components/ui/button'
import { useUsersTab } from '@/features/users/hooks'
import { useDeleteUser } from '@/features/users/mutations'
import { usersColumns } from '@/features/users/columns'
import type { User } from '@/types'

const PLAN_FILTERS: FilterConfig[] = [
  {
    key: 'plan',
    label: 'Plan',
    options: [
      { value: 'FREE', label: 'Free' },
      { value: 'PREMIUM', label: 'Premium' },
      { value: 'ADMIN', label: 'Admin' },
    ],
  },
]

export default function UsersPage() {
  const {
    rows,
    isLoading,
    page,
    limit,
    total,
    total_pages,
    setPage,
    search,
    setSearch,
    filters,
    setFilter,
    resetFilters,
  } = useUsersTab()

  const router = useRouter()
  const deleteMutation = useDeleteUser()
  const [deleteId, setDeleteId] = useState<string | null>(null)

  const actionsColumn = {
    id: 'actions' as const,
    enableHiding: false,
    enableSorting: false,
    cell: ({ row }: { row: { original: User } }) => {
      const user = row.original
      const actions: RowAction[] = [
        { label: 'Voir le profil', icon: Eye, onClick: () => router.push(`/app/users/${user.id}`) },
        {
          label: 'Modifier',
          icon: Pencil,
          onClick: () => router.push(`/app/users/${user.id}`),
        },
        {
          label: 'Supprimer',
          icon: Trash2,
          onClick: () => setDeleteId(user.id),
          variant: 'destructive',
          separator: true,
        },
      ]
      return <RowActions actions={actions} />
    },
  }

  return (
    <div>
      <PageHeader title="Utilisateurs" description="Liste et gestion des comptes utilisateurs." />
      <DataTableToolbar
        searchValue={search}
        onSearch={setSearch}
        searchPlaceholder="Rechercher par email…"
        filters={PLAN_FILTERS}
        activeFilters={filters}
        onFilterChange={setFilter}
        onReset={resetFilters}
        actions={
          <Button variant="outline" size="sm" asChild>
            <a href="/admin/users/export" download>
              <Download className="size-4" /> Export CSV
            </a>
          </Button>
        }
      />
      <DataTable
        data={rows}
        columns={[...usersColumns, actionsColumn]}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
      <ConfirmDialog
        open={!!deleteId}
        onOpenChange={open => !open && setDeleteId(null)}
        title="Supprimer cet utilisateur ?"
        description="L'utilisateur sera supprimé (soft-delete). Ses données resteront en base."
        confirmLabel="Supprimer"
        variant="destructive"
        onConfirm={() => {
          if (deleteId) deleteMutation.mutate(deleteId, { onSuccess: () => setDeleteId(null) })
        }}
        isPending={deleteMutation.isPending}
      />
    </div>
  )
}
