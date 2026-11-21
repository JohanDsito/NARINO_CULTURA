import { forwardRef } from 'react'
import type { InputHTMLAttributes } from 'react'
import { cn } from '@/utils'

export const Input = forwardRef<HTMLInputElement, InputHTMLAttributes<HTMLInputElement>>(
  ({ className, ...props }, ref) => (
    <input
      ref={ref}
      className={cn(
        'w-full bg-bg-card border border-border-strong rounded-input',
        'px-4 py-2.5 font-body text-[15px] text-text-primary',
        'transition-colors duration-[350ms] ease-smooth',
        'focus:outline-none focus:border-azul focus:ring-2 focus:ring-azul/25',
        'placeholder:text-text-muted',
        className
      )}
      {...props}
    />
  )
)
Input.displayName = 'Input'
