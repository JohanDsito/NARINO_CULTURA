import type { HTMLAttributes } from 'react'
import { cn } from '@/utils'

export type BadgeVariant =
  | 'azul'
  | 'tomate'
  | 'naranja'
  | 'oro'
  | 'magenta'
  | 'verde'
  // Alias anteriores: tierra = azul, selva = verde, indigo = magenta
  | 'tierra'
  | 'selva'
  | 'indigo'
  | 'secondary'
  | 'outline'

export interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant?: BadgeVariant
}

// Fondo con el tinte del acento y texto con su tinta (legible en claro y oscuro)
const variants: Record<BadgeVariant, string> = {
  azul: 'bg-azul-tint text-azul',
  tomate: 'bg-tomate-tint text-tomate',
  naranja: 'bg-naranja-tint text-naranja',
  oro: 'bg-oro-tint text-oro',
  magenta: 'bg-magenta-tint text-magenta',
  verde: 'bg-verde-tint text-verde',
  tierra: 'bg-azul-tint text-azul',
  selva: 'bg-verde-tint text-verde',
  indigo: 'bg-magenta-tint text-magenta',
  // Neutros: estados inactivos o etiquetas sin color de marca.
  secondary: 'bg-bg-subtle text-text-secondary',
  outline: 'bg-transparent text-text-secondary border border-border',
}

export function Badge({ variant = 'tierra', className, children, ...props }: BadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center text-[11px] font-semibold',
        'px-[10px] py-[3px] rounded-tag',
        variants[variant],
        className,
      )}
      {...props}
    >
      {children}
    </span>
  )
}
