import type { BadgeVariant } from '@/components/ui/badge'
import type { UserRole } from '@/types'

// Etiquetas en español de los valores que envía el backend. Los colores usan
// los tokens del design system para que funcionen en modo claro y oscuro.

export const ROLE_LABELS: Record<UserRole, string> = {
  artist: 'Artista',
  buyer: 'Visitante',
  cultural_manager: 'Gestor cultural',
  admin: 'Administrador',
}

/** Estado de una obra: etiqueta y variante de `Badge`. */
export const ARTWORK_STATUS: Record<string, { label: string; variant: BadgeVariant }> = {
  PENDIENTE: { label: 'Pendiente', variant: 'tierra' },
  DISPONIBLE: { label: 'Disponible', variant: 'selva' },
  EN_SUBASTA: { label: 'En subasta', variant: 'indigo' },
  VENDIDA: { label: 'Vendida', variant: 'secondary' },
  INACTIVA: { label: 'Inactiva', variant: 'secondary' },
}

export function artworkStatus(status: string) {
  return ARTWORK_STATUS[status] ?? { label: status, variant: 'secondary' as BadgeVariant }
}

export const EVENT_TYPES = [
  { value: 'CONCIERTO', label: 'Concierto' },
  { value: 'EXPOSICION', label: 'Exposición' },
  { value: 'TALLER', label: 'Taller' },
  { value: 'FERIA', label: 'Feria' },
  { value: 'ESPECTACULO', label: 'Espectáculo' },
  { value: 'OTRO', label: 'Otro' },
] as const

export const ORDER_STATUS_LABELS: Record<string, { label: string; color: string }> = {
  PENDIENTE: { label: 'Pendiente', color: 'bg-oro-pale text-oro' },
  PAGADO: { label: 'Pagado', color: 'bg-selva-pale text-selva' },
  CANCELADO: { label: 'Cancelado', color: 'bg-error/10 text-error' },
  REEMBOLSADO: { label: 'Reembolsado', color: 'bg-indigo-pale text-indigo' },
}

export const ORDER_TYPE_LABELS: Record<string, string> = {
  COMPRA_DIRECTA: 'Compra directa',
  SUBASTA: 'Subasta',
}

export const TRANSACTION_STATUS_LABELS: Record<string, { label: string; color: string }> = {
  PENDIENTE: { label: 'Pendiente', color: 'bg-oro-pale text-oro' },
  APROBADO: { label: 'Aprobado', color: 'bg-selva-pale text-selva' },
  RECHAZADO: { label: 'Rechazado', color: 'bg-error/10 text-error' },
  REEMBOLSADO: { label: 'Reembolsado', color: 'bg-indigo-pale text-indigo' },
}

export const AUCTION_STATUS_LABELS: Record<string, string> = {
  PENDIENTE: 'Por aprobar',
  ACTIVA: 'En curso',
  CERRADA: 'Finalizada',
  CANCELADA: 'Cancelada',
}

export const AGGREGATION_TYPE_LABELS: Record<string, string> = {
  SOLISTA: 'Solista',
  BANDA: 'Banda',
  DJ: 'DJ',
  COLECTIVO: 'Colectivo',
  DUO: 'Dúo',
  TRIO: 'Trío',
}

export const MUSICAL_WORK_TYPE_LABELS: Record<string, string> = {
  VIDEO: 'Video',
  LIVE: 'En vivo',
  STUDIO: 'Estudio',
  COVER: 'Cover',
  PODCAST: 'Podcast',
}

/** Medio de pago que reporta Wompi (Transaction.payment_method). */
export const PAYMENT_METHOD_LABELS: Record<string, string> = {
  CARD: 'tarjeta',
  PSE: 'PSE',
  NEQUI: 'Nequi',
  BANCOLOMBIA_TRANSFER: 'transferencia Bancolombia',
  BANCOLOMBIA_QR: 'QR Bancolombia',
  DAVIPLATA: 'Daviplata',
}
