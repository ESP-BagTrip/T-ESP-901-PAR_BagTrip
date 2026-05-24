import * as React from 'react'

import { cn } from '@/lib/utils'

interface SparklineProps extends React.SVGAttributes<SVGSVGElement> {
  data: number[]
  width?: number
  height?: number
  strokeWidth?: number
}

/**
 * Minimal inline SVG sparkline. 60×24 by default. Uses currentColor so the parent
 * controls the color via `text-*` utilities (text-primary, text-success, etc.).
 */
export function Sparkline({
  data,
  width = 60,
  height = 24,
  strokeWidth = 1.5,
  className,
  ...rest
}: SparklineProps) {
  if (data.length < 2) {
    return (
      <svg
        width={width}
        height={height}
        className={cn('text-muted-foreground', className)}
        {...rest}
        aria-hidden="true"
      />
    )
  }

  const pad = 2
  const innerW = width - pad * 2
  const innerH = height - pad * 2
  const min = Math.min(...data)
  const max = Math.max(...data)
  const range = max - min || 1
  const step = innerW / (data.length - 1)

  const points = data
    .map((v, i) => {
      const x = pad + i * step
      const y = pad + innerH - ((v - min) / range) * innerH
      return `${x.toFixed(2)},${y.toFixed(2)}`
    })
    .join(' ')

  return (
    <svg
      width={width}
      height={height}
      viewBox={`0 0 ${width} ${height}`}
      className={className}
      aria-hidden="true"
      {...rest}
    >
      <polyline
        points={points}
        fill="none"
        stroke="currentColor"
        strokeWidth={strokeWidth}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}
