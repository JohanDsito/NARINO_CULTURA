import * as React from 'react'

import { cn } from '@/utils'

type SelectProps = React.ComponentPropsWithoutRef<'select'>

const Select = React.forwardRef<HTMLSelectElement, SelectProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <select
        ref={ref}
        className={cn(
          'flex h-10 w-full rounded-md border border-border bg-bg-subtle dark:bg-bg-subtle px-3 py-2 text-sm text-text-primary dark:text-text-primary placeholder:text-text-muted dark:placeholder:text-text-muted',
          'transition-colors duration-[350ms] ease-smooth',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-tierra focus-visible:ring-offset-2 dark:focus-visible:ring-offset-bg-card disabled:cursor-not-allowed disabled:opacity-50',
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
