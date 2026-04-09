'use client'

import { DataTable } from '@/components/DataTable'
import { PageHeader } from '@/components/layout/PageHeader'
import { useUsersTab } from '@/features/users/hooks'
import { usersColumns } from '@/features/users/columns'

export default function UsersPage() {
  const { rows, isLoading, page, limit, total, total_pages, setPage } = useUsersTab()

  return (
    <div>
      <PageHeader title="Utilisateurs" description="Liste et gestion des comptes utilisateurs." />
      <DataTable
        data={rows}
        columns={usersColumns}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />
    </div>
  )
}
