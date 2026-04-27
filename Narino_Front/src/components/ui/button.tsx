import { ButtonHTMLAttributes, forwardRef } from 'react'
import { Slot } from '@radix-ui/react-slot'
import { cn } from '../../utils/cn'

type Variant = 'primary' | 'secondary' | 'gold'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant
  asChild?: boolean
}

const base =
  'inline-flex items-center gap-1.5 font-body text-[13px] font-semibold ' +
  'px-[18px] py-[9px] rounded-btn border-none cursor-pointer ' +
  'transition-all duration-[350ms] ease-smooth ' +
  'hover:-translate-y-px focus-visible:outline-2'

const variants: Record<Variant, string> = {
  primary:   'bg-tierra text-white hover:bg-tierra-light',
  secondary: 'bg-transparent text-tierra border-[1.5px] border-tierra hover:bg-tierra-pale',
  gold:      'bg-oro text-[#2D1B00] font-bold hover:bg-oro-light',
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'primary', asChild = false, className, children, ...props }, ref) => {
    const Comp = asChild ? Slot : 'button'
    return (
      <Comp
        ref={ref}
        className={cn(base, variants[variant], className)}
        {...props}
      >
        {children}
      </Comp>
    )
  }
)
Button.displayName = 'Button'