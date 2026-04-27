import { type HTMLAttributes } from 'react'
import { cn } from '../../utils/cn'

type Variant = 'tierra' | 'oro' | 'selva' | 'indigo'

interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant?: Variant
}

const variants: Record<Variant, string> = {
  tierra: 'bg-tierra-pale text-tierra',
  oro:    'bg-oro-pale    text-oro',
  selva:  'bg-selva-pale  text-selva',
  indigo: 'bg-indigo-pale text-indigo',
}

export function Badge({ variant = 'tierra', className, children, ...props }: BadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center text-[11px] font-semibold',
        'px-[10px] py-[3px] rounded-tag',
        variants[variant],
        className
      )}
      {...props}
    >
      {children}
    </span>
  )
}