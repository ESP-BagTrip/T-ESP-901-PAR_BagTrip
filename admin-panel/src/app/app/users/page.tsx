'use client'

import { useMemo, useState } from 'react'
import { useRouter } from 'next/navigation'
import { Download, Eye, Pencil, Trash2 } from 'lucide-react'
import type { ColumnDef, RowSelectionState } from '@tanstack/react-table'

import { DataTable } from '@/components/DataTable'
import { DataTableToolbar, type FilterConfig } from '@/components/DataTableToolbar'
import { ConfirmDialog } from '@/components/ConfirmDialog'
import { RowActions, type RowAction } from '@/components/RowActions'
import { PageHeader } from '@/components/layout/PageHeader'
import { Button } from '@/components/ui/button'
import { Checkbox } from '@/components/ui/checkbox'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { useUsersTab } from '@/features/users/hooks'
import { useDeleteUser, useBulkChangePlan, useBulkBan } from '@/features/users/mutations'
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
  const bulkPlanMutation = useBulkChangePlan()
  const bulkBanMutation = useBulkBan()

  const [deleteId, setDeleteId] = useState<string | null>(null)
  const [rowSelection, setRowSelection] = useState<RowSelectionState>({})

  const selectedIds = useMemo(
    () =>
      Object.entries(rowSelection)
        .filter(([, selected]) => selected)
        .map(([id]) => id),
    [rowSelection]
  )

  const checkboxColumn: ColumnDef<User> = {
    id: 'select',
    header: ({ table }) => (
      <Checkbox
        checked={table.getIsAllPageRowsSelected()}
        onCheckedChange={v => table.toggleAllPageRowsSelected(!!v)}
        aria-label="Tout sélectionner"
      />
    ),
    cell: ({ row }) => (
      <Checkbox
        checked={row.getIsSelected()}
        onCheckedChange={v => row.toggleSelected(!!v)}
        aria-label="Sélectionner"
      />
    ),
    enableSorting: false,
    enableHiding: false,
  }

  const actionsColumn: ColumnDef<User> = {
    id: 'actions',
    enableHiding: false,
    enableSorting: false,
    cell: ({ row }) => {
      const user = row.original
      const actions: RowAction[] = [
        { label: 'Voir le profil', icon: Eye, onClick: () => router.push(`/app/users/${user.id}`) },
        { label: 'Modifier', icon: Pencil, onClick: () => router.push(`/app/users/${user.id}`) },
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
        selectedCount={selectedIds.length}
        bulkActions={
          <>
            <Select
              onValueChange={plan => {
                bulkPlanMutation.mutate(
                  { userIds: selectedIds, plan },
                  { onSuccess: () => setRowSelection({}) }
                )
              }}
            >
              <SelectTrigger className="w-32">
                <SelectValue placeholder="Plan…" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="FREE">FREE</SelectItem>
                <SelectItem value="PREMIUM">PREMIUM</SelectItem>
                <SelectItem value="ADMIN">ADMIN</SelectItem>
              </SelectContent>
            </Select>
            <Button
              variant="destructive"
              size="sm"
              onClick={() =>
                bulkBanMutation.mutate(
                  { userIds: selectedIds, reason: 'Bulk ban from admin' },
                  { onSuccess: () => setRowSelection({}) }
                )
              }
              disabled={bulkBanMutation.isPending}
            >
              Bannir
            </Button>
          </>
        }
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
        columns={[checkboxColumn, ...usersColumns, actionsColumn]}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
        rowSelection={rowSelection}
        onRowSelectionChange={setRowSelection}
        getRowId={(row: User) => row.id}
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
