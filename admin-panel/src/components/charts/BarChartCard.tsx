'use client'

import { Bar, BarChart, CartesianGrid, XAxis, YAxis } from 'recharts'

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from '@/components/ui/chart'
import { Skeleton } from '@/components/ui/skeleton'

interface BarChartCardProps {
  title: string
  description?: string
  data: Array<{ name: string; value: number }>
  isLoading?: boolean
  tone?: 'primary' | 'success'
  valueFormatter?: (value: number) => string
}

const config = {
  value: {
    label: 'Valeur',
    theme: { light: 'var(--chart-2)', dark: 'var(--chart-2)' },
  },
} satisfies ChartConfig

export function BarChartCard({
  title,
  description,
  data,
  isLoading,
  tone = 'success',
  valueFormatter,
}: BarChartCardProps) {
  const resolvedColor = tone === 'primary' ? 'var(--chart-1)' : 'var(--chart-2)'

  const finalConfig: ChartConfig = {
    value: { label: config.value.label, theme: { light: resolvedColor, dark: resolvedColor } },
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">{title}</CardTitle>
        {description && <CardDescription>{description}</CardDescription>}
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <Skeleton className="h-[240px] w-full" />
        ) : data.length === 0 ? (
          <p className="flex h-[240px] items-center justify-center text-sm text-muted-foreground">
            Aucune donnée
          </p>
        ) : (
          <ChartContainer config={finalConfig} className="h-[240px] w-full">
            <BarChart data={data} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
              <CartesianGrid vertical={false} stroke="var(--chart-grid)" strokeDasharray="3 3" />
              <XAxis
                dataKey="name"
                tickLine={false}
                axisLine={false}
                tick={{ fontSize: 11, fill: 'var(--chart-axis)' }}
                tickMargin={8}
              />
              <YAxis
                tickLine={false}
                axisLine={false}
                tick={{ fontSize: 11, fill: 'var(--chart-axis)' }}
                width={40}
                tickFormatter={v => (valueFormatter ? valueFormatter(v) : String(v))}
              />
              <ChartTooltip
                cursor={{ fill: 'var(--muted)', opacity: 0.4 }}
                content={
                  <ChartTooltipContent
                    formatter={value =>
                      valueFormatter ? valueFormatter(Number(value)) : String(value)
                    }
                  />
                }
              />
              <Bar dataKey="value" fill="var(--color-value)" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ChartContainer>
        )}
      </CardContent>
    </Card>
  )
}
