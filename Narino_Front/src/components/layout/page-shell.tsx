import type { ReactNode } from 'react'

import { cn } from '@/utils'

export function PageShell({
  title,
  description,
  actions,
  children,
  className,
}: {
  title: string
  description?: string
  actions?: ReactNode
  children: ReactNode
  className?: string
}) {
  return (
    <div className={cn('mx-auto w-full max-w-5xl px-4 py-8 pt-16', className)}>
      <header className="mb-6 flex flex-col gap-2">
        <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
          <div className="space-y-1">
            <h1 className="text-3xl font-semibold">{title}</h1>
            {description ? (
              <p className="text-sm text-muted-foreground">{description}</p>
            ) : null}
          </div>
          {actions ? <div className="shrink-0">{actions}</div> : null}
        </div>
      </header>
      {children}
    </div>
  )
}

