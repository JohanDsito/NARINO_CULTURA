import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

/** Combina clases condicionales y resuelve conflictos de Tailwind. */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

const currencyFormatter = new Intl.NumberFormat('es-CO', {
  style: 'currency',
  currency: 'COP',
  maximumFractionDigits: 0,
})

/**
 * Formatea un valor en pesos colombianos. Acepta números o los strings que
 * DRF envía para los DecimalField; devuelve `fallback` si no es un número.
 */
export function formatCurrency(
  amount: number | string | null | undefined,
  fallback = '—',
): string {
  if (amount === null || amount === undefined || amount === '') return fallback
  const value = typeof amount === 'number' ? amount : parseFloat(amount)
  return Number.isFinite(value) ? currencyFormatter.format(value) : fallback
}

const relativeFormatter = new Intl.RelativeTimeFormat('es-CO', { numeric: 'auto' })
const shortDateFormatter = new Intl.DateTimeFormat('es-CO', { day: 'numeric', month: 'short', year: 'numeric' })

/**
 * Tiempo relativo en español ("hace 5 minutos", "ayer"). Pasada una semana muestra la fecha corta.
 * Devuelve `fallback` si la fecha no es válida.
 */
export function formatRelativeTime(
  value: string | Date | null | undefined,
  now: Date = new Date(),
  fallback = '',
): string {
  if (!value) return fallback
  const date = value instanceof Date ? value : new Date(value)
  if (Number.isNaN(date.getTime())) return fallback

  const seconds = Math.round((date.getTime() - now.getTime()) / 1000)
  const abs = Math.abs(seconds)
  if (abs < 60) return 'hace un momento'
  if (abs < 3600) return relativeFormatter.format(Math.round(seconds / 60), 'minute')
  if (abs < 86400) return relativeFormatter.format(Math.round(seconds / 3600), 'hour')
  if (abs < 7 * 86400) return relativeFormatter.format(Math.round(seconds / 86400), 'day')
  return shortDateFormatter.format(date)
}
