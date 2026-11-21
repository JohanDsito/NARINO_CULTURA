import type { ReactNode } from 'react'

import { cn } from '@/utils'

/** Acento de cada sección (como en la app): catálogo magenta, tienda naranja, subastas oro, eventos tomate, música azul. */
export type SectionAccent = 'azul' | 'tomate' | 'naranja' | 'oro' | 'magenta' | 'verde'

const EYEBROW_COLOR: Record<SectionAccent, string> = {
  azul: 'text-azul',
  tomate: 'text-tomate',
  naranja: 'text-naranja',
  oro: 'text-oro',
  magenta: 'text-magenta',
  verde: 'text-verde',
}

export function PageShell({
  title,
  eyebrow,
  accent = 'azul',
  description,
  subtitle,
  actions,
  children,
  className,
}: {
  title: string
  /** Etiqueta corta sobre el título, en el color de la sección ("ARTES PLÁSTICAS") */
  eyebrow?: string
  accent?: SectionAccent
  description?: string
  subtitle?: string
  actions?: ReactNode
  children?: ReactNode
  className?: string
}) {
  const sub = subtitle ?? description

  return (
    <div className={cn('mx-auto w-full max-w-5xl px-4 py-8 pt-16', className)}>
      <header className="mb-6 flex flex-col gap-2">
        <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
          <div className="space-y-1">
            {eyebrow ? <p className={cn('nc-eyebrow', EYEBROW_COLOR[accent])}>{eyebrow}</p> : null}
            <h1 className="text-3xl font-extrabold text-text-primary md:text-4xl">{title}</h1>
            {sub ? (
              <p className="text-sm text-text-secondary">{sub}</p>
            ) : null}
          </div>
          {actions ? <div className="shrink-0">{actions}</div> : null}
        </div>
      </header>
      {children}
    </div>
  )
}

