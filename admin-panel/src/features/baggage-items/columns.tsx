import { ColumnDef } from '@tanstack/react-table'
import { safeFormatDate } from '@/utils/date'
import type { AdminBaggageItem } from '@/types'

/**
 * Infer a better category from the item name when the DB has OTHER.
 * The AI flow doesn't categorize baggage items — this is a display-only heuristic.
 */
function inferCategory(name: string, dbCategory: string | null): string {
  if (dbCategory && dbCategory !== 'OTHER') return dbCategory
  const n = name.toLowerCase()
  if (/passport|visa|ticket|id card|permit|insurance|boarding/i.test(n)) return 'DOCUMENTS'
  if (
    /shirt|pants|jacket|dress|sock|underwear|shoes|coat|hat|scarf|glove|sweater|shorts|t-shirt|clothing/i.test(
      n
    )
  )
    return 'CLOTHING'
  if (
    /phone|charger|laptop|camera|adapter|cable|headphone|earbud|tablet|battery|power bank|usb/i.test(
      n
    )
  )
    return 'ELECTRONICS'
  if (/toothbrush|shampoo|soap|sunscreen|deodorant|razor|moisturizer|lotion|towel|tissue/i.test(n))
    return 'TOILETRIES'
  if (/medicine|pill|first.aid|bandage|mask|sanitizer|prescription|vitamin|inhaler/i.test(n))
    return 'HEALTH'
  if (
    /bag|luggage|wallet|watch|sunglasses|umbrella|book|guide|map|key|lock|pillow|blanket/i.test(n)
  )
    return 'ACCESSORIES'
  return 'OTHER'
}

const categoryColors: Record<string, string> = {
  DOCUMENTS: 'bg-primary/15 text-primary',
  CLOTHING: 'bg-chart-4/15 text-chart-4',
  ELECTRONICS: 'bg-info/15 text-info',
  TOILETRIES: 'bg-success/15 text-success',
  HEALTH: 'bg-destructive/15 text-destructive',
  ACCESSORIES: 'bg-warning/15 text-warning',
  OTHER: 'bg-secondary text-foreground',
}

export const baggageItemsColumns: ColumnDef<AdminBaggageItem>[] = [
  {
    accessorKey: 'id',
    header: 'ID',
    cell: ({ row }) => (
      <span className="font-mono text-xs">{(row.getValue('id') as string).slice(0, 8)}...</span>
    ),
  },
  {
    accessorKey: 'trip_title',
    header: 'Trip',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('trip_title') || '—'}</span>,
  },
  {
    accessorKey: 'user_email',
    header: 'Utilisateur',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('user_email')}</span>,
  },
  {
    accessorKey: 'name',
    header: 'Nom',
    cell: ({ row }) => <span className="text-foreground">{row.getValue('name')}</span>,
  },
  {
    accessorKey: 'category',
    header: 'Catégorie',
    cell: ({ row }) => {
      const cat = inferCategory(row.original.name, row.getValue('category') as string | null)
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${categoryColors[cat] || categoryColors.OTHER}`}
        >
          {cat}
        </span>
      )
    },
  },
  {
    accessorKey: 'quantity',
    header: 'Qté',
    cell: ({ row }) => (
      <span className="tabular-nums text-foreground">{row.getValue('quantity') ?? 1}</span>
    ),
  },
  {
    accessorKey: 'is_packed',
    header: 'Emballé',
    cell: ({ row }) => {
      const isPacked = row.getValue('is_packed') as boolean | null
      return (
        <span
          className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
            isPacked ? 'bg-success/15 text-success' : 'bg-secondary text-foreground'
          }`}
        >
          {isPacked ? 'Oui' : 'Non'}
        </span>
      )
    },
  },
  {
    accessorKey: 'created_at',
    header: 'Créé le',
    cell: ({ row }) => {
      const date = row.getValue('created_at') as string | null
      return (
        <span className="text-muted-foreground text-xs">
          {safeFormatDate(date, 'dd/MM/yyyy HH:mm')}
        </span>
      )
    },
  },
]
