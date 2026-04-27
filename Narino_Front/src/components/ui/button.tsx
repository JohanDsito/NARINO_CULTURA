import { type ButtonHTMLAttributes, forwardRef, Children, cloneElement, isValidElement } from 'react'
import { cn } from '../../utils/cn'

type Variant = 'primary' | 'secondary' | 'gold' | 'outline'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant
  asChild?: boolean
}

const base =
  'inline-flex items-center justify-center gap-1.5 font-body text-[13px] font-semibold ' +
  'px-[18px] py-[9px] rounded-btn border-none cursor-pointer ' +
  'transition-all duration-[350ms] ease-smooth ' +
  'hover:-translate-y-px focus-visible:outline-2 ' +
  'disabled:opacity-50 disabled:cursor-not-allowed'

const variants: Record<Variant, string> = {
  primary:   'bg-tierra text-white hover:bg-tierra-light',
  secondary: 'bg-transparent text-tierra border-[1.5px] border-tierra hover:bg-tierra-pale',
  gold:      'bg-oro text-[#2D1B00] font-bold hover:bg-oro-light',
  outline:   'bg-transparent text-tierra border-[1.5px] border-tierra hover:bg-tierra-pale',
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'primary', className, children, asChild, ...props }, ref) => {
    const classes = cn(base, variants[variant], className)

    if (asChild && children) {
      // Renderizar como el hijo (ej: Link) con las clases del button
      const child = Children.only(children) as React.ReactElement<{ className?: string }>
      if (isValidElement(child)) {
        const childClassName = child.props?.className || ''
        return cloneElement(child, {
          className: cn(classes, childClassName),
        })
      }
    }

    // Renderizar como button normal
    return (
      <button
        ref={ref}
        className={classes}
        {...props}
      >
        {children}
      </button>
    )
  }
)
Button.displayName = 'Button'