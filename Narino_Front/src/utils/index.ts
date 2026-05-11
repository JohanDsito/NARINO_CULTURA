import { type ClassValue, clsx } from 'clsx'
import { format, formatDistanceToNow } from 'date-fns'
import { es } from 'date-fns/locale'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP',
    minimumFractionDigits: 0,
  }).format(amount)
}

export function formatDate(dateStr: string): string {
  return format(new Date(dateStr), "d 'de' MMMM, yyyy", { locale: es })
}

export function formatDateShort(dateStr: string): string {
  return format(new Date(dateStr), 'dd/MM/yyyy', { locale: es })
}

export function formatRelativeTime(dateStr: string): string {
  return formatDistanceToNow(new Date(dateStr), { addSuffix: true, locale: es })
}

export function getCountdown(endDate: string): {
  days: number
  hours: number
  minutes: number
  seconds: number
  isExpired: boolean
} {
  const now = new Date().getTime()
  const end = new Date(endDate).getTime()
  const diff = end - now

  if (diff <= 0) return { days: 0, hours: 0, minutes: 0, seconds: 0, isExpired: true }

  return {
    days: Math.floor(diff / (1000 * 60 * 60 * 24)),
    hours: Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)),
    minutes: Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60)),
    seconds: Math.floor((diff % (1000 * 60)) / 1000),
    isExpired: false,
  }
}

export function truncateText(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text
  return text.slice(0, maxLength) + '...'
}

export function getImageUrl(path?: string): string {
  if (!path) return '/placeholder.webp'
  if (path.startsWith('http')) return path
  const baseURL = (import.meta.env.VITE_API_BASE_URL ?? import.meta.env.VITE_API_URL ?? '').replace(/\/$/, '')
  return `${baseURL}${path}`
}

export function slugify(text: string): string {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '')
}