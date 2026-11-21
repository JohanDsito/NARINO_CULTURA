import { forwardRef } from 'react'
import type { ButtonHTMLAttributes } from 'react'
import { Slot } from '@radix-ui/react-slot'
import { cn } from '@/utils'

export type ButtonVariant = 'primary' | 'secondary' | 'outline' | 'ghost' | 'gold'
export type ButtonSize = 'default' | 'sm' | 'icon'

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant
  size?: ButtonSize
  asChild?: boolean
}

// Píldora con reacción al toque (escala 0.96, curva "spring"), como NcPrimaryButton en la app
const base =
  'inline-flex items-center justify-center gap-1.5 font-body text-[14px] font-semibold ' +
  'rounded-btn border-none cursor-pointer transition-all duration-200 ease-spring ' +
  'active:scale-[0.96] focus-visible:outline-2 ' +
  'disabled:cursor-not-allowed disabled:opacity-60 disabled:active:scale-100'

const sizes: Record<ButtonSize, string> = {
  default: 'px-5 h-11',
  sm: 'px-3.5 h-9 text-[13px]',
  icon: 'h-11 w-11 rounded-full p-0',
}

// La acción principal es siempre azul. `outline` es alias de `secondary` porque varias pantallas lo usan.
const variants: Record<ButtonVariant, string> = {
  primary:
    'bg-azul-fill text-on-azul hover:bg-azul-fill/90 dark:shadow-[0_0_24px_-6px_var(--azul-fill)]',
  secondary: 'bg-transparent text-azul border-[1.5px] border-azul/60 hover:bg-azul-tint',
  outline: 'bg-transparent text-azul border-[1.5px] border-azul/60 hover:bg-azul-tint',
  ghost: 'bg-transparent text-text-primary hover:bg-bg-subtle',
  gold: 'bg-oro-fill text-on-oro font-bold hover:bg-oro-fill/90',
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'primary', size = 'default', asChild = false, className, children, ...props }, ref) => {
    const Comp = asChild ? Slot : 'button'
    return (
      <Comp
        ref={ref}
        className={cn(base, sizes[size], variants[variant], className)}
        {...props}
      >
        {children}
      </Comp>
    )
  },
)
Button.displayName = 'Button'
