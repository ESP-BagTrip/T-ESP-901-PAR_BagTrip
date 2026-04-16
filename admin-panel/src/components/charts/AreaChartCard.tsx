'use client'

import { Area, AreaChart, CartesianGrid, XAxis, YAxis } from 'recharts'

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from '@/components/ui/chart'
import { Skeleton } from '@/components/ui/skeleton'

interface AreaChartCardProps {
  title: string
  description?: string
  data: Array<{ name: string; value: number }>
  isLoading?: boolean
  valueFormatter?: (value: number) => string
  dataKeyLabel?: string
}

const config = {
  value: {
    label: 'Valeur',
    theme: { light: 'var(--chart-1)', dark: 'var(--chart-1)' },
  },
} satisfies ChartConfig

export function AreaChartCard({
  title,
  description,
  data,
  isLoading,
  valueFormatter,
  dataKeyLabel,
}: AreaChartCardProps) {
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
          <ChartContainer
            config={
              dataKeyLabel ? { ...config, value: { ...config.value, label: dataKeyLabel } } : config
            }
            className="h-[240px] w-full"
          >
            <AreaChart data={data} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
              <defs>
                <linearGradient id="areaFill" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="var(--color-value)" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="var(--color-value)" stopOpacity={0} />
                </linearGradient>
              </defs>
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
                width={32}
                tickFormatter={v => (valueFormatter ? valueFormatter(v) : String(v))}
              />
              <ChartTooltip
                cursor={{ stroke: 'var(--chart-grid)' }}
                content={
                  <ChartTooltipContent
                    formatter={value =>
                      valueFormatter ? valueFormatter(Number(value)) : String(value)
                    }
                  />
                }
              />
              <Area
                type="monotone"
                dataKey="value"
                stroke="var(--color-value)"
                strokeWidth={2}
                fill="url(#areaFill)"
                dot={false}
                activeDot={{ r: 4, strokeWidth: 0 }}
              />
            </AreaChart>
          </ChartContainer>
        )}
      </CardContent>
    </Card>
  )
}
