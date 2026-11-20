import type { HTMLAttributes } from 'react'
import { cn } from '@/utils'

export type BadgeVariant = 'tierra' | 'oro' | 'selva' | 'indigo' | 'secondary' | 'outline'

export interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant?: BadgeVariant
}

const variants: Record<BadgeVariant, string> = {
  tierra: 'bg-tierra-pale text-tierra',
  oro: 'bg-oro-pale text-oro',
  selva: 'bg-selva-pale text-selva',
  indigo: 'bg-indigo-pale text-indigo',
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
