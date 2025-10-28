import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatNumber(value: number, decimals: number = 0): string {
  return new Intl.NumberFormat('en-US', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(value)
}

export function formatPercent(value: number, decimals: number = 1): string {
  // If value is already a percentage (0-100 range), don't multiply
  // If value is a decimal (0-1 range), multiply by 100
  const isAlreadyPercent = value > 1 || value < -1
  const percentValue = isAlreadyPercent ? value : value * 100
  return `${percentValue.toFixed(decimals)}%`
}

export function formatDate(date: Date | string): string {
  const d = typeof date === 'string' ? new Date(date) : date
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  }).format(d)
}

export function getTierColor(tier: string): string {
  const colors: Record<string, string> = {
    'Platinum': 'bg-yellow-400 text-yellow-900',
    'Gold': 'bg-gray-300 text-gray-900',
    'Silver': 'bg-blue-400 text-blue-900',
    'Bronze': 'bg-gray-500 text-white'
  }
  return colors[tier] || 'bg-gray-200 text-gray-800'
}

export function getTrendIcon(value: number): string {
  if (value > 0) return '↑'
  if (value < 0) return '↓'
  return '→'
}

export function getTrendColor(value: number): string {
  if (value > 0) return 'text-green-600'
  if (value < 0) return 'text-red-600'
  return 'text-gray-600'
}
