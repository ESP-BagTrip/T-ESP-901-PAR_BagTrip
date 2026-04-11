'use client'

import { Cell, Pie, PieChart } from 'recharts'

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from '@/components/ui/chart'
import { Skeleton } from '@/components/ui/skeleton'

interface DonutChartCardProps {
  title: string
  description?: string
  data: Array<{ name: string; value: number }>
  isLoading?: boolean
}

const PALETTE = [
  'var(--chart-1)',
  'var(--chart-2)',
  'var(--chart-3)',
  'var(--chart-4)',
  'var(--chart-5)',
]

const config = {
  value: { label: 'Valeur' },
} satisfies ChartConfig

export function DonutChartCard({ title, description, data, isLoading }: DonutChartCardProps) {
  const total = data.reduce((acc, d) => acc + d.value, 0)

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">{title}</CardTitle>
        {description && <CardDescription>{description}</CardDescription>}
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <Skeleton className="h-[240px] w-full" />
        ) : data.length === 0 || total === 0 ? (
          <p className="flex h-[240px] items-center justify-center text-sm text-muted-foreground">
            Aucune donnée
          </p>
        ) : (
          <div className="flex items-center gap-6">
            <ChartContainer config={config} className="h-[220px] w-[220px] shrink-0">
              <PieChart>
                <ChartTooltip content={<ChartTooltipContent hideLabel />} />
                <Pie
                  data={data}
                  dataKey="value"
                  nameKey="name"
                  innerRadius={55}
                  outerRadius={90}
                  strokeWidth={2}
                  stroke="var(--background)"
                  paddingAngle={2}
                >
                  {data.map((entry, i) => (
                    <Cell key={entry.name} fill={PALETTE[i % PALETTE.length]} />
                  ))}
                </Pie>
              </PieChart>
            </ChartContainer>
            <ul className="flex min-w-0 flex-1 flex-col gap-2 text-sm">
              {data.map((d, i) => {
                const pct = total > 0 ? ((d.value / total) * 100).toFixed(0) : '0'
                return (
                  <li key={d.name} className="flex items-center justify-between gap-2">
                    <span className="flex min-w-0 items-center gap-2">
                      <span
                        aria-hidden="true"
                        className="size-2.5 shrink-0 rounded-[2px]"
                        style={{ background: PALETTE[i % PALETTE.length] }}
                      />
                      <span className="truncate text-muted-foreground">{d.name}</span>
                    </span>
                    <span className="font-medium tabular-nums text-foreground">
                      {d.value} <span className="text-muted-foreground">({pct}%)</span>
                    </span>
                  </li>
                )
              })}
            </ul>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
