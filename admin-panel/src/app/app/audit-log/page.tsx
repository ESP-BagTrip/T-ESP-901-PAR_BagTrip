'use client'

import { useState } from 'react'
import type { ColumnDef } from '@tanstack/react-table'

import { DataTable } from '@/components/DataTable'
import { DataTableToolbar, type FilterConfig } from '@/components/DataTableToolbar'
import { PageHeader } from '@/components/layout/PageHeader'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { adminService } from '@/services'
import { usePaginatedQuery } from '@/shared/hooks/usePaginatedQuery'
import { safeFormatDate } from '@/utils/date'
import type { AuditLogEntry } from '@/types/admin'

const ENTITY_FILTERS: FilterConfig[] = [
  {
    key: 'entity_type',
    label: 'Entité',
    options: [
      { value: 'USER', label: 'User' },
      { value: 'TRIP', label: 'Trip' },
      { value: 'ACTIVITY', label: 'Activity' },
      { value: 'BOOKING_INTENT', label: 'Booking' },
      { value: 'ACCOMMODATION', label: 'Accommodation' },
    ],
  },
  {
    key: 'action',
    label: 'Action',
    options: [
      { value: 'CREATE', label: 'Create' },
      { value: 'UPDATE', label: 'Update' },
      { value: 'DELETE', label: 'Delete' },
      { value: 'BAN', label: 'Ban' },
      { value: 'UNBAN', label: 'Unban' },
      { value: 'PLAN_CHANGE', label: 'Plan change' },
      { value: 'STATUS_CHANGE', label: 'Status change' },
    ],
  },
]

const ACTION_BADGE: Record<string, 'default' | 'secondary' | 'destructive' | 'warning'> = {
  CREATE: 'default',
  UPDATE: 'secondary',
  DELETE: 'destructive',
  BAN: 'destructive',
  UNBAN: 'warning',
  PLAN_CHANGE: 'warning',
  STATUS_CHANGE: 'secondary',
}

const columns: ColumnDef<AuditLogEntry>[] = [
  {
    accessorKey: 'created_at',
    header: 'Date',
    cell: ({ row }) => (
      <span className="text-xs tabular-nums text-muted-foreground">
        {safeFormatDate(row.original.created_at, 'dd/MM/yyyy HH:mm')}
      </span>
    ),
  },
  {
    accessorKey: 'actor_email',
    header: 'Admin',
    cell: ({ row }) => <span className="text-sm">{row.original.actor_email}</span>,
  },
  {
    accessorKey: 'action',
    header: 'Action',
    cell: ({ row }) => (
      <Badge variant={ACTION_BADGE[row.original.action] ?? 'outline'}>{row.original.action}</Badge>
    ),
  },
  {
    accessorKey: 'entity_type',
    header: 'Entité',
    cell: ({ row }) => <span className="font-mono text-xs">{row.original.entity_type}</span>,
  },
  {
    accessorKey: 'entity_id',
    header: 'ID',
    cell: ({ row }) => (
      <span className="font-mono text-xs text-muted-foreground">
        {row.original.entity_id.slice(0, 8)}…
      </span>
    ),
  },
]

export default function AuditLogPage() {
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
  } = usePaginatedQuery<AuditLogEntry>({
    queryKey: ['admin', 'audit-logs'],
    queryFn: params => adminService.getAuditLogs(params),
    filterKeys: ['entity_type', 'action'],
    defaultLimit: 20,
  })

  const [diffEntry, setDiffEntry] = useState<AuditLogEntry | null>(null)

  const columnsWithDiff: ColumnDef<AuditLogEntry>[] = [
    ...columns,
    {
      id: 'diff',
      header: 'Diff',
      cell: ({ row }) =>
        row.original.diff_json ? (
          <Button variant="ghost" size="xs" onClick={() => setDiffEntry(row.original)}>
            Voir
          </Button>
        ) : (
          <span className="text-xs text-muted-foreground">—</span>
        ),
    },
  ]

  return (
    <div>
      <PageHeader title="Journal d'audit" description="Historique de toutes les actions admin." />
      <DataTableToolbar
        searchValue={search}
        onSearch={setSearch}
        searchPlaceholder="Rechercher par email admin…"
        filters={ENTITY_FILTERS}
        activeFilters={filters}
        onFilterChange={setFilter}
        onReset={resetFilters}
      />
      <DataTable
        data={rows}
        columns={columnsWithDiff}
        isLoading={isLoading}
        pagination={{ page, limit, total, total_pages }}
        onPaginationChange={newPage => setPage(newPage)}
      />

      <Dialog open={!!diffEntry} onOpenChange={open => !open && setDiffEntry(null)}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>
              {diffEntry?.action} — {diffEntry?.entity_type}
            </DialogTitle>
          </DialogHeader>
          <pre className="max-h-96 overflow-auto rounded-md bg-muted p-4 text-xs">
            {diffEntry?.diff_json ? JSON.stringify(diffEntry.diff_json, null, 2) : 'Aucun diff'}
          </pre>
        </DialogContent>
      </Dialog>
    </div>
  )
}
