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
