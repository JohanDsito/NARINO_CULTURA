import { ButtonHTMLAttributes, forwardRef } from 'react'
import { Slot } from '@radix-ui/react-slot'
import { cn } from '../../utils/cn'

type Variant = 'primary' | 'secondary' | 'outline' | 'ghost' | 'gold'
type ButtonSize = 'default' | 'icon'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant
  size?: ButtonSize
  asChild?: boolean
}

const base =
  'inline-flex items-center justify-center gap-1.5 font-body text-[13px] font-semibold ' +
  'rounded-btn border-none cursor-pointer transition-all duration-[350ms] ease-smooth ' +
  'hover:-translate-y-px focus-visible:outline-2'

const sizes: Record<ButtonSize, string> = {
  default: 'px-[18px] py-[9px] h-auto',
  icon: 'h-10 w-10 rounded-full p-0',
}

const variants: Record<Variant, string> = {
  primary:   'bg-tierra text-white hover:bg-tierra-light',
  secondary: 'bg-transparent text-tierra border-[1.5px] border-tierra hover:bg-tierra-pale',
  outline:   'bg-transparent text-tierra border-[1.5px] border-tierra hover:bg-tierra-pale',
  ghost:     'bg-transparent text-text-primary hover:bg-bg-subtle',
  gold:      'bg-oro text-[#2D1B00] font-bold hover:bg-oro-light',
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
  }
)
Button.displayName = 'Button'