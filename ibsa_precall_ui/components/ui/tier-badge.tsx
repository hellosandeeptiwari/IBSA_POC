'use client'

import { Badge } from '@/components/ui/badge'
import { getTierColor } from '@/lib/utils'

interface TierBadgeProps {
  tier: string
  size?: 'sm' | 'md' | 'lg'
}

export function TierBadge({ tier, size = 'md' }: TierBadgeProps) {
  const sizeClasses = {
    sm: 'text-xs px-2 py-0.5',
    md: 'text-sm px-2.5 py-0.5',
    lg: 'text-base px-3 py-1'
  }

  return (
    <Badge className={`${getTierColor(tier)} ${sizeClasses[size]} font-semibold`}>
      {tier}
    </Badge>
  )
}
