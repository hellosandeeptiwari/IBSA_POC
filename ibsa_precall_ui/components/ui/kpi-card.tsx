'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { formatNumber, formatPercent, getTrendColor } from '@/lib/utils'
import { ArrowUpIcon, ArrowDownIcon } from 'lucide-react'

interface KPICardProps {
  title: string
  value: number | string
  trend?: number
  format?: 'number' | 'percent' | 'currency' | 'none'
  decimals?: number
  description?: string
}

export function KPICard({ title, value, trend, format = 'number', decimals = 0, description }: KPICardProps) {
  const formattedValue = typeof value === 'string' ? value : 
    format === 'number' ? formatNumber(value, decimals) :
    format === 'percent' ? formatPercent(value, decimals) :
    format === 'currency' ? `$${formatNumber(value, decimals)}` :
    value

  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex items-baseline justify-between">
          <div className="text-3xl font-bold">{formattedValue}</div>
          {trend !== undefined && (
            <div className={`flex items-center text-sm font-medium ${getTrendColor(trend)}`}>
              {trend > 0 ? <ArrowUpIcon className="h-4 w-4 mr-1" /> : <ArrowDownIcon className="h-4 w-4 mr-1" />}
              {formatPercent(Math.abs(trend), 1)}
            </div>
          )}
        </div>
        {description && <p className="text-xs text-muted-foreground mt-1">{description}</p>}
      </CardContent>
    </Card>
  )
}
