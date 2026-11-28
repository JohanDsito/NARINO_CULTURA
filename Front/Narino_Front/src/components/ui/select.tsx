import * as React from 'react'

import { cn } from '@/utils'

type SelectProps = React.ComponentPropsWithoutRef<'select'>

const Select = React.forwardRef<HTMLSelectElement, SelectProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <select
        ref={ref}
        className={cn(
          'flex h-11 w-full rounded-input border border-border-strong bg-bg-card px-3.5 py-2 text-[15px] text-text-primary placeholder:text-text-muted',
          'transition-colors duration-[350ms] ease-smooth',
          'focus-visible:outline-none focus-visible:border-azul focus-visible:ring-2 focus-visible:ring-azul/25 disabled:cursor-not-allowed disabled:opacity-50',
          className,
        )}
        {...props}
      >
        {children}
      </select>
    )
  },
)
Select.displayName = 'Select'

export { Select }
