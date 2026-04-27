import { InputHTMLAttributes, forwardRef } from 'react'
import { cn } from '../../utils/cn'

export const Input = forwardRef<HTMLInputElement, InputHTMLAttributes<HTMLInputElement>>(
  ({ className, ...props }, ref) => (
    <input
      ref={ref}
      className={cn(
        'w-full bg-bg-subtle border border-border rounded-input',
        'px-4 py-2.5 font-body text-[14px] text-text-primary',
        'transition-colors duration-[350ms] ease-smooth',
        'focus:outline-none focus:border-tierra focus:ring-2 focus:ring-tierra-pale',
        'placeholder:text-text-muted',
        className
      )}
      {...props}
    />
  )
)
Input.displayName = 'Input'