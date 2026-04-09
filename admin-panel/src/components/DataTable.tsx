'use client'

import { useState } from 'react'
import {
  ColumnDef,
  flexRender,
  getCoreRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  SortingState,
  useReactTable,
} from '@tanstack/react-table'
import { ChevronLeft, ChevronRight, ArrowDown, ArrowUp, ArrowUpDown } from 'lucide-react'

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { cn } from '@/lib/utils'

interface DataTableProps<T> {
  data: T[]
  columns: ColumnDef<T>[]
  isLoading?: boolean
  pagination?: {
    page: number
    limit: number
    total: number
    total_pages: number
  }
  onPaginationChange?: (page: number, limit: number) => void
  emptyLabel?: string
}

export function DataTable<T>({
  data,
  columns,
  isLoading = false,
  pagination,
  onPaginationChange,
  emptyLabel = 'Aucune donnée disponible',
}: DataTableProps<T>) {
  const [sorting, setSorting] = useState<SortingState>([])

  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: pagination ? undefined : getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    onSortingChange: setSorting,
    state: { sorting },
    manualPagination: !!pagination,
    pageCount: pagination?.total_pages ?? 0,
  })

  const currentPage = pagination?.page ?? table.getState().pagination.pageIndex + 1
  const totalPages = pagination?.total_pages ?? table.getPageCount()
  const total = pagination?.total ?? data.length
  const limit = pagination?.limit ?? 10

  const handlePageChange = (newPage: number) => {
    if (pagination && onPaginationChange) {
      onPaginationChange(newPage, pagination.limit)
    } else {
      table.setPageIndex(newPage - 1)
    }
  }

  if (isLoading) {
    return (
      <div className="rounded-md border border-border bg-card shadow-xs">
        <div className="space-y-3 p-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton key={i} className={cn('h-8', i === 5 ? 'w-3/4' : 'w-full')} />
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="overflow-hidden rounded-md border border-border bg-card shadow-xs">
      <Table>
        <TableHeader>
          {table.getHeaderGroups().map(headerGroup => (
            <TableRow key={headerGroup.id} className="bg-muted/40 hover:bg-muted/40">
              {headerGroup.headers.map(header => {
                const canSort = header.column.getCanSort()
                const sortDir = header.column.getIsSorted() as false | 'asc' | 'desc'
                return (
                  <TableHead
                    key={header.id}
                    className={cn(
                      'h-10 text-[11px] font-medium uppercase tracking-wider text-muted-foreground',
                      canSort && 'cursor-pointer select-none hover:text-foreground'
                    )}
                    onClick={canSort ? header.column.getToggleSortingHandler() : undefined}
                  >
                    <span className="flex items-center gap-1">
                      {flexRender(header.column.columnDef.header, header.getContext())}
                      {canSort && (
                        <span aria-hidden="true" className="text-muted-foreground">
                          {sortDir === 'asc' ? (
                            <ArrowUp className="size-3" />
                          ) : sortDir === 'desc' ? (
                            <ArrowDown className="size-3" />
                          ) : (
                            <ArrowUpDown className="size-3 opacity-50" />
                          )}
                        </span>
                      )}
                    </span>
                  </TableHead>
                )
              })}
            </TableRow>
          ))}
        </TableHeader>
        <TableBody>
          {table.getRowModel().rows.length === 0 ? (
            <TableRow>
              <TableCell
                colSpan={columns.length}
                className="h-24 text-center text-sm text-muted-foreground"
              >
                {emptyLabel}
              </TableCell>
            </TableRow>
          ) : (
            table.getRowModel().rows.map(row => (
              <TableRow key={row.id}>
                {row.getVisibleCells().map(cell => (
                  <TableCell key={cell.id} className="whitespace-nowrap text-sm text-foreground">
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </TableCell>
                ))}
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>

      {(pagination || totalPages > 1) && (
        <div className="flex items-center justify-between gap-4 border-t border-border bg-background px-4 py-3">
          <p className="text-xs text-muted-foreground">
            {total > 0 ? (
              <>
                <span className="font-medium tabular-nums text-foreground">
                  {(currentPage - 1) * limit + 1}
                </span>
                {' – '}
                <span className="font-medium tabular-nums text-foreground">
                  {Math.min(currentPage * limit, total)}
                </span>
                {' sur '}
                <span className="font-medium tabular-nums text-foreground">{total}</span>
              </>
            ) : (
              'Aucun résultat'
            )}
          </p>
          <div className="flex items-center gap-2">
            <span className="text-xs text-muted-foreground">
              Page <span className="font-medium tabular-nums text-foreground">{currentPage}</span>
              {' / '}
              <span className="font-medium tabular-nums text-foreground">{totalPages || 1}</span>
            </span>
            <div className="flex items-center gap-1">
              <Button
                variant="outline"
                size="icon-sm"
                aria-label="Page précédente"
                onClick={() => handlePageChange(currentPage - 1)}
                disabled={currentPage <= 1}
              >
                <ChevronLeft className="size-4" />
              </Button>
              <Button
                variant="outline"
                size="icon-sm"
                aria-label="Page suivante"
                onClick={() => handlePageChange(currentPage + 1)}
                disabled={currentPage >= totalPages}
              >
                <ChevronRight className="size-4" />
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
